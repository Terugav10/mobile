import 'package:flutter/material.dart';
import 'aprender.dart';
import 'route_observer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Aprender(),
      navigatorObservers: [routeObserver],
    );
  }
}
