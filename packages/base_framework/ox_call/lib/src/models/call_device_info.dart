class CallDeviceInfo {
  final String deviceId;
  final String label;
  final String kind;

  CallDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.kind,
  });

  @override
  String toString() => 'CallDeviceInfo(id: $deviceId, label: $label, kind: $kind)';
}