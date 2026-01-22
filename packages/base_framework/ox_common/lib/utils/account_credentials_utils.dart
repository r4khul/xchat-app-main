import 'package:flutter/foundation.dart';
import 'package:ox_common/login/login_manager.dart';
import 'package:ox_common/login/account_models.dart';

/// Utility class for getting account credentials for API calls
class AccountCredentialsUtils {
  AccountCredentialsUtils._();

  /// Get account credentials (pubkey and privkey) from LoginManager
  /// 
  /// Returns a map with 'pubkey' and 'privkey' keys, or null if credentials cannot be obtained.
  /// 
  /// For LoginType.nesc: decrypts private key from encrypted storage
  /// For LoginType.androidSigner: returns 'androidSigner' as privkey
  /// For LoginType.remoteSigner: returns 'remoteSigner' as privkey
  static Future<Map<String, String>?> getCredentials() async {
    try {
      final account = LoginManager.instance.currentState.account;
      if (account == null) {
        return null;
      }

      final pubkey = account.pubkey;
      if (pubkey.isEmpty) {
        return null;
      }

      String? privkey;
      
      switch (account.loginType) {
        case LoginType.nesc:
          if (account.privateKey != null && account.privateKey!.isNotEmpty) {
            privkey = account.privateKey;
          } else {
            try {
              privkey = AccountHelperEx.getPrivateKey(
                account.encryptedPrivKey,
                account.defaultPassword,
              );
            } catch (e) {
              debugPrint('Failed to decrypt private key: $e');
              return null;
            }
          }
          break;
        case LoginType.androidSigner:
          privkey = 'androidSigner';
          break;
        case LoginType.remoteSigner:
          privkey = 'remoteSigner';
          break;
      }

      if (privkey == null || privkey.isEmpty) {
        return null;
      }

      return {
        'pubkey': pubkey,
        'privkey': privkey,
      };
    } catch (e) {
      debugPrint('Error getting account credentials: $e');
      return null;
    }
  }
}

