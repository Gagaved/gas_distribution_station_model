import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: MaterialButton(
                    onPressed: () {
                      ToolsState.of(context).calculationToolVisible =
                          !ToolsState.of(context).calculationToolVisible;
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
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
              ],
            ),
            const _PipelinePanelWidget()
          ]),
        ),
        Container(
          width: 1,
          color: Colors.black12,
        )
      ],
    );
  }
}

class _PipelinePanelWidget extends StatelessWidget {
  const _PipelinePanelWidget({Key? key}) : super(key: key);
  static final TextEditingController _flowFieldController =
      TextEditingController();
  static final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    const toolTypes = ToolType.values;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...toolTypes.map(
          (tool) {
            return Expanded(
              child: GestureDetector(onTap: () {
                EditorState.of(context).changeSelectedToolType(tool);
              }, child: Observer(builder: (context) {
                return Container(
                  padding: const EdgeInsets.all(5.0),
                  height: 60,
                  child: Card(
                    elevation: 5,
                    color: stateStore.selectedTool == tool
                        ? Theme.of(context).primaryColor
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Center(
                        child: Text(
                          tool.value,
                          style: TextStyle(
                            color: stateStore.selectedTool == tool
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })),
            );
          },
        ),
      ],
    );
  }
}
