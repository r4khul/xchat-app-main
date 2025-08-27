import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:ox_common/component.dart';
import 'package:ox_common/utils/file_encryption_utils.dart';
import 'package:ox_common/utils/string_utils.dart';
import 'package:ox_common/widgets/common_loading.dart';
import 'package:ox_common/widgets/common_toast.dart';
import 'package:ox_localizable/ox_localizable.dart';

class ImageSaveUtils {
  static Future<bool> saveImageToGallery({
    required String imageUri,
    String? decryptKey,
    String? decryptNonce,
    required BuildContext context,
    String? fileName,
  }) async {
    if (imageUri.isEmpty) return false;

    final isEncryptedFile = decryptKey != null;
    final actualFileName = fileName ?? imageUri.split('/').lastOrNull?.split('?').firstOrNull ?? '';
    final isGIF = actualFileName.contains('.gif');

    unawaited(OXLoading.show());

    try {
      var result;
      
      if (imageUri.isRemoteURL) {
        // Remote image
        final imageManager = await CLCacheManager.getCircleCacheManager(CacheFileType.image);
        
        File imageFile = await imageManager.getSingleFile(imageUri)
            .timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception('time out');
        });

        switch ((isGIF, isEncryptedFile)) {
          case (true, false):
            result = await ImageGallerySaverPlus.saveFile(
              imageFile.path,
              isReturnPathOfIOS: true,
            );
            break;

          case (true, true):
            final decryptedFile = await FileEncryptionUtils.decryptFile(
              encryptedFile: imageFile,
              decryptKey: decryptKey!,
              decryptNonce: decryptNonce,
            );
            result = await ImageGallerySaverPlus.saveFile(
              decryptedFile.path,
              isReturnPathOfIOS: true,
            );
            decryptedFile.delete();
            break;

          case (false, false):
            final imageData = await imageFile.readAsBytes();
            result = await ImageGallerySaverPlus.saveImage(Uint8List.fromList(imageData));
            break;

          case (false, true):
            final imageData = await FileEncryptionUtils.decryptFileInMemory(
              imageFile,
              decryptKey!,
              decryptNonce,
            );
            result = await ImageGallerySaverPlus.saveImage(Uint8List.fromList(imageData));
            break;
        }
      } else if (imageUri.isImageBase64) {
        final imageData = await Base64ImageProvider.decodeBase64ToBytes(imageUri);
        result = await ImageGallerySaverPlus.saveImage(imageData, quality: 100);
      } else {
        // Local image
        final imageFile = File(imageUri);
        if (decryptKey != null) {
          final decryptData = await FileEncryptionUtils.decryptFileInMemory(
            imageFile,
            decryptKey,
            decryptNonce,
          );
          result = await ImageGallerySaverPlus.saveImage(decryptData);
        } else {
          final imageData = await imageFile.readAsBytes();
          result = await ImageGallerySaverPlus.saveImage(imageData);
        }
      }

      unawaited(OXLoading.dismiss());

      if (result != null) {
        unawaited(CommonToast.instance.show(context, Localized.text('ox_common.str_saved_to_album')));
        return true;
      } else {
        unawaited(CommonToast.instance.show(context, Localized.text('ox_common.str_save_failed')));
        return false;
      }
    } catch (e) {
      unawaited(OXLoading.dismiss());
      unawaited(CommonToast.instance.show(context, e.toString()));
      return false;
    }
  }
}
