import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';

class CalculationTool extends StatefulObserverWidget {
  const CalculationTool({Key? key}) : super(key: key);

  @override
  State<CalculationTool> createState() => _CalculationToolState();
}

class _CalculationToolState extends State<CalculationTool> {
  final epsilonController = TextEditingController();
  final epsilonFocusNode = FocusNode();
  final viscosityController = TextEditingController();
  final viscosityFocusNode = FocusNode();
  final densityController = TextEditingController();
  final densityFocusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    epsilonController.text = stateStore.epsilon.toString();
    viscosityController.text = stateStore.viscosity.toString();
    densityController.text = stateStore.density.toString();
    return Positioned(
      right: 10,
      top: 10,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                child: Builder(builder: (context) {
                  void save() {
                    try {
                      final value = epsilonController.text;
                      final formatedString =
                          value.replaceAllMapped(',', (f) => '.');
                      stateStore.epsilon = double.parse(formatedString);
                      print('set epsilon to ${stateStore.epsilon}');
                      epsilonController.text = formatedString;
                      epsilonFocusNode.parent?.requestFocus();
                    } catch (e) {
                      stateStore.epsilon = 0.000001;
                      epsilonController.text = stateStore.epsilon.toString();
                    }
                  }

                  return TextField(
                    focusNode: epsilonFocusNode,
                    controller: epsilonController,
                    keyboardType: TextInputType.number,
                    onTapOutside: (_) => save(),
                    onEditingComplete: () => save(),
                    decoration: const InputDecoration(
                      labelText: 'Погрешность ε',
                      border: OutlineInputBorder(),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                child: Builder(builder: (context) {
                  void save() {
                    try {
                      final value = viscosityController.text;
                      final formatedString =
                          value.replaceAllMapped(',', (f) => '.');
                      stateStore.viscosity = double.parse(formatedString);
                      print('set viscosity to ${stateStore.viscosity}');
                      viscosityController.text = formatedString;
                      viscosityFocusNode.parent?.requestFocus();
                    } catch (e) {
                      stateStore.viscosity = 0.000011;
                      viscosityController.text =
                          stateStore.viscosity.toString();
                    }
                  }

                  return TextField(
                    focusNode: viscosityFocusNode,
                    controller: viscosityController,
                    keyboardType: TextInputType.number,
                    onTapOutside: (_) => save(),
                    onEditingComplete: () => save(),
                    decoration: const InputDecoration(
                      labelText: 'Вязкость м²/с',
                      border: OutlineInputBorder(),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                child: Builder(builder: (context) {
                  void save() {
                    try {
                      final value = densityController.text;
                      final formatedString =
                          value.replaceAllMapped(',', (f) => '.');
                      stateStore.density = double.parse(formatedString);
                      print('set density to ${stateStore.viscosity}');
                      densityController.text = formatedString;
                      densityFocusNode.parent?.requestFocus();
                    } catch (e) {
                      stateStore.density = 0.000011;
                      densityController.text = stateStore.density.toString();
                    }
                  }

                  return TextField(
                    focusNode: densityFocusNode,
                    controller: densityController,
                    keyboardType: TextInputType.number,
                    onTapOutside: (_) => save(),
                    onEditingComplete: () => save(),
                    decoration: const InputDecoration(
                      labelText: 'Плотность кг/м³',
                      border: OutlineInputBorder(),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              MaterialButton(
                onPressed: stateStore.calculateStatus != CalculateStatus.process
                    ? () {
                        stateStore.calculateGasNetwork();
                      }
                    : null,
                child: stateStore.calculateStatus == CalculateStatus.process
                    ? const CircularProgressIndicator()
                    : const Text('Расчитать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
