import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/logic/editor_page/editor_bloc.dart';
import 'package:gas_distribution_station_model/models/graph_model.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/pipeline_element.dart';

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
        Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          state.selectedEdge != null
              ? _PipelineInformationCardWidget(
                  edge: state.selectedEdge!,
                )
              : const SizedBox.shrink(),
          const _PipelinePanelWidget()
        ]),
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
        SizedBox(
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                  padding: const EdgeInsets.all(8.0),
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
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<EditorPageBloc>()
                          .add(CalculateFlowButtonPressEvent());
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.science),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Расчитать"),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )),
        state.calculateStatus == CalculateStatus.process
            ? Expanded(
                child: Container(
                  color: Colors.black38,
                  child: const Center(child: CircularProgressIndicator()),
                ),
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
              height: 200,
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
                                height: 300,
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
                        child: Text('Добавить ${state.selectedType}'),
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


class _PipelineInformationCardWidget extends StatelessWidget {
  const _PipelineInformationCardWidget({Key? key, required this.edge})
      : super(key: key);
  final GraphEdge edge;
  static TextEditingController sinkFlowValueTextController =
  TextEditingController();
  static TextEditingController lenValueTextController = TextEditingController();
  static TextEditingController sourcePressureValueTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    sinkFlowValueTextController.text = edge.targetFlow.toString();
    lenValueTextController.text = edge.len.toString();
    sourcePressureValueTextController.text = (edge.pressure/1000000).toString();
    return Card(
      elevation: 10,
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(edge.type.name.toUpperCase()),
            Text("id: ${edge.id}"),
            Text("PtoP: ${edge.p1.id}-${edge.p2.id}"),
            Text("Длина участка: ${edge.len} м"),
            Text("Направление: ${edge.flowDirection?.id}"),
            Text("Flow: ${(edge.flow*3600).toStringAsFixed(2)} м^3 / ч"),
            Text("Давление: ${(edge.pressure / 1000000).toStringAsFixed(4)} МПа"),
            edge.temperature!=null?Text("Тепература: ${(edge.temperature! - 273.15).toStringAsFixed(2)} °C) "):const SizedBox.shrink(),
            Text("Диаметр: ${edge.diam} м"),
            (edge.type == PipelineElementType.valve)
                ? MaterialButton(
              color: edge.openPercentage == 0
                  ? Colors.redAccent
                  : Colors.lightGreen,
              child: Text(
                  edge.openPercentage == 0 ? "Закрыт" : "Открыт"),
              onPressed: () {
                context.read<EditorPageBloc>().add(
                    GdsThroughputFLowPercentageElementChangeEvent(
                        edge, edge.openPercentage == 0 ? 1 : 0));
              },
            )
                : const SizedBox.shrink(),
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: lenValueTextController,
                onChanged: (str) {
                  context.read<EditorPageBloc>().add(
                      GdsLenElementChangeEvent(
                          edge,
                          double.parse(
                              lenValueTextController.value.text)));
                },
                decoration: const InputDecoration(
                  labelText: 'Длина м',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            (edge.type == PipelineElementType.percentageValve)
                ? Text(
                "Открыт на ${(edge.openPercentage * 100).toInt()}%")
                : const SizedBox.shrink(),
            (edge.type == PipelineElementType.percentageValve)
                ? Slider(
              value: edge.openPercentage * 100,
              max: 100,
              divisions: 10,
              label: edge.openPercentage.toString(),
              onChanged: (double value) {
                context.read<EditorPageBloc>().add(
                    GdsThroughputFLowPercentageElementChangeEvent(
                        edge, value / 100));
              },
            )
                : const SizedBox.shrink(),
            (edge.type == PipelineElementType.sink)
                ? Container(
              width: 150,
              padding:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: sinkFlowValueTextController,
                onChanged: (str) {
                  context.read<EditorPageBloc>().add(
                      GdsSinkTargetFLowElementChangeEvent(
                          edge,
                          double.parse(sinkFlowValueTextController
                              .value.text)));
                },
                decoration: const InputDecoration(
                  labelText: 'Расход м^3/c',
                  border: OutlineInputBorder(),
                ),
              ),
            )
                : const SizedBox.shrink(),
            (edge.type == PipelineElementType.source)
                ? Container(
              width: 150,
              padding:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: sourcePressureValueTextController,
                onChanged: (str) {
                  context.read<EditorPageBloc>().add(
                      GdsSourcePressureElementChangeEvent(
                          edge,
                          double.parse(sourcePressureValueTextController
                              .value.text)));
                },
                decoration: const InputDecoration(
                  labelText: 'Давление МПа',
                  border: OutlineInputBorder(),
                ),
              ),
            )
                : const SizedBox.shrink(),
            (edge.type == PipelineElementType.reducer)
                ? Text(
                "Давление на которое\n настроен редуктор: ${edge.targetPressure / 1000000} МПа")
                : const SizedBox.shrink(),
            (edge.type == PipelineElementType.heater)
                ? Slider(
              value: edge.heaterPower!,
              max: 1000,
              min: 100,
              divisions: 10,
              label: "Мощность подогревателя: ${edge.heaterPower} МВт",
              onChanged: (double value) {
                context.read<EditorPageBloc>().add(
                    GdsHeaterPowerElementChangeEvent(
                        edge, value));
              },
            )
                : const SizedBox.shrink(),
            (edge.type == PipelineElementType.reducer)
                ? Slider(
              value: edge.targetPressure / 1000000,
              max: 2,
              min: 1,
              divisions: 10,
              label: "${edge.targetPressure / 1000000}МПа",
              onChanged: (double value) {
                context.read<EditorPageBloc>().add(
                    GdsTargetPressureReducerElementChangeEvent(
                        edge, value * 1000000));
              },
            )
                : const SizedBox.shrink(),
            Padding(
                padding: const EdgeInsets.all(10),
                child: MaterialButton(
                  onPressed: () {
                    context
                        .read<EditorPageBloc>()
                        .add(DeleteElementButtonPressEvent());
                  },
                  color: Colors.red,
                  child: const Text('Удалить'),
                ))
          ],
        ),
      ),
    );
  }
}
