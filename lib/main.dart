import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'services/desktop_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(800, 560),
    minimumSize: Size(660, 460),
    center: true,
    backgroundColor: Color(0xFF202124),
    title: 'FastMask',
    windowButtonVisibility: true,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.hide();
  });
  await windowManager.setMinimumSize(const Size(660, 460));

  final preferences = await SharedPreferences.getInstance();
  final controller = AppController(preferences: preferences);
  await controller.initialize();

  final desktopService = DesktopService(controller: controller);
  await desktopService.initialize();

  runApp(FastMaskApp(controller: controller, desktopService: desktopService));
}
