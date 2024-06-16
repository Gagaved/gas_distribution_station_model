import 'package:flutter/material.dart';

import '../editor_page.dart';
import '../editor_state_mobx.dart';
import 'tools_state_mobx.dart';

class SideToolsMenuWidget extends StatelessWidget {
  const SideToolsMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 200,
          child: ListView(children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: MaterialButton(
                    onPressed: () {
                      EditorState.of(context).exportToFile();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.save),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Экпорт"),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: MaterialButton(
                    onPressed: () {
                      EditorState.of(context).loadFromFile();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.upload_file_sharp),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Импорт"),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: MaterialButton(
                    onPressed: () async {
                      bool? wasDelete = await showDialog<bool>(
                          context: context,
                          builder: (_) {
                            return const ClearConfirmationPopup();
                          });
                      print("was delete:$wasDelete");
                      if (wasDelete != null && wasDelete) {
                        EditorState.of(context).clear();
                        try {} catch (_) {}
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.delete_forever),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Очистить"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: MaterialButton(
                onPressed: () {
                  ToolsState.of(context).calculationToolVisible =
                      !ToolsState.of(context).calculationToolVisible;
                },
                child: const Row(
                  children: [
                    Icon(Icons.calculate),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Расчет"),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
