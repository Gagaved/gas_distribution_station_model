import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';
import 'package:provider/provider.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import '../../models/gas_network.dart';
import '../grapth_visualisator/grapth_visualisator.dart';
import 'tools/calculation_tool.dart';
import 'tools/mouse_region_mobx.dart';
import 'tools/on_cursor_tool_painter_mobx.dart';
import 'tools/selected_element_panel.dart';

part 'pipeline_element.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/clear_confirmation_popup.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/pipeline_element.dart';
part 'tools/clear_confirmation_popup.dart';

class EditorPageWidget extends StatelessWidget {
  const EditorPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
        create: (context) => EditorStateStore()..init(),
        child: const FocusScope(
          child: _KeyboardHandler(
            child: Row(
              children: [
                /// Панель иструментов редактора
                _EditorToolsWidget(),

                /// Рабочее поле редактора на котором отображается элементы редактора
                _PipelinePlanWidget(),
              ],
            ),
          ),
        ));
  }
}

class _KeyboardHandler extends StatefulWidget {
  const _KeyboardHandler({super.key, required this.child});
  final Widget child;

  @override
  State<_KeyboardHandler> createState() => _KeyboardHandlerState();
}

class _KeyboardHandlerState extends State<_KeyboardHandler> {
  final focusNode = FocusNode();
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent keyEvent) {
        if (LogicalKeyboardKey.escape == keyEvent.logicalKey) {
          stateStore.deselectElements();
        }
        print(keyEvent);
      },
      child: widget.child,
    );
  }
}

class _EditorToolsWidget extends StatelessWidget {
  const _EditorToolsWidget();

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
            const _PipelinePanelWidget()
          ]),
        ),
      ],
    );
  }
}

class _PipelinePlanWidget extends StatefulObserverWidget {
  const _PipelinePlanWidget();

  @override
  State<_PipelinePlanWidget> createState() => _PipelinePlanWidgetState();
}

class _PipelinePlanWidgetState extends State<_PipelinePlanWidget> {
  final TransformationController transformationController =
      TransformationController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    var listOfElements = <Widget>[];
    {
      for (Edge edge in stateStore.edges) {
        bool isSelect = stateStore.selectedElementIds.lookup(edge.id) != null;
        listOfElements.add(PipelineWidget.edge(edge: edge, isSelect: isSelect));
      }
      for (Node node in stateStore.nodes) {
        bool isSelect = stateStore.selectedElementIds.lookup(node.id) != null;
        listOfElements.add(PipelineWidget.node(
          node: node,
          isSelect: isSelect,
        ));
      }
      listOfElements.add(const EdgeDraftProjector());

      // listOfElements.insert(
      //   0,
      //   Positioned(
      //     height: 1600,
      //     width: 2400,
      //     child: FittedBox(
      //       fit: BoxFit.fill,
      //       child: Image.asset(
      //         'assets/GRS.png',
      //       ),
      //     ),
      //   ),
      // );
      return Expanded(
          child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (stateStore.selectedTool != null) {
            stateStore.createElement(
              transformationController.toScene(details.localPosition),
            );
          }
        },
        onSecondaryTapDown: (TapDownDetails details) {
          stateStore.deselectElements();
        },
        child: MouserRegionProvider(
          transformationController: transformationController,
          child: OnCursorSelectedToolPainter(
            child: Stack(
              children: [
                InfiniteSurface(
                  transformationController: transformationController,
                  children: listOfElements,
                ),
                const SelectedElementPanel(),
                const CalculationTool(),
              ],
            ),
          ),
        ),
      ));
    }
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
        )
      ],
    );
  }
}
