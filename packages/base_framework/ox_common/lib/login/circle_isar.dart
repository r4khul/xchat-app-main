import 'package:isar/isar.dart';
import 'login_models.dart';

part 'circle_isar.g.dart';

/// Circle data model stored in accountDB
@collection
class CircleISAR {
  int id = 0;

  /// Account public key this circle belongs to
  @Index()
  late String pubkey;

  /// Circle unique identifier
  @Index(unique: true)
  late String circleId;

  /// Circle name
  late String name;

  /// Primary relay URL for this circle
  late String relayUrl;

  /// Circle type (relay or bitchat)
  late int typeValue; // Store as int for Isar compatibility

  /// Invitation code for this circle (optional)
  String? invitationCode;

  /// Circle category (custom or paid)
  @enumValue
  late CircleCategory category;

  /// Subscription group id (e.g. loc1) for paid circles owned by this account.
  /// Null for custom circles or when unknown.
  String? groupId;

  CircleISAR({
    required this.pubkey,
    required this.circleId,
    required this.name,
    required this.relayUrl,
    CircleType type = CircleType.relay,
    this.invitationCode,
    this.category = CircleCategory.custom,
    this.groupId,
  }) : typeValue = _typeToInt(type);

  static int _typeToInt(CircleType type) {
    return type == CircleType.bitchat ? 1 : 0;
  }

  static CircleType _intToType(int value) {
    return value == 1 ? CircleType.bitchat : CircleType.relay;
  }

  CircleType get type => _intToType(typeValue);

  set type(CircleType value) {
    typeValue = _typeToInt(value);
  }
}
