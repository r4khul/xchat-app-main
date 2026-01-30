import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/upload/minio_uploader.dart';
import 'package:ox_common/utils/s3_url_utils.dart';
import 'package:chatcore/chat-core.dart';

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
      final s3Config = await S3ConfigUtils.loadS3ConfigFromCircleDB(circle.id);
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
      );

      // Generate presigned URL
      // Use 7 days expiration (will be adjusted by _calculateMaxExpiration if needed)
      final presignedUrl = await MinioUploader.instance.getPresignedUrl(objectName);

      return presignedUrl;
    } catch (e) {
      print('Error generating presigned URL for s3://$bucket/$objectName: $e');
      return null;
    }
  }
}
