import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:ox_common/upload/upload_exception.dart';
import 'string_util.dart';
import 'base64.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'hash_util.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:chatcore/chat-core.dart';

// This uploader not complete.
class BolssomUploader {
  static var dio = Dio();

  static Future<String?> upload(String endPoint, String filePath, {
    String? fileName,
    Function(double progress)? onProgress,
  }) async {
    var uri = Uri.tryParse(endPoint);
    if (uri == null) {
      return null;
    }
    var uploadApiPath = Uri(
            scheme: uri.scheme,
            userInfo: uri.userInfo,
            host: uri.host,
            port: uri.port,
            path: "/upload")
        .toString();

    String? payload;
    MultipartFile? multipartFile;
    Uint8List? bytes;
    if (BASE64.check(filePath)) {
      bytes = BASE64.toData(filePath);
    } else {
      var file = File(filePath);
      bytes = file.readAsBytesSync();

      if (StringUtil.isBlank(fileName)) {
        fileName = filePath.split("/").last;
      }
    }

    if (bytes.isEmpty) {
      return null;
    }

    var fileSize = bytes.length;
    log("file size is ${bytes.length}");
    payload = HashUtil.sha256Bytes(bytes);
    multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: fileName,
    );

    Map<String, String>? headers = {};
    if (StringUtil.isNotBlank(fileName)) {
      var mt = lookupMimeType(fileName!);
      if (StringUtil.isNotBlank(mt)) {
        headers["Content-Type"] = mt!;
      }
    }
    if (StringUtil.isBlank(headers["Content-Type"])) {
      if (multipartFile.contentType != null) {
        headers["Content-Type"] = multipartFile.contentType!.mimeType;
      } else {
        headers["Content-Type"] = "multipart/form-data";
      }
    }

    List<List<String>> tags = [];
    tags.add(["t", "upload"]);
    tags.add([
      "expiration",
      ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60 * 10).toString()
    ]);
    tags.add(["size", "$fileSize"]);
    tags.add(["x", payload]);
    Event nip98Event = await Event.from(
        kind: 24242,
        tags: tags,
        content: "Upload $fileName",
        pubkey: Account.sharedInstance.currentPubkey,
        privkey: Account.sharedInstance.currentPrivkey);
    headers["Authorization"] =
        "Nostr ${base64Url.encode(utf8.encode(jsonEncode(nip98Event.toJson())))}";

    var isMockProgress = true;
    double mockProgress = 0.0;
    Timer? timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isMockProgress) {
        timer.cancel();
        return;
      }
      onProgress?.call((mockProgress += 0.005).clamp(0.0, 0.9));
    });
    try {
      var response = await dio.put(
        uploadApiPath,
        data: bytes,
        // data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return true;
          },
        ),
        onSendProgress: (count, total) {
          if (isMockProgress && total > 0 && count <= total) {
            isMockProgress = false;
          }
          if (!isMockProgress) {
            onProgress?.call(count / total);
          }
        },
      );
      timer.cancel();
      timer = null;
      var body = response.data;
      log("Blossom upload response: ${response.data}");
      if (body is Map<String, dynamic> && body["url"] != null) {
        return body["url"];
      } else {
        throw UploadException('${uri.host} Bad Gateway');
      }
    } catch (e) {
      timer?.cancel();
      print("BolssomUploader.upload upload exception:");
      print(e);
      rethrow;
    }
  }

  static Future<String?> uploadWithStandard(
      String endPoint,
      String filePath, {
        String? fileName,
        Function(double progress)? onProgress,
      }) async {
    final uri = Uri.tryParse(endPoint);
    if (uri == null) return null;

    final uploadApiPath = Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.port,
      path: "/upload",
    ).toString();

    // read bytes
    Uint8List bytes;
    if (BASE64.check(filePath)) {
      bytes = BASE64.toData(filePath);
    } else {
      final file = File(filePath);
      bytes = await file.readAsBytes();
      fileName ??= file.uri.pathSegments.last;
    }

    if (bytes.isEmpty) return null;

    final int fileSize = bytes.length;
    log("Blossom upload file size: $fileSize");

    // hash
    final String sha256 = HashUtil.sha256Bytes(bytes);

    // MIME
    final String contentType =
        lookupMimeType(fileName ?? '') ?? 'application/octet-stream';

    // Blossom JSON body
    final Map<String, dynamic> jsonBody = {
      "data": base64Encode(bytes), // Blossom 要求纯 base64
      "content_type": contentType,
      "size": fileSize,
      "sha256": sha256,
    };
    // NIP-98 Authorization
    final List<List<String>> tags = [
      ["t", "upload"],
      [
        "expiration",
        ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60 * 10).toString()
      ],
      ["size", "$fileSize"],
      ["x", sha256],
    ];

    final Event nip98Event = await Event.from(
      kind: 24242,
      tags: tags,
      content: "Upload $fileName",
      pubkey: Account.sharedInstance.currentPubkey,
      privkey: Account.sharedInstance.currentPrivkey,
    );

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization":
      "Nostr ${base64Url.encode(utf8.encode(jsonEncode(nip98Event.toJson())))}",
    };

    // Mock progress
    bool isMockProgress = true;
    double mockProgress = 0.0;
    Timer timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!isMockProgress) {
        t.cancel();
        return;
      }
      mockProgress = (mockProgress + 0.005).clamp(0.0, 0.9);
      onProgress?.call(mockProgress);
    });

    try {
      // Network put
      final response = await dio.put(
        uploadApiPath,
        data: jsonEncode(jsonBody),
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
        ),
        onSendProgress: (count, total) {
          if (total > 0 && count <= total) {
            isMockProgress = false;
            onProgress?.call(count / total);
          }
        },
      );

      timer.cancel();

      log("Blossom upload response: ${response.data}");
      final body = response.data;
      if (body is Map<String, dynamic> && body["url"] != null) {
        onProgress?.call(1.0);
        return body["url"];
      }

      throw UploadException("${uri.host} Bad Gateway");
    } catch (e) {
      timer.cancel();
      log("BlossomUploader.upload exception: $e");
      rethrow;
    }
  }
}
