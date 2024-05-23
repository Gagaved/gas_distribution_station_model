import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/presentation/main_screen/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  //globals.database = await $FloorAppDatabase.databaseBuilder('edmt1 database.db').build();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({
    super.key,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: HomePage());
  }
}
