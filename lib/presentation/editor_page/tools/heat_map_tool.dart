import 'package:flutter/material.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/tools/tools_state_mobx.dart';

class FlowHeatPressureSwitcher extends StatefulWidget {
  const FlowHeatPressureSwitcher({Key? key}) : super(key: key);
  @override
  State<FlowHeatPressureSwitcher> createState() =>
      _FlowHeatPressureSwitcherState();
}

class _FlowHeatPressureSwitcherState extends State<FlowHeatPressureSwitcher> {
  final _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    final stateStore = ToolsState.of(context);
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Тепловая карта'),
          DropdownButton<HeatMapState>(
            focusNode: _focusNode,
            value: stateStore.heatMapState,
            items: HeatMapState.values
                .map<DropdownMenuItem<HeatMapState>>((HeatMapState type) {
              return DropdownMenuItem<HeatMapState>(
                value: type,
                child: Text(
                  type.value,
                ),
              );
            }).toList(),
            onChanged: (HeatMapState? type) {
              setState(() {
                if (type != null) {
                  stateStore.heatMapState =
                      stateStore.heatMapState == type ? null : type;
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
