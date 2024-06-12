import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';

class CalculationTool extends StatelessObserverWidget {
  const CalculationTool({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    return Positioned(
      right: 10,
      top: 10,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: MaterialButton(
            onPressed: stateStore.calculateStatus != CalculateStatus.process
                ? () {
                    stateStore.calculateGasNetwork();
                  }
                : null,
            child: stateStore.calculateStatus == CalculateStatus.process
                ? const CircularProgressIndicator()
                : const Text('Расчитать'),
          ),
        ),
      ),
    );
  }
}
