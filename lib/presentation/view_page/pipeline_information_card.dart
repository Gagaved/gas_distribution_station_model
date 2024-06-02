// part of 'viewer_page.dart';
//
// class PipelineInformationCardWidget extends StatelessWidget {
//   const PipelineInformationCardWidget({Key? key, required this.edge})
//       : super(key: key);
//   final GraphEdge edge;
//   static TextEditingController sinkFlowValueTextController =
//   TextEditingController();
//   static TextEditingController lenValueTextController = TextEditingController();
//   static TextEditingController sourcePressureValueTextController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     sinkFlowValueTextController.text = (edge.targetFlow*3600).toString();
//     lenValueTextController.text = edge.len.toString();
//     sourcePressureValueTextController.text = (edge.pressure/1000000).toString();
//     return Card(
//       elevation: 10,
//       child: SizedBox(
//         width: 200,
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(edge.type.name.toUpperCase(),style: Theme.of(context)
//             .textTheme
//             .headlineSmall
//             ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
//     ),
//               Text("id: ${edge.id}"),
//               Text("PtoP: ${edge.p1.id}-${edge.p2.id}"),
//               Text("Длина участка: ${edge.len} м"),
//               //Text("Направление: ${edge.flowDirection?.id}"),
//               Text("Flow: ${(edge.flow*3600).toStringAsFixed(2)} м^3 / ч"),
//               Text("Давление: ${(edge.pressure / 1000000).toStringAsFixed(4)} МПа"),
//               edge.temperature!=null?Text("Тепература: ${(edge.temperature! - 273.15).toStringAsFixed(2)} °C) "):const SizedBox.shrink(),
//               Text("Диаметр: ${edge.diam} м"),
//               (edge.type == PipelineElementType.valve)
//                   ? MaterialButton(
//                 color: edge.openPercentage == 0
//                     ? Colors.redAccent
//                     : Colors.lightGreen,
//                 child: Text(
//                     edge.openPercentage == 0 ? "Закрыт" : "Открыт"),
//                 onPressed: () {
//                   context.read<ViewerPageBloc>().add(
//                       ThroughputFLowPercentageElementChangeViewerEvent(
//                           edge, edge.openPercentage == 0 ? 1 : 0));
//                 },
//               )
//                   : const SizedBox.shrink(),
//               // Container(
//               //   width: 150,
//               //   padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//               //   child: TextField(
//               //     keyboardType: TextInputType.number,
//               //     controller: lenValueTextController,
//               //     onChanged: (str) {
//               //       context.read<ViewerPageBloc>().add(
//               //           LenElementChangeViewerEvent(
//               //               edge,
//               //               double.parse(
//               //                   lenValueTextController.value.text)));
//               //     },
//               //     decoration: const InputDecoration(
//               //       labelText: 'Длина м',
//               //       border: OutlineInputBorder(),
//               //     ),
//               //   ),
//               // ),
//               (edge.type == PipelineElementType.percentageValve)
//                   ? Text(
//                   "Открыт на ${(edge.openPercentage * 100).toInt()}%")
//                   : const SizedBox.shrink(),
//               (edge.type == PipelineElementType.percentageValve)
//                   ? Slider(
//                 value: edge.openPercentage * 100,
//                 max: 100,
//                 divisions: 10,
//                 label: edge.openPercentage.toString(),
//                 onChanged: (double value) {
//                   context.read<ViewerPageBloc>().add(
//                       ThroughputFLowPercentageElementChangeViewerEvent(
//                           edge, value / 100));
//                 },
//               )
//                   : const SizedBox.shrink(),
//               (edge.type == PipelineElementType.sink)
//                   ? Container(
//                 width: 150,
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//                 child: TextField(
//                   keyboardType: TextInputType.number,
//                   controller: sinkFlowValueTextController,
//                   onChanged: (str) {
//                     context.read<ViewerPageBloc>().add(
//                         SinkTargetFLowElementChangeViewerEvent(
//                             edge,
//                             double.parse(sinkFlowValueTextController
//                                 .value.text)/3600));
//                   },
//                   decoration: const InputDecoration(
//                     labelText: 'Расход м^3/c',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               )
//                   : const SizedBox.shrink(),
//               (edge.type == PipelineElementType.source)
//                   ? Container(
//                 width: 150,
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//                 child: TextField(
//                   keyboardType: TextInputType.number,
//                   controller: sourcePressureValueTextController,
//                   onChanged: (str) {
//                     context.read<ViewerPageBloc>().add(
//                         SourcePressureElementChangeViewerEvent(
//                             edge,
//                             double.parse(sourcePressureValueTextController
//                                 .value.text)));
//                   },
//                   decoration: const InputDecoration(
//                     labelText: 'Давление МПа',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               )
//                   : const SizedBox.shrink(),
//               (edge.type == PipelineElementType.reducer)
//                   ? Text(
//                   "Выходное давление: ${edge.targetPressure / 1000000} МПа")
//                   : const SizedBox.shrink(),
//               (edge.type == PipelineElementType.heater)
//                   ?Text("Мощность подогр. ${edge.heaterPower}"):SizedBox.shrink(),
//               (edge.type == PipelineElementType.heater)
//                   ? Slider(
//                 value: edge.heaterPower!,
//                 max: 600,
//                 min: 0,
//                 divisions: 10,
//                 label: "Мощность подогревателя: ${edge.heaterPower} КВт",
//                 onChanged: (double value) {
//                   context.read<ViewerPageBloc>().add(
//                       GdsHeaterPowerElementChangeViewerEvent(
//                           edge, value));
//                 },
//               )
//                   : const SizedBox.shrink(),
//               (edge.type == PipelineElementType.reducer)
//                   ? Slider(
//                 value: edge.targetPressure / 1000000,
//                 max: 2,
//                 min: 1,
//                 divisions: 10,
//                 label: "${edge.targetPressure / 1000000}МПа",
//                 onChanged: (double value) {
//                   context.read<ViewerPageBloc>().add(
//                       TargetPressureReducerElementChangeViewerEvent(
//                           edge, value * 1000000));
//                 },
//               )
//                   : const SizedBox.shrink(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
