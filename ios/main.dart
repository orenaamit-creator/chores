// main.dart

import 'package:flutter/material.dart';
import 'pages/chores_home_page.dart';

void main() {
  runApp(const ChoresApp());
}

class ChoresApp extends StatelessWidget {
  const ChoresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Set the app title in Hebrew
      title: 'אפליקציית מטלות',
      // Define a clean, Google-style theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const ChoresHomePage(),
    );
  }
}
