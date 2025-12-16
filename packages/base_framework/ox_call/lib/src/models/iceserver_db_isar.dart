import 'package:isar/isar.dart';

part 'iceserver_db_isar.g.dart';

/// ICE server record stored per circle.
@collection
class ICEServerDBISAR {
  int id = 0;

  /// Circle ID this record belongs to.
  @Index()
  late String circleId;

  /// ICE server URL (e.g., 'stun:stun.l.google.com:19302' or 'turn:turn.example.com:3478')
  late String url;

  /// Username for TURN authentication (optional).
  String? username;

  /// Credential for TURN authentication (optional).
  String? credential;

  ICEServerDBISAR({
    required this.circleId,
    required this.url,
    this.username,
    this.credential,
  });
}