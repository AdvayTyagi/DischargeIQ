import 'package:flutter/material.dart';
import 'core/router.dart';

void main() {
  runApp(const DischargeIQApp());
}

class DischargeIQApp extends StatelessWidget {
  const DischargeIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DischargeIQ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}