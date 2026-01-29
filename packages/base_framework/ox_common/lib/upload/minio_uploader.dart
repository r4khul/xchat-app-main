import 'dart:io';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';
import 'package:ox_common/upload/file_type.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/utils/account_credentials_utils.dart';

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
    
    // Build object name with path prefix
    // Format: {pathPrefix}{fileFolder}{filename}
    String objectName;
    if (_pathPrefix != null && _pathPrefix!.isNotEmpty) {
      // Ensure pathPrefix ends with /
      final prefix = _pathPrefix!.endsWith('/') ? _pathPrefix! : '${_pathPrefix!}/';
      objectName = '$prefix$fileFolder$filename';
    } else {
      // Fallback to old format if no path prefix
      objectName = '$fileFolder$filename';
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
    
    int expires = 7 * 24 * 60 * 60;
    final url = await _minio.presignedGetObject(bucketName, objectName, expires: expires);
    onProgress?.call(1.0);
    return url;
  }

  Future<bool> bucketExists() async {
    return await _minio.bucketExists(bucketName);
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
