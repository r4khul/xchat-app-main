import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:ox_module_service/ox_module_service.dart';
import 'package:ox_call/src/models/iceserver_db_isar.dart';
import 'package:ox_call/src/utils/call_integration_helper.dart';

class OXCall extends OXFlutterModule {
  @override
  String get moduleName => 'ox_call';

  @override
  bool get useTheme => false;

  @override
  bool get useLocalized => false;

  @override
  List<IsarGeneratedSchema> get isarDBSchemes => [
    ICEServerDBISARSchema,
  ];

  @override
  Future<void> setup() async {
    await super.setup();
    // Register CallIntegrationHelper as LoginManager observer
    CallIntegrationHelper.instance.register();
  }

  @override
  Future<T?>? navigateToPage<T>(BuildContext context, String pageName, Map<String, dynamic>? params) {
    return null;
  }
}