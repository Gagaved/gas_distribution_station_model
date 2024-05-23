import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;
import 'package:gas_distribution_station_model/logic/viewer_page/viewer_page_bloc.dart';
import 'package:gas_distribution_station_model/models/graph_model.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/presentation/grapth_visualisator/grapth_visualisator.dart';

part 'pipeline_element.dart';
part 'pipeline_information_card.dart';

class ViewerPageWidget extends StatelessWidget {
  const ViewerPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ViewerPageBloc>(
        create: (context) => ViewerPageBloc(),
        child: BlocBuilder<ViewerPageBloc, ViewerPageState>(
          builder: (context, state) {
            if (state is ViewerPageInitial) {
              return const CircularProgressIndicator();
            }
            if (state is ViewerPageLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ViewerMainState) {
              return Scaffold(
                  body: Row(
                children: [
                  ///
                  ///
                  /// Панель иструментов редактора
                  _ToolsWidget(state: state),

                  ///
                  ///
                  /// Рабочее поле просмотрщика на котором отображается элементы редактора
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

class _ToolsWidget extends StatelessWidget {
  final ViewerMainState state;

  const _ToolsWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: double.maxFinite,
          width: 200,
          child: ListView(shrinkWrap: true, children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<ViewerPageBloc>()
                          .add(CalculateFlowButtonPressViewerEvent());
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.science),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Расчитать"),
                        ),
                      ],
                    ))),
            state.selectedEdge != null
                ? PipelineInformationCardWidget(
                    edge: state.selectedEdge!,
                  )
                : Card(
                    child: Container(
                        height: 200,
                        width: 200,
                        child: Center(
                          child: Text(
                            "Выберите элемент для взаимодействия или нажнмите кнопку Расчитать",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        )),
                  ),
          ]),
        ),
      ],
    );
  }
}

class _PipelinePlanWidget extends StatelessWidget {
  final ViewerMainState state;

  static final TransformationController _transformationController =
      TransformationController();

  const _PipelinePlanWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    var listOfElements = <Widget>[];
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
      child: InfiniteSurface(children: listOfElements),
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
    case PipelineElementType.adorizer:
      return PipelineAdorizerWidget(edge: edge, isSelect: isSelect);
    default:
      return PipelineSegmentWidget(edge: edge, isSelect: isSelect);
  }
}
