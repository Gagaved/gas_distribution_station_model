part of 'editor_page.dart';

class PipelineInformationCardWidget extends StatelessObserverWidget {
  const PipelineInformationCardWidget({
    Key? key,
  }) : super(key: key);
  static TextEditingController sinkFlowValueTextController =
      TextEditingController();
  static TextEditingController lenValueTextController = TextEditingController();
  static TextEditingController diamValueTextController =
      TextEditingController();
  static TextEditingController sourcePressureValueTextController =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    // sinkFlowValueTextController.text = (edge.targetFlow*3600).toString();
    // diamValueTextController.text = edge.diam.toString();
    // lenValueTextController.text = edge.len.toString();
    // sourcePressureValueTextController.text = (edge.pressure/1000000).toString();
    final stateStore = EditorState.of(context);
    //todo fix first
    final Edge? edge =
        stateStore.selectedElementIds.whereType<Edge>().firstOrNull;
    if (edge == null) return const SizedBox.shrink();
    return Card(
      elevation: 10,
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              edge.type.name.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            //Text("id: ${edge.id}"),
            Text("PtoP: ${edge.startNodeId}-${edge.endNodeId}"),
            //todo fix first
            //Text("Длина участка: ${edge.len} м"),
            // // Text("Направление: ${edge.flowDirection?.id}"),
            Text("Flow: ${(edge.flow * 3600).toStringAsFixed(2)} м^3 / ч"),
            //Text("Давление: ${(edge.pressure / 1000000).toStringAsFixed(4)} МПа"),
            //edge.temperature!=null?Text("Тепература: ${(edge.temperature! - 273.15).toStringAsFixed(2)} °C) "):const SizedBox.shrink(),
            //Text("Диаметр: ${edge.diam} м"),
            // (edge.type == PipelineElementType.valve)
            //     ? MaterialButton(
            //   color: edge.openPercentage == 0
            //       ? Colors.redAccent
            //       : Colors.lightGreen,
            //   child: Text(
            //       edge.openPercentage == 0 ? "Закрыт" : "Открыт"),
            //   onPressed: () {
            //     context.read<EditorPageBloc>().add(
            //         GdsThroughputFLowPercentageElementChangeEvent(
            //             edge, edge.openPercentage == 0 ? 1 : 0));
            //   },
            // )
            //     : const SizedBox.shrink(),
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: lenValueTextController
                  ..text = edge.length.toStringAsFixed(1),
                onSubmitted: (value) {
                  stateStore.changeLen(
                      edge, double.parse(lenValueTextController.value.text));
                },
                decoration: const InputDecoration(
                  labelText: 'Длина м',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: diamValueTextController,
                onChanged: (str) {
                  stateStore.changeDiam(
                      edge, double.parse(diamValueTextController.value.text));
                },
                decoration: const InputDecoration(
                  labelText: 'Диаметр, м',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(10),
                child: MaterialButton(
                  onPressed: () {
                    stateStore.deleteSelectedElement();
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
