import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: EditorPageWidget());
  }
}
