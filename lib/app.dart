import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/app_controller.dart';
import 'pages/home_page.dart';
import 'services/desktop_service.dart';
import 'theme/app_theme.dart';

class FastMaskApp extends StatelessWidget {
  const FastMaskApp({
    required this.controller,
    required this.desktopService,
    super.key,
  });

  final AppController controller;
  final DesktopService desktopService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastMask',
      debugShowCheckedModeBanner: false,
      theme: buildFastMaskTheme(),
      home: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape):
              desktopService.hideWindow,
          const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
              desktopService.hideWindow,
          const SingleActivator(LogicalKeyboardKey.keyW, control: true):
              desktopService.hideWindow,
        },
        child: Focus(
          autofocus: true,
          child: HomePage(
            controller: controller,
            desktopService: desktopService,
          ),
        ),
      ),
    );
  }
}
