import 'package:flutter/material.dart';
import 'package:momflex/provider/counter_provider.dart';
import 'package:momflex/theme/app_theme.dart';
import 'package:momflex/views/counter_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const CounterScreen(),
      ),
    );
  }
}