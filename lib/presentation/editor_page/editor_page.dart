import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/logic/editor_page/editor_bloc.dart';
import 'package:gas_distribution_station_model/models/graph_model.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;
//import 'package:gas_distribution_station_model/presentation/editor_page/clear_confirmation_popup.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/pipeline_element.dart';
part 'clear_confirmation_popup.dart';
part 'pipeline_element.dart';
part 'pipeline_information_card.dart';

class EditorPageWidget extends StatelessWidget {
  const EditorPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditorPageBloc>(
        create: (context) => EditorPageBloc(),
        child: BlocBuilder<EditorPageBloc, GdsState>(
          builder: (context, state) {
            if (state is EditorInitialState) {
              return const CircularProgressIndicator();
            }
            if (state is EditorLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EditorMainState) {
              return Scaffold(
                  body: Row(
                children: [
                  ///
                  ///
                  /// Панель иструментов редактора
                  _EditorToolsWidget(state: state),
                  ///
                  ///
                  /// Рабочее поле редактора на котором отображается элементы редактора
                  _PipelinePlanWidget(
                    state: state,
                  ),
                ],
              ));
            } else {
              return ErrorWidget("unexpected state: $state");
            }
          },
        ));
  }
}

class _EditorToolsWidget extends StatelessWidget {
  final EditorMainState state;

  const _EditorToolsWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 200,
          height: double.maxFinite,
          child: ListView(
              shrinkWrap: true,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<EditorPageBloc>().add(ExportGdsToFileEvent());
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
                          context.read<EditorPageBloc>().add(LoadFromFileEvent());
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
                            context
                                .read<EditorPageBloc>()
                                .add(ClearButtonPressEditorEvent());
                            try {
                            } catch (_) {}
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
            state.selectedEdge != null
                ? PipelineInformationCardWidget(
                    edge: state.selectedEdge!,
                  )
                : const SizedBox.shrink(),
            const _PipelinePanelWidget()
          ]),
        ),
      ],
    );
  }
}

class _PipelinePlanWidget extends StatelessWidget {
  final EditorMainState state;

  static final TransformationController _transformationController =
      TransformationController();

  const _PipelinePlanWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    var listOfElements = <Widget>[];
    listOfElements.add(Container(
      color: Colors.black12,
    ));
    var edgesMap = (state).graph.edges;
    for (GraphEdge edge in edgesMap.values) {
      if (edge != state.selectedEdge) {
        listOfElements.add(_getWidgetFromEdge(edge, isSelect: false));
      }
    }
    if (state.selectedEdge != null) {
      listOfElements
          .add(_getWidgetFromEdge(state.selectedEdge!, isSelect: true));
    }
    return Expanded(
      child: Stack(alignment: AlignmentDirectional.bottomEnd, children: [
        InteractiveViewer(
          maxScale: 2.5,
          minScale: 0.5,
          transformationController: _transformationController,
          child: Stack(children: listOfElements),
        ),
        state.calculateStatus == CalculateStatus.process
            ? Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            )
            : const SizedBox.shrink()
      ]),
    );
  }
}

Widget _getWidgetFromEdge(GraphEdge edge, {required bool isSelect}) {
  switch (edge.type) {
    case PipelineElementType.valve:
      return PipelineValveWidget(edge: edge, isSelect: isSelect);
    case PipelineElementType.segment:
      return PipelineSegmentWidget(edge: edge, isSelect: isSelect);
    case PipelineElementType.percentageValve:
      return PipelinePercentageValveWidget(
        edge: edge,
        isSelect: isSelect,
      );
    case PipelineElementType.heater:
      return PipelineHeaterWidget(edge: edge, isSelect: isSelect);
    case PipelineElementType.reducer:
      return PipelineReducerWidget(edge: edge, isSelect: isSelect);
    case PipelineElementType.meter:
      return PipelineMeterWidget(edge: edge, isSelect: isSelect);
    case PipelineElementType.filter:
      return PipelineFilterWidget(edge: edge, isSelect: isSelect);
    default:
      return PipelineSegmentWidget(edge: edge, isSelect: isSelect);
  }
}

class _PipelinePanelWidget extends StatelessWidget {
  const _PipelinePanelWidget({Key? key}) : super(key: key);
  static final TextEditingController _flowFieldController =
      TextEditingController();
  static final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorPageBloc, GdsState>(
      builder: (context, state) {
        if (state is EditorMainState) {
          if (state.selectedEdge != null) {
            _flowFieldController.text = state.selectedEdge!.diam.toString();
          }
          var edgeTypes = PipelineElementType.values;
          return Card(
            elevation: 10,
            child: SizedBox(
              width: 200,
              height: 170,
              child: Column(
                children: [
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: edgeTypes.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (BuildContext con, int index) {
                          return GestureDetector(
                              onTap: () {
                                context.read<EditorPageBloc>().add(
                                    ChangeSelectedTypeInPanelEditorEvent(
                                        edgeTypes[index]));
                              },
                              child: Container(
                                height: 200,
                                padding: const EdgeInsets.all(5.0),
                                child: Card(
                                  elevation: 5,
                                  color: state.selectedType == edgeTypes[index]
                                      ? Theme.of(context).primaryColor
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Center(
                                        child: Text(
                                      edgeTypes[index].name,
                                      style: TextStyle(
                                        color: state.selectedType ==
                                                edgeTypes[index]
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                    )),
                                  ),
                                ),
                              ));
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
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<EditorPageBloc>().add(
                              AddElementButtonPressEditorEvent(
                                  double.parse(_flowFieldController.text)));
                        },
                        child: Text('Добавить ${state.selectedType.name}'),
                      ))
                  //const TextField(),
                  //const TextField(),
                ],
              ),
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}