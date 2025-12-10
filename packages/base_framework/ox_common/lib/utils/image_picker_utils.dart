
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ox_common/ox_common.dart';
import 'package:ox_common/navigator/navigator.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_localizable/ox_localizable.dart';
// Android only imports
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

///Title: image_picker_utils
///Description: TODO(Take a photo or select an image from an album)
///Copyright: Copyright (c) 2023
///@author john
///@CheckItem Fill in by oneself
///@since Dart 2.3
class ImagePickerUtils {

  /// Choose an image or video
  ///
  /// Return information of the selected picture or video
  ///
  /// galleryMode enum Select an image or select a video to enumerate
  ///
  /// uiConfig  Select an image or select the theme of the video page Default 0xfffefefe
  ///
  /// selectCount Number of images to select
  ///
  /// showCamera Whether to display the camera button
  ///
  /// cropConfig  Crop configuration (video does not support cropping and compression, this parameter is not available when selecting video)
  ///
  /// compressSize Ignore compression size after selection, will not compress unit KB when the image size is smaller than compressSize
  ///
  /// videoRecordMaxSecond  Maximum video recording time (seconds)
  ///
  /// videoRecordMinSecond  Minimum video recording time (seconds)
  ///
  /// videoSelectMaxSecond  Maximum video duration when selecting a video (seconds)
  ///
  /// videoSelectMinSecond  Minimum video duration when selecting a video (seconds)
  static Future<List<Media>> pickerPaths({
    GalleryMode galleryMode = GalleryMode.image,
    UIConfig? uiConfig,
    int selectCount = 9,
    bool showCamera = false,
    bool showGif = true,
    CropConfig? cropConfig,
    int compressSize = 500,
    int videoRecordMaxSecond = 120,
    int videoRecordMinSecond = 1,
    int videoSelectMaxSecond = 120,
    int videoSelectMinSecond = 1,
    Language language = Language.system,
    BuildContext? context,
  }) async {
    // iOS uses native method channel, Android uses wechat_assets_picker
    if (Platform.isIOS) {
      return await _pickerPathsIOS(
        galleryMode: galleryMode,
        uiConfig: uiConfig,
        selectCount: selectCount,
        showCamera: showCamera,
        showGif: showGif,
        cropConfig: cropConfig,
        compressSize: compressSize,
        videoRecordMaxSecond: videoRecordMaxSecond,
        videoRecordMinSecond: videoRecordMinSecond,
        videoSelectMaxSecond: videoSelectMaxSecond,
        videoSelectMinSecond: videoSelectMinSecond,
        language: language,
      );
    } else {
      return await _pickerPathsAndroid(
        galleryMode: galleryMode,
        uiConfig: uiConfig,
        selectCount: selectCount,
        showCamera: showCamera,
        showGif: showGif,
        cropConfig: cropConfig,
        compressSize: compressSize,
        videoRecordMaxSecond: videoRecordMaxSecond,
        videoRecordMinSecond: videoRecordMinSecond,
        videoSelectMaxSecond: videoSelectMaxSecond,
        videoSelectMinSecond: videoSelectMinSecond,
        language: language,
        context: context,
      );
    }
  }

  /// iOS implementation using native method channel
  static Future<List<Media>> _pickerPathsIOS({
    GalleryMode galleryMode = GalleryMode.image,
    UIConfig? uiConfig,
    int selectCount = 1,
    bool showCamera = false,
    bool showGif = true,
    CropConfig? cropConfig,
    int compressSize = 500,
    int videoRecordMaxSecond = 120,
    int videoRecordMinSecond = 1,
    int videoSelectMaxSecond = 120,
    int videoSelectMinSecond = 1,
    Language language = Language.system,
  }) async {
    Color uiColor = UIConfig.defUiThemeColor;
    if (uiConfig != null) {
      uiColor = uiConfig.uiThemeColor;
    }

    bool enableCrop = false;
    int width = -1;
    int height = -1;
    if (cropConfig != null) {
      enableCrop = cropConfig.enableCrop;
      width = cropConfig.width <= 0 ? -1 : cropConfig.width;
      height = cropConfig.height <= 0 ? -1 : cropConfig.height;
    }

    final Map<String, dynamic> params = <String, dynamic>{
      'galleryMode': galleryMode.name,
      'showGif': showGif,
      'uiColor': {
        "a": 255,
        "r": uiColor.red,
        "g": uiColor.green,
        "b": uiColor.blue,
        "l": (uiColor.computeLuminance() * 255).toInt()
      },
      'selectCount': selectCount,
      'showCamera': showCamera,
      'enableCrop': enableCrop,
      'width': width,
      'height': height,
      'compressSize': compressSize < 50 ? 50 : compressSize,
      'videoRecordMaxSecond': videoRecordMaxSecond,
      'videoRecordMinSecond': videoRecordMinSecond,
      'videoSelectMaxSecond': videoSelectMaxSecond,
      'videoSelectMinSecond': videoSelectMinSecond,
      'language': language.name,
    };
    final List<dynamic> paths =
        await OXCommon.channel.invokeMethod('getPickerPaths', params);
    List<Media> medias = [];
    paths.forEach((data) {
      Media media = Media();
      media.thumbPath = data["thumbPath"];
      media.path = data["path"];
      if (media.path == media.thumbPath) {
        media.galleryMode = GalleryMode.image;
      } else {
        media.galleryMode = GalleryMode.video;
      }
      medias.add(media);
    });
    return medias;
  }

  /// Android implementation using wechat_assets_picker
  static Future<List<Media>> _pickerPathsAndroid({
    GalleryMode galleryMode = GalleryMode.image,
    UIConfig? uiConfig,
    int selectCount = 9,
    bool showCamera = false,
    bool showGif = true,
    CropConfig? cropConfig,
    int compressSize = 500,
    int videoRecordMaxSecond = 120,
    int videoRecordMinSecond = 1,
    int videoSelectMaxSecond = 120,
    int videoSelectMinSecond = 1,
    Language language = Language.system,
    BuildContext? context,
  }) async {
    // Get context from navigator if not provided
    final BuildContext? pickerContext = context ?? 
        (OXNavigator.navigatorKey.currentContext != null 
            ? OXNavigator.navigatorKey.currentContext 
            : null);
    
    if (pickerContext == null) {
      throw Exception('Context is required for wechat_assets_picker');
    }

    // Request permission first
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      return [];
    }

    // Convert GalleryMode to RequestType
    final RequestType requestType;
    switch (galleryMode) {
      case GalleryMode.image:
        requestType = RequestType.image;
        break;
      case GalleryMode.video:
        requestType = RequestType.video;
        break;
      case GalleryMode.all:
        requestType = RequestType.all;
        break;
    }

    // Configure filter options
    final FilterOptionGroup filterOptionGroup = FilterOptionGroup(
      imageOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      videoOption: FilterOption(
        durationConstraint: DurationConstraint(
          min: Duration(seconds: videoSelectMinSecond),
          max: Duration(seconds: videoSelectMaxSecond),
        ),
      ),
    );

    // Set confirm button color based on platform
    // Android: theme purple
    final Color confirmButtonColor = ThemeColor.purple2; // Theme purple color

    // Create ThemeData and customize buttonTheme
    final ThemeData pickerTheme = ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.black,
        secondary: confirmButtonColor,
      ),
    );

    // Configure picker config
    final AssetPickerTextDelegate textDelegate = 
        _getTextDelegateFromLocaleType(Localized.getCurrentLanguage());
    
    final AssetPickerConfig pickerConfig = AssetPickerConfig(
      selectedAssets: <AssetEntity>[],
      maxAssets: selectCount,
      requestType: requestType,
      filterOptions: filterOptionGroup,
      pickerTheme: pickerTheme,
      textDelegate: textDelegate,
      pageSize: 320,
      gridThumbnailSize: const ThumbnailSize(80, 80),
      previewThumbnailSize: const ThumbnailSize(150, 150),
      // Add camera item as special item if needed
      specialItems: showCamera 
          ? [
              SpecialItem<AssetPathEntity>(
                position: SpecialItemPosition.prepend,
                builder: _buildCameraItem,
              ),
            ]
          : const <SpecialItem<AssetPathEntity>>[],
    );

    // Pick assets
    // The picker will automatically handle Android navigation bar with SafeArea
    // It uses BuildContext to determine locale for text display
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      pickerContext,
      pickerConfig: pickerConfig,
    );

    if (result == null || result.isEmpty) {
      return [];
    }

    // Convert AssetEntity to Media
    List<Media> medias = [];
    for (final AssetEntity entity in result) {
      Media media = Media();
      
      // Get file path
      final File? file = await entity.file;
      if (file != null) {
        media.path = file.path;
      }

      // Handle compression for images
      if (entity.type == AssetType.image && compressSize > 0) {
        final Uint8List? imageData = await entity.originBytes;
        if (imageData != null) {
          final int sizeInKB = imageData.length ~/ 1024;
          if (sizeInKB > compressSize) {
            // Compress image
            final Uint8List? compressedData = await entity.thumbnailDataWithSize(
              const ThumbnailSize(200, 200),
              quality: 85,
            );
            if (compressedData != null) {
              // Save compressed image to temp file
              final Directory tempDir = await getTemporaryDirectory();
              final String compressedPath = 
                  '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final File compressedFile = File(compressedPath);
              await compressedFile.writeAsBytes(compressedData);
              media.path = compressedPath;
            }
          }
        }
      }

      // Get thumbnail for videos
      if (entity.type == AssetType.video) {
        final Uint8List? thumbnailData = await entity.thumbnailDataWithSize(
          const ThumbnailSize(200, 200),
          quality: 100,
        );
        if (thumbnailData != null) {
          final Directory tempDir = await getTemporaryDirectory();
          final String thumbPath = 
              '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File thumbFile = File(thumbPath);
          await thumbFile.writeAsBytes(thumbnailData);
          media.thumbPath = thumbPath;
        }
      } else {
        // For images, thumbPath is same as path
        media.thumbPath = media.path;
      }

      // Set gallery mode
      if (entity.type == AssetType.image) {
        media.galleryMode = GalleryMode.image;
      } else if (entity.type == AssetType.video) {
        media.galleryMode = GalleryMode.video;
      }

      medias.add(media);
    }

    return medias;
  }

  // Helper method to get text delegate from LocaleType
  static AssetPickerTextDelegate _getTextDelegateFromLocaleType(LocaleType localeType) {
    switch (localeType) {
      case LocaleType.zh:
        // Simplified Chinese - use default AssetPickerTextDelegate which is Simplified Chinese
        return const AssetPickerTextDelegate();
      case LocaleType.zh_tw:
        return const TraditionalChineseAssetPickerTextDelegate();
      case LocaleType.en:
        return const EnglishAssetPickerTextDelegate();
      case LocaleType.ja:
        return const JapaneseAssetPickerTextDelegate();
      case LocaleType.fr:
        return const FrenchAssetPickerTextDelegate();
      case LocaleType.de:
        return const GermanAssetPickerTextDelegate();
      case LocaleType.ru:
        return const RussianAssetPickerTextDelegate();
      case LocaleType.vi:
        return const VietnameseAssetPickerTextDelegate();
      case LocaleType.ko:
        return const KoreanAssetPickerTextDelegate();
      case LocaleType.ar:
        return const ArabicAssetPickerTextDelegate();
      default:
        // For other languages not supported by wechat_assets_picker, use English
        return const EnglishAssetPickerTextDelegate();
    }
  }

  // Build camera item widget
  // Note: This is a placeholder. For actual camera functionality,
  // you should integrate wechat_camera_picker or use ImagePicker.openCamera
  static Widget? _buildCameraItem(
    BuildContext context,
    AssetPathEntity? path,
    PermissionState permissionState,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle camera tap - you can integrate wechat_camera_picker here
        // For now, just close the picker
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.camera_alt, size: 48),
        ),
      ),
    );
  }

  /// Return information of the selected picture or video
  ///
  /// cameraMimeType  CameraMimeType.photo is a photo, CameraMimeType.video is a video
  ///
  /// cropConfig  Crop configuration (video does not support cropping and compression, this parameter is not available when selecting video)
  ///
  /// compressSize Ignore compression size after selection, will not compress unit KB when the image size is smaller than compressSize
  ///
  /// videoRecordMaxSecond  Maximum video recording time (seconds)
  ///
  /// videoRecordMinSecond  Minimum video recording time (seconds)
  ///

  static Future<Media?> openCamera({
    CameraMimeType cameraMimeType = CameraMimeType.photo,
    CropConfig? cropConfig,
    int compressSize = 500,
    int videoRecordMaxSecond = 120,
    int videoRecordMinSecond = 1,
    Language language = Language.system,
  }) async {

    bool enableCrop = false;
    int width = -1;
    int height = -1;
    if (cropConfig != null) {
      enableCrop = cropConfig.enableCrop;
      width = cropConfig.width <= 0 ? -1 : cropConfig.width;
      height = cropConfig.height <= 0 ? -1 : cropConfig.height;
    }

    Color uiColor = UIConfig.defUiThemeColor;
    final Map<String, dynamic> params = <String, dynamic>{
      'galleryMode': "image",
      'showGif': true,
      'uiColor': {
        "a": 255,
        "r": uiColor.red,
        "g": uiColor.green,
        "b": uiColor.blue,
        "l": (uiColor.computeLuminance() * 255).toInt()
      },
      'selectCount': 1,
      'showCamera': false,
      'enableCrop': enableCrop,
      'width': width,
      'height': height,
      'compressSize': compressSize < 50 ? 50 : compressSize,
      'cameraMimeType': cameraMimeType.name,
      'videoRecordMaxSecond': videoRecordMaxSecond,
      'videoRecordMinSecond': videoRecordMinSecond,
      'language': language.name,
    };
    final List<dynamic>? paths =
    await OXCommon.channel.invokeMethod('getPickerPaths', params);

    if (paths != null && paths.length > 0) {
      Media media = Media();
      media.thumbPath = paths[0]["thumbPath"];
      media.path = paths[0]["path"];
      if(cameraMimeType == CameraMimeType.photo){
        media.galleryMode = GalleryMode.image;
      }else{
        media.galleryMode = GalleryMode.video;
      }
      return media;
    }

    return null;
  }
}

enum GalleryMode {
  image,
  video,
  all,
}

enum CameraMimeType {
  photo,
  video,
}

class Media {
  ///Video thumbnail image path
  String? thumbPath;

  ///Video path or image path
  String? path;
  GalleryMode? galleryMode;

  @override
  String toString() {
    return '( thumbPath = $thumbPath, path = $path, galleryMode = ${galleryMode?.name} )';
  }
}

/// Select image page color configuration
class UIConfig {
  static const Color defUiThemeColor = Color(0xfffefefe);
  Color uiThemeColor;

  /// uiThemeColor
  UIConfig({this.uiThemeColor = defUiThemeColor});
}

///Crop configuration
class CropConfig {

  bool enableCrop = false;

  ///Cropped width ratio
  int width = -1;

  ///Crop height ratio
  int height = -1;

  CropConfig({this.enableCrop = false, this.width = -1, this.height = -1});
}

enum Language {
  system,

  chinese,

  traditional_chinese,

  english,

  japanese,

  france,

  german,

  russian,

  vietnamese,

  korean,

  portuguese,

  spanish,

  arabic,
}