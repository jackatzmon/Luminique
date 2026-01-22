import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import '../providers/app_state_provider.dart';

class LuminiqueApp extends StatelessWidget {
  const LuminiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'Luminique - DJ Photo Stream',
          debugShowCheckedModeBanner: false,
          theme: LuminiqueTheme.lightTheme,
          darkTheme: LuminiqueTheme.darkTheme,
          themeMode: appState.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
