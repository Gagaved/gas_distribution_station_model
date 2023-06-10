import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/models/gds_element_type.dart';
import 'package:gas_distribution_station_model/presentation/gds_element.dart';

class GdsScreenWidget extends StatelessWidget {
  const GdsScreenWidget({super.key});

  static final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GdsPageBloc>(
        create: (context) => GdsPageBloc(),
        child: BlocBuilder<GdsPageBloc, GdsState>(
          builder: (context, state) {
            var listOfElements = <Widget>[];
            if (state is GdsInitial) {
              return const CircularProgressIndicator();
            }
            if(state is GdsLoadedState){
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GdsMainState) {
              var edgesMap = (state).graph.edges;
              for (GraphEdge edge in edgesMap.values) {
                if (edge != state.selectedEdge) {
                  listOfElements.add(getWidgetFromEdge(edge, isSelect: false));
                }
              }
              if (state.selectedEdge != null) {
                listOfElements.add(
                    getWidgetFromEdge(state.selectedEdge!, isSelect: true));
                // listOfElements.add(PipelineInformationCardWidget(
                //   edge: state.selectedEdge!,
                // ));
              }
              // _transformationController =
              //     TransformationController(_transformationController.value);
              // _transformationController.addListener(() {
              //   context
              //       .read<GdsPageBloc>()
              //       .add(ScaleChangeEvent());
              // });
              return Scaffold(
                  body: Row(
                children: [
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    state.selectedEdge != null
                        ? PipelineInformationCardWidget(
                            edge: state.selectedEdge!,
                          )
                        : const SizedBox.shrink(),
                    const PipelinePanelWidget()
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      maxScale: 2.5,
                      minScale: 0.5,
                      transformationController: _transformationController,
                      child: Stack(children: listOfElements),
                    ),
                  ),
                  Column(
                    mainAxisAlignment:MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                context
                                    .read<GdsPageBloc>()
                                    .add(SaveGdsEvent());
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.save),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("Cохранить систему"),
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
                                    .read<GdsPageBloc>()
                                    .add(LoadGdsEvent());
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.sim_card_download),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("загрузить систему"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            context
                                .read<GdsPageBloc>()
                                .add(CalculateFlowButtonPressGdsEvent());
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.science),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Расчитать систему"),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ));
            } else {
              return ErrorWidget("unexpected state: ${state}");
            }
          },
        ));
  }
}

Widget getWidgetFromEdge(GraphEdge edge, {required bool isSelect}) {
  switch (edge.type) {
    case GdsElementType.valve:
      return PipelineValveWidget(edge: edge, isSelect: isSelect);
    case GdsElementType.segment:
      return PipelineSegmentWidget(edge: edge, isSelect: isSelect);
    case GdsElementType.percentageValve:
      return PipelinePercentageValveWidget(
        edge: edge,
        isSelect: isSelect,
      );
    case GdsElementType.heater:
      return PipelineHeaterWidget(edge: edge, isSelect: isSelect);
    case GdsElementType.reducer:
      return PipelineReducerWidget(edge: edge, isSelect: isSelect);
    case GdsElementType.meter:
      return PipelineMeterWidget(edge: edge, isSelect: isSelect);
    default:
      return PipelineSegmentWidget(edge: edge, isSelect: isSelect);
  }
}

class PipelinePanelWidget extends StatelessWidget {
  const PipelinePanelWidget({Key? key}) : super(key: key);
  static final TextEditingController _flowFieldController =
      TextEditingController();
  static final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GdsPageBloc, GdsState>(
      builder: (context, state) {
        if (state is GdsMainState) {
          if (state.selectedEdge != null) {
            _flowFieldController.text = state.selectedEdge!.diam.toString();
          }
          var edgeTypes = GdsElementType.values;
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
                                context.read<GdsPageBloc>().add(
                                    ChangeSelectedTypeInPanelEvent(
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
                  state.selectedEdge == null
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<GdsPageBloc>().add(
                                  AddElementButtonPressGdsEvent(
                                      double.parse(_flowFieldController.text)));
                            },
                            child: Text('Добавить ${state.selectedType}'),
                          ))
                      : const SizedBox.shrink(),
                  state.selectedEdge != null
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: MaterialButton(
                            onPressed: () {
                              context
                                  .read<GdsPageBloc>()
                                  .add(DeleteElementButtonPressGdsEvent());
                            },
                            child: const Text('Удалить'),
                            color: Colors.red,
                          ))
                      : const SizedBox.shrink(),

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
