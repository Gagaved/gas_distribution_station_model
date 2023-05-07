import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/presentation/gds_element.dart';

List<Widget> createPipelineElementWidgetsList(List<GraphEdge> list) {
  List<Widget> newList = [];
  for (var edge in list) {
    newList.add(PipelineSegmentWidget(edge: edge, isSelect: false));
  }
  return newList;
}

class GdsScreenWidget extends StatelessWidget {
  const GdsScreenWidget({super.key});

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
            if (state is GdsMainState) {
              var edgesMap = (state).graph.edges;
              for (GraphEdge edge in edgesMap.values) {
                if (edge != state.selectedEdge) {
                  listOfElements
                      .add(PipelineSegmentWidget(edge: edge, isSelect: false));
                }
              }
              if (state.selectedEdge != null) {
                listOfElements
                    .add(PipelineSegmentWidget(edge: state.selectedEdge!, isSelect: true));
              }
              return Scaffold(
                  floatingActionButton: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        child: const Icon(Icons.calculate),
                        onPressed: () {
                          context
                              .read<GdsPageBloc>()
                              .add(CalculateFlowButtonPressGdsEvent());
                        },
                      )
                    ],
                  ),
                  body: Stack(children: [
                    const PipelineParamsWidget(),
                    Stack(children: listOfElements),
                  ]));
            } else {
              return ErrorWidget("unexpected state: ${state}");
            }
          },
        ));
  }
}

class PipelineParamsWidget extends StatelessWidget {
  const PipelineParamsWidget({Key? key}) : super(key: key);
  static TextEditingController flowFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GdsPageBloc, GdsState>(
      builder: (context, state) {
        if (state is GdsMainState) {
          if (state.selectedEdge != null) {
            flowFieldController.text =
                state.selectedEdge!.throughputFlow.toString();
          } else {
            flowFieldController.text = '';
          }
        }
        return Positioned(
          left: 5,
          bottom: 5,
          child: Card(
            elevation: 5,
            child: SizedBox(
              width: 150,
              child: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: flowFieldController,
                    decoration: const InputDecoration(
                      labelText: 'макс. поток',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: MaterialButton(
                        onPressed: () {
                          context.read<GdsPageBloc>().add(
                              AddEdgeButtonPressGdsEvent(
                                  double.parse(flowFieldController.text)));
                        },
                        child: Text('Добавить ребро'),
                        color: Colors.blue,
                      ))

                  //const TextField(),
                  //const TextField(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
