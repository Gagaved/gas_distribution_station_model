import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/tools/tools_state_mobx.dart';

import 'heat_map_tool.dart';

class CalculationTool extends StatefulObserverWidget {
  const CalculationTool({Key? key}) : super(key: key);

  @override
  State<CalculationTool> createState() => _CalculationToolState();
}

class _CalculationToolState extends State<CalculationTool> {
  Offset position = const Offset(10, 10);
  final epsilonController = TextEditingController();
  final epsilonFocusNode = FocusNode();
  final viscosityController = TextEditingController();
  final viscosityFocusNode = FocusNode();
  final universalGasConstantController = TextEditingController();
  final universalGasConstantFocusNode = FocusNode();
  final zFactorController = TextEditingController();
  final zFactorFocusNode = FocusNode();
  final molarMassController = TextEditingController();
  final molarMassFocusNode = FocusNode();
  final specificHeatController = TextEditingController();
  final specificHeatNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    epsilonController.text = stateStore.epsilon.toString();
    viscosityController.text = stateStore.viscosity.toString();
    universalGasConstantController.text =
        stateStore.universalGasConstant.toString();
    molarMassController.text = stateStore.molarMass.toString();
    zFactorController.text = stateStore.zFactor.toString();
    specificHeatController.text = stateStore.specificHeat.toString();
    if (ToolsState.of(context).calculationToolVisible) {
      return Positioned(
        right: position.dx,
        top: position.dy,
        child: GestureDetector(
          onPanUpdate: (det) {
            setState(() {
              position = position + Offset(-det.delta.dx, det.delta.dy);
            });
          },
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    ToolsState.of(context)
                                        .calculationToolVisible = false;
                                  },
                                  icon: const Icon(Icons.close)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 150,
                            child: Builder(builder: (context) {
                              void save() {
                                try {
                                  final value = epsilonController.text;
                                  final formatedString =
                                      value.replaceAllMapped(',', (f) => '.');
                                  stateStore.epsilon =
                                      double.parse(formatedString);
                                  print('set epsilon to ${stateStore.epsilon}');
                                  epsilonController.text = formatedString;
                                  epsilonFocusNode.parent?.requestFocus();
                                } catch (e) {
                                  stateStore.epsilon = 0.000001;
                                  epsilonController.text =
                                      stateStore.epsilon.toString();
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
                                  stateStore.viscosity =
                                      double.parse(formatedString);
                                  print(
                                      'set viscosity to ${stateStore.viscosity}');
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
                                  final value =
                                      universalGasConstantController.text;
                                  final formatedString =
                                      value.replaceAllMapped(',', (f) => '.');
                                  stateStore.universalGasConstant =
                                      double.parse(formatedString);
                                  print(
                                      'set universalGasConstant to ${stateStore.universalGasConstant}');
                                  universalGasConstantController.text =
                                      formatedString;
                                  universalGasConstantFocusNode.parent
                                      ?.requestFocus();
                                } catch (e) {
                                  universalGasConstantController.text =
                                      stateStore.universalGasConstant
                                          .toString();
                                }
                              }

                              return TextField(
                                focusNode: universalGasConstantFocusNode,
                                controller: universalGasConstantController,
                                keyboardType: TextInputType.number,
                                onTapOutside: (_) => save(),
                                onEditingComplete: () => save(),
                                decoration: const InputDecoration(
                                  labelText: 'Г. пост. Дж/(моль·К)',
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
                                  final value = molarMassController.text;
                                  final formatedString =
                                      value.replaceAllMapped(',', (f) => '.');
                                  stateStore.molarMass =
                                      double.parse(formatedString);
                                  print(
                                      'set molarMass to ${stateStore.molarMass}');
                                  molarMassController.text = formatedString;
                                  molarMassFocusNode.parent?.requestFocus();
                                } catch (e) {
                                  molarMassController.text =
                                      stateStore.molarMass.toString();
                                }
                              }

                              return TextField(
                                focusNode: molarMassFocusNode,
                                controller: molarMassController,
                                keyboardType: TextInputType.number,
                                onTapOutside: (_) => save(),
                                onEditingComplete: () => save(),
                                decoration: const InputDecoration(
                                  labelText: 'Молярная м. кг/моль',
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
                                  final value = zFactorController.text;
                                  final formatedString =
                                      value.replaceAllMapped(',', (f) => '.');
                                  stateStore.zFactor =
                                      double.parse(formatedString);
                                  print('set zFactor to ${stateStore.zFactor}');
                                  zFactorController.text = formatedString;
                                  zFactorFocusNode.parent?.requestFocus();
                                } catch (e) {
                                  zFactorController.text =
                                      stateStore.molarMass.toString();
                                }
                              }

                              return TextField(
                                focusNode: zFactorFocusNode,
                                controller: zFactorController,
                                keyboardType: TextInputType.number,
                                onTapOutside: (_) => save(),
                                onEditingComplete: () => save(),
                                decoration: const InputDecoration(
                                  labelText: 'Фактор сжимаемости',
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
                                  final value = specificHeatController.text;
                                  final formatedString =
                                      value.replaceAllMapped(',', (f) => '.');
                                  stateStore.specificHeat =
                                      double.parse(formatedString);
                                  print(
                                      'set specificHeat to ${stateStore.specificHeat}');
                                  specificHeatController.text = formatedString;
                                  specificHeatNode.parent?.requestFocus();
                                } catch (e) {
                                  specificHeatController.text =
                                      stateStore.specificHeat.toString();
                                }
                              }

                              return TextField(
                                focusNode: specificHeatNode,
                                controller: specificHeatController,
                                keyboardType: TextInputType.number,
                                onTapOutside: (_) => save(),
                                onEditingComplete: () => save(),
                                decoration: const InputDecoration(
                                  labelText: 'Уд. тепл. Дж/(кг·К)',
                                  border: OutlineInputBorder(),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          MaterialButton(
                            onPressed: stateStore.calculateStatus !=
                                    CalculateStatus.process
                                ? () {
                                    stateStore.calculateGasNetwork();
                                  }
                                : null,
                            child: stateStore.calculateStatus ==
                                    CalculateStatus.process
                                ? const CircularProgressIndicator()
                                : const Text('Расчитать'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Card(
                    child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: FlowHeatPressureSwitcher(),
                )),
              ],
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
