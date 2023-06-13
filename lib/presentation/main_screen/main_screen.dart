import 'package:flutter/material.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
      children: [
        SideMenu(
          builder: (data) => SideMenuData(
            header: const Text(''),
            items: [
              SideMenuItemDataTile(
                isSelected: true,
                onTap: () {},
                title: 'Редактирование',
                icon: const Icon(Icons.account_tree),
              ),
            ],
            footer: const Text(''),
          ),
        ),
        const Expanded(
          child: EditorPageWidget()
        ),
      ],
    ));
  }
}
