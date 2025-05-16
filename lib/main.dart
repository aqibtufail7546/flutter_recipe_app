import 'dart:ui';

import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:flutter_food_recipe_api/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Recipe App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF85C50),
        fontFamily: 'Poppins',
      ),
      home: const OnboardingScreen(),
    );
  }
}
