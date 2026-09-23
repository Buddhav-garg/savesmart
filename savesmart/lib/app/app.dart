import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class SaveSmartApp extends StatelessWidget {
  const SaveSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaveSmart',
      theme: SaveSmartTheme.light,
      routerConfig: appRouter,
    );
  }
}
