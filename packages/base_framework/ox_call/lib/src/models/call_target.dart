import 'package:flutter/foundation.dart';
import 'package:chatcore/chat-core.dart';

/// Represents a call target (recipient of a call).
///
/// A target encapsulates both the user's pubkey and the private group context
/// required for signaling. This abstracts away the underlying signaling requirements
/// from the call logic layer.
@immutable
class CallTarget {
  /// The pubkey of the target user.
  final String pubkey;

  /// The private group ID for signaling context.
  final String privateGroupId;

  const CallTarget({
    required this.pubkey,
    required this.privateGroupId,
  });

  /// Create a target from a user and their associated private group.
  ///
  /// Use this when you have a [UserDBISAR] object and know the private group ID.
  factory CallTarget.fromUser(UserDBISAR user, String privateGroupId) {
    return CallTarget(
      pubkey: user.pubKey,
      privateGroupId: privateGroupId,
    );
  }

  /// Create a target from pubkey and private group ID.
  ///
  /// Use this when you only have the raw identifiers.
  factory CallTarget.fromPubkey(String pubkey, String privateGroupId) {
    return CallTarget(
      pubkey: pubkey,
      privateGroupId: privateGroupId,
    );
  }

  /// Get the associated user from the database.
  ///
  /// Returns a [ValueNotifier] that will update when user info changes.
  ValueNotifier<UserDBISAR?> get user$ {
    return Account.sharedInstance.getUserNotifier(pubkey);
  }

  /// Get the associated user synchronously.
  ///
  /// May return null if user info is not yet loaded.
  UserDBISAR? get user => user$.value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CallTarget &&
        other.pubkey == pubkey &&
        other.privateGroupId == privateGroupId;
  }

  @override
  int get hashCode => Object.hash(pubkey, privateGroupId);

  @override
  String toString() {
    return 'CallTarget(pubkey: ${pubkey.length > 8 ? '${pubkey.substring(0, 8)}...' : pubkey}, '
        'privateGroupId: ${privateGroupId.length > 8 ? '${privateGroupId.substring(0, 8)}...' : privateGroupId})';
  }

  /// Create a copy with optional new values.
  CallTarget copyWith({
    String? pubkey,
    String? privateGroupId,
  }) {
    return CallTarget(
      pubkey: pubkey ?? this.pubkey,
      privateGroupId: privateGroupId ?? this.privateGroupId,
    );
  }
}