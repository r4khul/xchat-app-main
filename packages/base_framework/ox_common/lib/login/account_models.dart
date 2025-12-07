import 'dart:collection';

import 'package:isar/isar.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:nostr_core_dart/nostr.dart' hide Filter;
import 'login_models.dart';

part 'account_models.g.dart';

/// Account level key-value storage
/// 
/// Stores various account-level information in key-value format
/// Examples: pubkey, createdAt, lastLoginAt, themeMode, language, fontSize, etc.
@collection
class AccountDataISAR {
  int id = 0;

  @Index(unique: true)
  String keyName;

  String? stringValue;
  int? intValue;
  double? doubleValue;
  bool? boolValue;

  int updatedAt;

  AccountDataISAR({
    this.keyName = '',
    this.stringValue,
    this.intValue,
    this.doubleValue,
    this.boolValue,
    this.updatedAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': keyName,
      'stringValue': stringValue,
      'intValue': intValue,
      'doubleValue': doubleValue,
      'boolValue': boolValue,
      'updatedAt': updatedAt,
    };
  }

  static AccountDataISAR fromMap(Map<String, dynamic> map) {
    return AccountDataISAR(
      keyName: map['key'] ?? '',
      stringValue: map['stringValue'],
      intValue: map['intValue'],
      doubleValue: map['doubleValue']?.toDouble(),
      boolValue: map['boolValue'],
      updatedAt: map['updatedAt'] ?? 0,
    );
  }

  // Helper methods for different value types
  static AccountDataISAR createString(String key, String value) {
    return AccountDataISAR(
      keyName: key,
      stringValue: value,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static AccountDataISAR createInt(String key, int value) {
    return AccountDataISAR(
      keyName: key,
      intValue: value,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static AccountDataISAR createDouble(String key, double value) {
    return AccountDataISAR(
      keyName: key,
      doubleValue: value,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static AccountDataISAR createBool(String key, bool value) {
    return AccountDataISAR(
      keyName: key,
      boolValue: value,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Common account data keys
  static const String keyPubkey = 'pubkey';
  static const String keyCreatedAt = 'createdAt';
  static const String keyLastLoginAt = 'lastLoginAt';
  static const String keyThemeMode = 'themeMode';
  static const String keyPrimaryColor = 'primaryColor';
  static const String keyLanguage = 'language';
  static const String keyLocale = 'locale';
  static const String keyFontSize = 'fontSize';
  static const String keyFontFamily = 'fontFamily';
}

/// Account level schemas utilities
class AccountSchemas {
  AccountSchemas._(); // Private constructor to prevent instantiation

  // Private static list to avoid recreating the list every time
  static final List<IsarGeneratedSchema> _schemas = [
    AccountDataISARSchema,
  ];

  /// Get account level schemas for independent Isar instance
  /// Returns an unmodifiable view to prevent external modification
  static List<IsarGeneratedSchema> get schemas =>
      UnmodifiableListView(_schemas);
}

/// Account login types
enum LoginType {
  nesc(1),           // Private key login
  androidSigner(2),  // Amber signer login  
  remoteSigner(3);   // NostrConnect remote signer login
  
  const LoginType(this.value);
  final int value;
  
  static LoginType fromValue(int value) {
    return LoginType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LoginType.nesc,
    );
  }
}

/// Account model for LoginManager
class AccountModel {
  AccountModel({
    required this.pubkey,
    required this.loginType,
    this.privateKey,
    required this.encryptedPrivKey,
    this.encryptedPrivKeyFuture,
    required this.defaultPassword,
    required this.nostrConnectUri,
    this.nostrConnectClientPrivkey,
    required this.circles,
    required this.createdAt,
    required this.lastLoginAt,
    this.lastLoginCircleId,
    this.pushToken,
    required this.db,
  });

  final String pubkey;
  final LoginType loginType;
  String? privateKey;
  String encryptedPrivKey;     // Only has value for nesc login type
  Future<String>? encryptedPrivKeyFuture;

  final String defaultPassword;      // Used to decrypt private key
  final String nostrConnectUri;     // Only has value for remoteSigner login type
  final String? nostrConnectClientPrivkey; // Only has value for remoteSigner login type
  final List<Circle> circles;
  final int createdAt;
  final int lastLoginAt;
  String? lastLoginCircleId;   // Last logged in circle ID
  String? pushToken;           // Push notification token
  
  late Isar db;

  AccountModel copyWith({
    String? pubkey,
    LoginType? loginType,
    String? encryptedPrivKey,
    String? defaultPassword,
    String? nostrConnectUri,
    String? nostrConnectClientPrivkey,
    List<Circle>? circles,
    int? createdAt,
    int? lastLoginAt,
    String? lastLoginCircleId,
    String? pushToken,
    bool? hasUpload,
  }) {
    return AccountModel(
      pubkey: pubkey ?? this.pubkey,
      loginType: loginType ?? this.loginType,
      privateKey: this.privateKey,
      encryptedPrivKey: encryptedPrivKey ?? this.encryptedPrivKey,
      encryptedPrivKeyFuture: this.encryptedPrivKeyFuture,
      defaultPassword: defaultPassword ?? this.defaultPassword,
      nostrConnectUri: nostrConnectUri ?? this.nostrConnectUri,
      nostrConnectClientPrivkey: nostrConnectClientPrivkey ?? this.nostrConnectClientPrivkey,
      circles: circles ?? this.circles,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginCircleId: lastLoginCircleId ?? this.lastLoginCircleId,
      pushToken: pushToken ?? this.pushToken,
      db: db,
    );
  }
}

/// Helper class for AccountDataISAR conversion
class AccountHelper {
  // AccountDataISAR keys
  static const String keyPubkey = 'pubkey';
  static const String keyLoginType = 'login_type';
  static const String keyEncryptedPrivKey = 'encrypted_priv_key';
  static const String keyDefaultPassword = 'default_password';
  static const String keyNostrConnectUri = 'nostr_connect_uri';
  static const String keyNostrConnectClientPrivkey = 'nostr_connect_client_privkey';
  static const String keyCircles = 'circles';
  static const String keyCreatedAt = 'created_at';
  static const String keyLastLoginAt = 'last_login_at';
  static const String keyLastLoginCircleId = 'last_login_circle_id';
  static const String keyPushToken = 'push_token';
  static const String keyHasUpload = 'has_upload';

  /// Convert AccountModel to list of AccountDataISAR entries
  static List<AccountDataISAR> toAccountDataList(AccountModel account) {
    final db = account.db;
    final result = <AccountDataISAR>[
      AccountDataISAR.createString(keyPubkey, account.pubkey)..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createInt(keyLoginType, account.loginType.value)..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createString(keyEncryptedPrivKey, account.encryptedPrivKey)..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createString(keyDefaultPassword, account.defaultPassword)..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createString(keyCircles, 
        jsonEncode(account.circles.map((c) => c.toJson()).toList()))..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createInt(keyCreatedAt, account.createdAt)..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createInt(keyLastLoginAt, account.lastLoginAt)..id = db.accountDataISARs.autoIncrement(),
      AccountDataISAR.createString(keyNostrConnectUri, account.nostrConnectUri)..id = db.accountDataISARs.autoIncrement(),
    ];
  
    if (account.lastLoginCircleId != null) {
      result.add(AccountDataISAR.createString(keyLastLoginCircleId, account.lastLoginCircleId!)..id = db.accountDataISARs.autoIncrement());
    }
    
    if (account.pushToken != null) {
      result.add(AccountDataISAR.createString(keyPushToken, account.pushToken!)..id = db.accountDataISARs.autoIncrement());
    }
    
    if (account.nostrConnectClientPrivkey != null) {
      result.add(AccountDataISAR.createString(keyNostrConnectClientPrivkey, account.nostrConnectClientPrivkey!)..id = db.accountDataISARs.autoIncrement());
    }
    
    return result;
  }

  /// Load AccountModel from AccountDataISAR entries
  static Future<AccountModel?> fromAccountDataList(
    Isar accountDb, 
    String pubkey,
  ) async {
    try {
      final accountData = await accountDb.accountDataISARs.where()
        .anyOf([keyPubkey, keyLoginType, keyEncryptedPrivKey, keyDefaultPassword, 
               keyNostrConnectUri, keyNostrConnectClientPrivkey, keyCircles, keyCreatedAt, keyLastLoginAt, keyLastLoginCircleId, keyPushToken, keyHasUpload],
               (q, String key) => q.keyNameEqualTo(key))
        .findAll();

      if (accountData.isEmpty) return null;

      final dataMap = <String, dynamic>{};
      for (final data in accountData) {
        if (data.stringValue != null) {
          dataMap[data.keyName] = data.stringValue;
        } else if (data.intValue != null) {
          dataMap[data.keyName] = data.intValue;
        } else if (data.doubleValue != null) {
          dataMap[data.keyName] = data.doubleValue;
        } else if (data.boolValue != null) {
          dataMap[data.keyName] = data.boolValue;
        }
      }

      // Parse circles
      List<Circle> circles = [];
      if (dataMap[keyCircles] != null) {
        final circlesJson = jsonDecode(dataMap[keyCircles] as String) as List;
        circles = circlesJson
            .map((json) => Circle.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final pubkey = dataMap[keyPubkey] as String?;
      final loginTypeRaw = dataMap[keyLoginType] as int?;
      final encryptedPrivKey = dataMap[keyEncryptedPrivKey] as String?;
      final defaultPassword = dataMap[keyDefaultPassword] as String?;
      final nostrConnectUri = dataMap[keyNostrConnectUri] as String?;
      final nostrConnectClientPrivkey = dataMap[keyNostrConnectClientPrivkey] as String?;
      final hasUpload = dataMap[keyHasUpload] as bool? ?? false;
      if (pubkey == null ||
          loginTypeRaw == null ||
          encryptedPrivKey == null ||
          defaultPassword == null ||
          nostrConnectUri == null) {
        return null;
      }

      return AccountModel(
        pubkey: pubkey,
        loginType: LoginType.fromValue(loginTypeRaw),
        encryptedPrivKey: encryptedPrivKey,
        defaultPassword: defaultPassword,
        nostrConnectUri: nostrConnectUri,
        nostrConnectClientPrivkey: nostrConnectClientPrivkey,
        circles: circles,
        createdAt: dataMap[keyCreatedAt] as int? ?? DateTime.now().millisecondsSinceEpoch,
        lastLoginAt: dataMap[keyLastLoginAt] as int? ?? DateTime.now().millisecondsSinceEpoch,
        lastLoginCircleId: dataMap[keyLastLoginCircleId] as String?,
        pushToken: dataMap[keyPushToken] as String?,
        db: accountDb,
      );
    } catch (e) {
      debugPrint('Failed to load AccountModel: $e');
      return null;
    }
  }
}

extension AccountHelperEx on AccountModel {

  static String getPrivateKey(String encryptedPrivKey, String password) {
    final encryptedBytes = hex.decode(encryptedPrivKey);
    final decryptedBytes = decryptPrivateKey(
      Uint8List.fromList(encryptedBytes),
      password,
    );
    return hex.encode(decryptedBytes);
  }

  // Static method to run in isolate for private key decryption
  static Future<String> _decodeAndEncodePrivkey(Map<String, String> params) async {
    try {
      final encryptedPrivKey = params['encryptedPrivKey']!;
      final password = params['password']!;
      final privkey = getPrivateKey(encryptedPrivKey, password);
      return Nip19.encodePrivkey(privkey);
    } catch (e) {
      print('Error in isolate decoding private key: $e');
      return '';
    }
  }

  String getEncodedPubkey() {
    return Nip19.encodePubkey(pubkey);
  }

  Future<String> getEncodedPrivkey() async {
    // Use compute to run the expensive decryption operation in isolate
    final params = {
      'encryptedPrivKey': encryptedPrivKey,
      'password': defaultPassword,
    };
    return await compute(_decodeAndEncodePrivkey, params);
  }
}