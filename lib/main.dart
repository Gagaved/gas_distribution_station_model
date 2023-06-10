import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/data/database/database.dart';
import 'package:gas_distribution_station_model/presentation/main_screen/main_screen.dart';
import 'package:json_theme/json_theme.dart';

import 'logic/gds_bloc.dart';
import 'presentation/gds_screen.dart';
import 'globals.dart' as globals;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
  final themeJson = jsonDecode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJson)!;

  WidgetsFlutterBinding.ensureInitialized();
  globals.database = await $FloorAppDatabase.databaseBuilder('edmt1 database.db').build();


  runApp(App(theme: theme));
}

class App extends StatelessWidget {
  final ThemeData theme;

  const App({super.key, required this.theme});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: const HomePage()
    );
  }
}

