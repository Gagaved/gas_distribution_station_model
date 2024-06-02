import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/gas_network.dart';
import '../grapth_visualisator/grapth_visualisator.dart';
import 'tools/on_cursor_tool_painter.dart';

part 'pipeline_element.dart';
part 'pipeline_information_card.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/clear_confirmation_popup.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/pipeline_element.dart';
part 'tools/clear_confirmation_popup.dart';

class EditorPageWidget extends StatelessWidget {
  const EditorPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
        create: (context) => EditorStateStore()..init(),
        child: const Scaffold(
            body: Row(
          children: [
            /// Панель иструментов редактора
            _EditorToolsWidget(),

            /// Рабочее поле редактора на котором отображается элементы редактора
            _PipelinePlanWidget(),
          ],
        )));
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
                  child: ElevatedButton(
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
                  child: ElevatedButton(
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
                  child: ElevatedButton(
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
            const PipelineInformationCardWidget(),
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
  final focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    var listOfElements = <Widget>[];

    // List<Edge>? sortedEdges = stateStore.graph.edges;
    // sortedEdges.sort((a, b) {
    //   if (a == selectedEdge) {
    //     return 1; // перемещаем выбранное ребро в конец списка
    //   } else if (b == selectedEdge) {
    //     return -1; // перемещаем выбранное ребро в конец списка
    //   }
    //   return 0; // остальные ребра остаются на месте
    // });
    {
      for (Edge edge in stateStore.edges) {
        bool isSelect = stateStore.selectedElementIds.lookup(edge.id) != null;
        switch (edge.type) {
          case PipelineEdgeType.valve:
            listOfElements
                .add(PipelineValveWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.segment:
            listOfElements
                .add(PipelineSegmentWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.percentageValve:
            listOfElements.add(
                PipelinePercentageValveWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.heater:
            listOfElements
                .add(PipelineHeaterWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.reducer:
            listOfElements
                .add(PipelineReducerWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.meter:
            listOfElements
                .add(PipelineMeterWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.filter:
            listOfElements
                .add(PipelineFilterWidget(edge: edge, isSelect: isSelect));
            break;
          case PipelineEdgeType.adorizer:
            listOfElements
                .add(PipelineAdorizerWidget(edge: edge, isSelect: isSelect));
            break;
          default:
            listOfElements
                .add(PipelineSegmentWidget(edge: edge, isSelect: isSelect));
            break;
        }
      }
      for (Node node in stateStore.nodes) {
        bool isSelect = stateStore.selectedElementIds.lookup(node.id) != null;
        listOfElements.add(PipelineWidget.node(
          node: node,
          isSelect: isSelect,
        ));
      }
    }

    return Expanded(
        child: KeyboardListener(
      autofocus: true,
      onKeyEvent: (KeyEvent keyEvent) {
        if (LogicalKeyboardKey.escape == keyEvent.logicalKey) {
          stateStore.deselectElements();
        }
        print(keyEvent);
      },
      focusNode: focusNode,
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
        child: OnCursorSelectedToolPainter(
          child: InfiniteSurface(
            transformationController: transformationController,
            children: listOfElements,
          ),
        ),
      ),
    ));
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Scrollbar(
          controller: _scrollController,
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: toolTypes.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext con, int index) {
                return GestureDetector(onTap: () {
                  EditorState.of(context)
                      .changeSelectedToolType(toolTypes[index]);
                }, child: Observer(builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(5.0),
                    child: Card(
                      elevation: 5,
                      color: stateStore.selectedTool == toolTypes[index]
                          ? Theme.of(context).primaryColor
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Center(
                          child: Text(
                            toolTypes[index].name,
                            style: TextStyle(
                              color: stateStore.selectedTool == toolTypes[index]
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }));
              },
            ),
          ),
        ),
        TextField(
          keyboardType: TextInputType.number,
          controller: _flowFieldController,
          decoration: const InputDecoration(
            labelText: 'Диаметр, м',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
