/// Utility functions for parsing and handling S3 URLs

/// Parse s3:// URL and extract bucket and object name
/// 
/// [s3Url] S3 URL in format s3://bucket/objectName
/// Returns a map with 'bucket' and 'objectName' keys, or null if URL is invalid
Map<String, String>? parseS3Url(String s3Url) {
  if (!s3Url.startsWith('s3://')) {
    return null;
  }
  
  try {
    final uri = Uri.parse(s3Url);
    final bucket = uri.host;
    final objectName = uri.path.substring(1); // Remove leading /
    
    if (bucket.isEmpty || objectName.isEmpty) {
      return null;
    }
    
    return {
      'bucket': bucket,
      'objectName': objectName,
    };
  } catch (e) {
    return null;
  }
}

/// Check if a URL is an s3:// URL
bool isS3Url(String url) {
  return url.startsWith('s3://');
}

/// Check if a URL is a presigned URL (contains X-Amz-Signature)
bool isPresignedUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.queryParameters.containsKey('X-Amz-Signature') ||
        uri.queryParameters.containsKey('x-amz-signature');
  } catch (e) {
    return false;
  }
}

