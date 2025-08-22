import 'package:flutter/material.dart';
import 'pages/input_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twite Stock Analyzer ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExcelInputPage(),
    );
  }
}
