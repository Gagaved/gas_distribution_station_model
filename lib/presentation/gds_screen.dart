import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';

List<PipelineElementWidget> createPipelineElementWidgetsList(
    List<PipelineEdge> list) {
  List<PipelineElementWidget> newList = [];
  for (var element in list) {
    newList.add(PipelineElementWidget(element));
  }
  return newList;
}

class GdsScreenWidget extends StatelessWidget {
  const GdsScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    print("BUILD GOVNO");
    return BlocProvider<GdsBloc>(
        create: (context) => GdsBloc(),
        child: BlocBuilder<GdsBloc, GdsState>(
          builder: (context, state) {
            if (state is GdsInitial) {
              return const CircularProgressIndicator();
            }
            if (state is GdsMainState) {
              var edges = (state).graph.edges;
              var listOfWidgets = edges.entries.map((e) => e.value).toList();
              return Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    context.read<GdsBloc>().add(FloatingButtonPressGdsEvent());
                  },
                ),
                body: Stack(
                    children: createPipelineElementWidgetsList(listOfWidgets)),
              );
            } else {
              return ErrorWidget("unexpected state: ${state}");
            }
          },
        ));
  }
}

class PipelineElementWidget extends StatelessWidget {
  PipelineEdge edge;

  PipelineElementWidget(this.edge, {super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: edge.x,
      top: edge.y,
      child: Container(
        width: 70,
        height: 70,
        color: Colors.black12,
        child: Center(
          child: Column(
            children: [
              Expanded(
                  child: Text(
                "${edge.fromPoint.toString()}-${edge.toPoint.toString()}",
                style: const TextStyle(fontSize: 10),
              )),
              Expanded(
                  child: Text(
                "f: ${edge.flow}",
                style: const TextStyle(fontSize: 10),
              )),
              Expanded(
                  child: Text(
                "pf: ${edge.possibleFlow}",
                style: const TextStyle(fontSize: 10),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
