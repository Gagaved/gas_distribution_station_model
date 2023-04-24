import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'logic/gds_bloc.dart';
import 'presentation/gds_screen.dart';

void main() {
  //WidgetsFlutterBinding.ensureInitialized();

  //final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
  //final themeJson = jsonDecode(themeStr);
  //final theme = ThemeDecoder.decodeThemeData(themeJson)!;
  var theme = ThemeData();
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
      home: const GdsScreenWidget()
    );
  }
}

