import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/logic/gds_bloc.dart';
import 'package:gas_distribution_station_model/models/GDS_graph_model.dart';
import 'package:gas_distribution_station_model/presentation/gds_element.dart';


List<Widget> createPipelineElementWidgetsList(List<GraphEdge> list) {
  List<Widget> newList = [];
  for (var element in list) {
    newList.add(PipelineSegmentWidget(p1: element.p1!,p2: element.p2!,));
  }
  return newList;
}

class GdsScreenWidget extends StatelessWidget {
  const GdsScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    print("BUILD GOVNO");
    return BlocProvider<GdsPageBloc>(
        create: (context) => GdsPageBloc(),
        child: BlocBuilder<GdsPageBloc, GdsState>(
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
                    context
                        .read<GdsPageBloc>()
                        .add(FloatingButtonPressGdsEvent());
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