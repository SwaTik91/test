import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'iap/store_billing_port.dart';
import 'save/cloud_save_port.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final cloud = resolveCloudSavePort();
  final storeTarget = resolveStoreTarget();

  runApp(MidgardApp(cloud: cloud, storeTarget: storeTarget));
}
