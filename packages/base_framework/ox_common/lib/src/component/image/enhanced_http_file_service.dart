import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/upload/minio_uploader.dart';
import 'package:ox_common/utils/s3_url_utils.dart';
import 'package:chatcore/chat-core.dart';
import 'package:ox_common/utils/account_credentials_utils.dart';

/// Enhanced HTTP FileService that supports both standard HTTP/HTTPS URLs and s3:// URLs
/// 
/// This service extends HttpFileService and adds support for s3:// URLs by automatically
/// converting them to presigned URLs using the current circle's S3 configuration.
/// For standard HTTP/HTTPS URLs, it uses the parent class's standard HTTP download logic.
class EnhancedHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    // Check if URL is s3:// format
    if (isS3Url(url)) {
      // Parse s3:// URL
      final parsed = parseS3Url(url);
      if (parsed == null) {
        throw Exception('Invalid s3:// URL: $url');
      }

      final bucket = parsed['bucket']!;
      final objectName = parsed['objectName']!;

      // Get current circle's S3 config and generate presigned URL
      final presignedUrl = await _generatePresignedUrl(bucket, objectName);
      if (presignedUrl == null) {
        throw Exception('Failed to generate presigned URL for: $url');
      }

      // Use parent class to download with presigned URL
      return super.get(presignedUrl, headers: headers);
    }

    // For non-s3:// URLs, use default HTTP service
    return super.get(url, headers: headers);
  }

  /// Generate presigned URL using current circle's S3 configuration
  /// 
  /// [bucket] S3 bucket name
  /// [objectName] S3 object name (path)
  /// Returns presigned URL or null if generation fails
  Future<String?> _generatePresignedUrl(String bucket, String objectName) async {
    try {
      final currentState = LoginManager.instance.currentState;
      final circle = currentState.currentCircle;
      
      if (circle == null) {
        print('Warning: No current circle available for S3 URL generation');
        return null;
      }

      // Load S3 config from circle
      S3Config? s3Config = await S3ConfigUtils.loadS3ConfigFromCircleDB(circle.id);
      
      // Check if S3 config is expired or near expiration
      bool needsRefresh = false;
      if (s3Config != null) {
        needsRefresh = _isS3ConfigExpired(s3Config);
      }
      
      // If no S3 config found or expired, and this is a paid relay, try to fetch from API
      if ((s3Config == null || needsRefresh) && CircleApi.isPaidRelay(circle.relayUrl)) {
        try {
          final circleDB = await Account.sharedInstance.getCircleById(circle.id);
          final tenantId = circleDB?.tenantId;
          if (tenantId != null && tenantId.isNotEmpty) {
            final credentials = await AccountCredentialsUtils.getCredentials();
            if (credentials != null) {
              s3Config = await CircleApi.getS3Credentials(
                pubkey: credentials['pubkey'] as String,
                privkey: credentials['privkey'] as String,
                tenantId: tenantId,
              );
              
              // Save to database
              await S3ConfigUtils.saveS3ConfigToCircleDB(
                circleId: circle.id,
                s3Config: s3Config,
              );
            }
          }
        } catch (e) {
          print('Warning: Failed to fetch S3 config from API: $e');
        }
      }
      
      if (s3Config == null) {
        print('Warning: No S3 config found for circle: ${circle.id}');
        return null;
      }

      // Verify bucket matches
      if (s3Config.bucket != bucket) {
        print('Warning: Bucket mismatch. Expected: ${s3Config.bucket}, got: $bucket');
        return null;
      }

      // Initialize MinioUploader with current circle's S3 config
      final url = S3ConfigUtils.getS3FileServerUrl(s3Config);
      MinioUploader.init(
        url: url,
        accessKey: s3Config.accessKeyId,
        secretKey: s3Config.secretAccessKey,
        bucketName: s3Config.bucket,
        pathPrefix: s3Config.pathPrefix,
        region: s3Config.region,
        sessionToken: s3Config.sessionToken,
        expiration: s3Config.expiration,
        circleId: circle.id, // Pass circleId for credential refresh and database update
      );

      // Generate presigned URL
      // getPresignedUrl will automatically check and refresh credentials if needed
      // Use 7 days expiration (will be adjusted by _calculateMaxExpiration if needed)
      final presignedUrl = await MinioUploader.instance.getPresignedUrl(objectName);

      return presignedUrl;
    } catch (e) {
      print('Error generating presigned URL for s3://$bucket/$objectName: $e');
      return null;
    }
  }

  /// Check if S3 config is expired or near expiration
  /// 
  /// [s3Config] S3 configuration to check
  /// [bufferSeconds] Buffer time in seconds before expiration (default: 300 seconds = 5 minutes)
  /// Returns true if credentials are expired or near expiration
  bool _isS3ConfigExpired(S3Config s3Config, {int bufferSeconds = 300}) {
    // If no expiration, credentials are permanent
    if (s3Config.expiration == null) {
      return false;
    }
    
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final timeUntilExpiration = s3Config.expiration! - now;
    
    // Consider expired if within buffer time or already expired
    return timeUntilExpiration <= bufferSeconds;
  }
}
