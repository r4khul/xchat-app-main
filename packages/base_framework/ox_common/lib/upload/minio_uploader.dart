import 'dart:io';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';
import 'package:ox_common/upload/file_type.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/utils/account_credentials_utils.dart';
import 'package:ox_common/upload/hash_util.dart';
import 'package:ox_common/utils/string_utils.dart';

class MinioUploader {

  static MinioUploader? _instance;

  late Minio _minio;
  late String bucketName;
  String? _pathPrefix;
  
  // Credential management for STS temporary credentials
  String? _tenantId;
  int? _expiration;
  String? _url;
  // Stored for potential future use (e.g., credential refresh tracking)
  // ignore: unused_field
  String? _accessKey;
  // ignore: unused_field
  String? _secretKey;
  String? _region;

  factory MinioUploader() => _instance!;

  MinioUploader._internal();

  static MinioUploader get instance {
    _instance ??= MinioUploader._internal();
    return _instance!;
  }

  static MinioUploader init({
    required String url,
    required String accessKey,
    required String secretKey,
    required String bucketName,
    String? pathPrefix,
    String? region,
    String? sessionToken,
    int? expiration,
    int? port,
    bool? useSSL,
  }) {
    _instance = MinioUploader._internal();
    final uri = Uri.parse(url);
    String endPoint = uri.host;
    final useSSL = uri.scheme == 'https';
    final port = uri.port == 0 ? null : uri.port;
    _instance!._minio = Minio(
      endPoint: endPoint,
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: useSSL,
      port: port,
      region: region,
      sessionToken: sessionToken,
    );
    _instance!.bucketName = bucketName;
    _instance!._pathPrefix = pathPrefix;
    
    // Store credential info for refresh
    _instance!._url = url;
    _instance!._accessKey = accessKey;
    _instance!._secretKey = secretKey;
    _instance!._region = region;
    _instance!._expiration = expiration;
    
    // Extract tenantId from pathPrefix if available
    // Format: "tenant-rb8QlKix/" -> "rb8QlKix"
    if (pathPrefix != null && pathPrefix.isNotEmpty) {
      final prefix = pathPrefix.endsWith('/') 
          ? pathPrefix.substring(0, pathPrefix.length - 1)
          : pathPrefix;
      if (prefix.startsWith('tenant-')) {
        _instance!._tenantId = prefix.substring(7); // Remove "tenant-" prefix
      }
    }
    
    return _instance!;
  }

  /// Check if credentials are near expiration
  /// 
  /// [expiration] Credential expiration timestamp (Unix seconds)
  /// [bufferSeconds] Buffer time in seconds before expiration to consider "near" (default: 300 = 5 minutes)
  /// Returns true if credentials are near expiration or already expired
  bool _isCredentialNearExpiration(int? expiration, {int bufferSeconds = 300}) {
    if (expiration == null) {
      // No expiration means permanent credentials
      return false;
    }
    
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiration = expiration - now;
    
    // Consider near expiration if within buffer time
    return timeUntilExpiration <= bufferSeconds;
  }

  /// Refresh credentials if needed
  /// 
  /// Checks if credentials are near expiration and refreshes them if necessary.
  /// Returns true if credentials were refreshed, false otherwise.
  Future<bool> _refreshCredentialsIfNeeded() async {
    // Only refresh if we have temporary credentials (sessionToken) and tenantId
    if (_tenantId == null || _expiration == null) {
      return false;
    }
    
    // Check if credentials are near expiration
    if (!_isCredentialNearExpiration(_expiration)) {
      return false;
    }
    
    try {
      // Get user credentials for API call
      final credentials = await AccountCredentialsUtils.getCredentials();
      if (credentials == null) {
        print('Warning: Cannot refresh S3 credentials - user credentials unavailable');
        return false;
      }
      
      // Call API to get new credentials
      final newS3Config = await CircleApi.getS3Credentials(
        pubkey: credentials['pubkey'] as String,
        privkey: credentials['privkey'] as String,
        tenantId: _tenantId!,
      );
      
      // Update Minio instance with new credentials
      final uri = Uri.parse(_url!);
      String endPoint = uri.host;
      final useSSL = uri.scheme == 'https';
      final port = uri.port == 0 ? null : uri.port;
      
      _minio = Minio(
        endPoint: endPoint,
        accessKey: newS3Config.accessKeyId,
        secretKey: newS3Config.secretAccessKey,
        useSSL: useSSL,
        port: port,
        region: _region,
        sessionToken: newS3Config.sessionToken,
      );
      
      // Update stored credential info
      _accessKey = newS3Config.accessKeyId;
      _secretKey = newS3Config.secretAccessKey;
      _expiration = newS3Config.expiration;
      
      print('S3 credentials refreshed successfully. New expiration: $_expiration');
      return true;
    } catch (e) {
      print('Warning: Failed to refresh S3 credentials: $e');
      // Continue with existing credentials - upload may fail if expired
      return false;
    }
  }

  /// Upload file with path prefix support for multi-tenant S3 buckets
  /// 
  /// Path format: {pathPrefix}{fileFolder}{filename}
  /// Example: tenant-rb8QlKix/images/avatar.jpg
  /// 
  /// [tags] Optional map of tag key-value pairs to set on the uploaded object.
  /// Tags can be used for S3 lifecycle rules (e.g., FileType=avatar for permanent,
  /// FileType=chat for 30-day expiration).
  /// 
  /// This method implements deduplication by using file hash as filename.
  /// If a file with the same hash already exists, it will skip upload and return the existing URL.
  /// 
  /// Returns s3:// URL format (e.g., s3://bucket/objectName).
  /// The presigned URL will be generated by the cache system when needed for downloading.
  Future<String> uploadFile({
    required File file,
    required String filename,
    required FileType fileType,
    Function(double progress)? onProgress,
    Map<String, String>? tags,
  }) async {
    // Check and refresh credentials if needed before upload
    await _refreshCredentialsIfNeeded();
    
    const presignedProgressRatio = 0.1;
    final fileFolder = getFileFolders(fileType);
    
    // Calculate file hash for deduplication
    final fileBytes = await file.readAsBytes();
    final hash = HashUtil.sha256Bytes(fileBytes);
    
    // Get file extension from original filename or file path
    final ext = filename.getFileExtension();
    final hashFilename = ext.isNotEmpty ? '$hash.$ext' : hash;
    
    // Build object name with path prefix using hash-based filename
    // Format: {pathPrefix}{fileFolder}{hashFilename}
    String objectName;
    if (_pathPrefix != null && _pathPrefix!.isNotEmpty) {
      // Ensure pathPrefix ends with /
      final prefix = _pathPrefix!.endsWith('/') ? _pathPrefix! : '${_pathPrefix!}/';
      objectName = '$prefix$fileFolder$hashFilename';
    } else {
      // Fallback to old format if no path prefix
      objectName = '$fileFolder$hashFilename';
    }
    
    // Check if file already exists to avoid duplicate upload
    try {
      await _minio.statObject(bucketName, objectName);
      // File exists, return s3:// URL without uploading
      final s3Url = 's3://$bucketName/$objectName';
      onProgress?.call(1.0);
      return s3Url;
    } catch (e) {
      // File doesn't exist, proceed with normal upload
      // Continue with upload flow below
    }
    
    await _minio.fPutObject(
      bucketName,
      objectName,
      file.path,
      null,
      (progress) => onProgress?.call(progress * (1 - presignedProgressRatio)),
    );
    
    // Set object tags if provided
    if (tags != null && tags.isNotEmpty) {
      try {
        await _minio.putObjectTagging(bucketName, objectName, tags);
      } catch (e) {
        // Log error but don't fail the upload
        // Tagging failures should not block file uploads
        print('Warning: Failed to set object tags: $e');
      }
    }
    
    // Return s3:// URL instead of presigned URL
    // The presigned URL will be generated by the cache system when needed
    final s3Url = 's3://$bucketName/$objectName';
    onProgress?.call(1.0);
    return s3Url;
  }

  Future<bool> bucketExists() async {
    return await _minio.bucketExists(bucketName);
  }

  /// 
  /// [objectName] The object name to check (without bucket name)
  /// Returns true if object exists, false otherwise
  Future<bool> objectExists(String objectName) async {
    try {
      await _minio.statObject(bucketName, objectName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate a presigned URL for an existing object
  /// 
  /// [objectName] The object name (without bucket name)
  /// [expires] Expiration time in seconds. Default is 7 days.
  /// Returns presigned URL or null if generation fails
  /// 
  /// Note: We skip statObject check because it may fail due to ACL issues.
  /// The presigned URL will still work even if we don't check existence first.
  Future<String?> getPresignedUrl(String objectName, {int? expires}) async {
    try {
      // Calculate max expiration based on sessionToken expiration if using temporary credentials
      final maxExpiresSeconds = _calculateMaxExpiration(expires);
      // Skip statObject check - it may fail due to ACL issues, but presigned URL generation doesn't require it
      final presignedUrl = await _minio.presignedGetObject(bucketName, objectName, expires: maxExpiresSeconds);
      return presignedUrl;
    } catch (e) {
      return null;
    }
  }

  /// Generate a presigned URL from s3:// URL
  /// 
  /// [s3Url] S3 URL in format s3://bucket/objectName
  /// [expires] Expiration time in seconds. Default is 7 days.
  /// Returns presigned URL or null if URL is invalid or object doesn't exist
  Future<String?> getPresignedUrlFromS3Url(String s3Url, {int? expires}) async {
    if (!s3Url.startsWith('s3://')) {
      return null;
    }
    
    try {
      final uri = Uri.parse(s3Url);
      final bucket = uri.host;
      final objectName = uri.path.substring(1); // Remove leading /
      
      if (bucket != bucketName) {
        // Different bucket, cannot generate presigned URL
        return null;
      }
      
      return await getPresignedUrl(objectName, expires: expires);
    } catch (e) {
      return null;
    }
  }

  /// Calculate maximum expiration time for presigned URLs
  /// Takes into account sessionToken expiration if using temporary credentials
  /// 
  /// [requestedExpires] Requested expiration time in seconds
  /// Returns the effective expiration time (may be reduced if sessionToken expires sooner)
  int _calculateMaxExpiration(int? requestedExpires) {
    final defaultExpires = 7 * 24 * 60 * 60; // Default 7 days
    int effectiveExpires = requestedExpires ?? defaultExpires;

    if (_expiration != null) {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final remainingCredentialTime = _expiration! - now;
      // Use 90% of remaining credential time as a buffer
      final maxAllowedExpires = (remainingCredentialTime * 0.9).floor();

      if (effectiveExpires > maxAllowedExpires) {
        return maxAllowedExpires;
      }
    }
    return effectiveExpires;
  }

  static String getFileFolders(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return 'images/';
      case FileType.video:
        return 'video/';
      case FileType.voice:
        return 'voice/';
      case FileType.text:
        return 'text/';
    }
  }
}
