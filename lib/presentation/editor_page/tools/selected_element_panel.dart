import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/presentation/design/app_card.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';

import '../../../models/gas_network.dart';

class SelectedElementPanel extends StatefulObserverWidget {
  const SelectedElementPanel({super.key});

  @override
  State<SelectedElementPanel> createState() => _SelectedElementPanelState();
}

class _SelectedElementPanelState extends State<SelectedElementPanel> {
  @override
  void initState() {
    super.initState();
  }

  Offset position = const Offset(20, 20);

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final selectedElement = stateStore.singleSelectedElement;
    if (selectedElement == null) {
      return const SizedBox.shrink();
    } else {
      return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: (det) {
              setState(() {
                position = position + det.delta;
              });
            },
            child: Card(
                child: switch (selectedElement) {
              Edge() => const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EdgeEditingFields(),
                        SizedBox(height: 5),
                        _EdgeInformationFields(),
                      ],
                    ),
                  ),
                ),
              Node() => const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        _NodeEditingFields(),
                        SizedBox(height: 5),
                        _NodeInformationFields(),
                      ],
                    ),
                  ),
                ),
            }),
          ));
    }
  }
}

class _NodeEditingFields extends StatefulObserverWidget {
  const _NodeEditingFields();

  @override
  State<_NodeEditingFields> createState() => _NodeEditingFieldsState();
}

enum SinkFlowMeasure {
  perSec,
  perHour,
}

enum PressureMeasure {
  MPA,
  PA,
}

class _NodeEditingFieldsState extends State<_NodeEditingFields> {
  final TextEditingController _sinkFlowController = TextEditingController();
  final TextEditingController _pressureController = TextEditingController();
  SinkFlowMeasure sinkFlowMeasure = SinkFlowMeasure.perHour;
  PressureMeasure pressureMeasure = PressureMeasure.MPA;
  final nodeTypeFocusNode = FocusNode(debugLabel: "nodeTypeFocusNode");
  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final Node node = stateStore.singleSelectedElement as Node;
    _pressureController.text =
        (node.pressure * (pressureMeasure == PressureMeasure.PA ? 1 : 1e-6))
            .toStringAsFixed(2);
    _sinkFlowController.text =
        (node.sinkFlow * (sinkFlowMeasure == SinkFlowMeasure.perSec ? 1 : 3600))
            .toString();

    return (Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        MaterialButton(
          onPressed: () {
            stateStore.deleteElement(node);
          },
          color: Colors.red,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Удалить'),
              Icon(
                Icons.delete,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DropdownButton<NodeType>(
          focusNode: nodeTypeFocusNode,
          value: node.type,
          items:
              NodeType.values.map<DropdownMenuItem<NodeType>>((NodeType type) {
            return DropdownMenuItem<NodeType>(
              value: type,
              child: Text(
                type.value,
              ),
            );
          }).toList(),
          onChanged: (NodeType? type) {
            setState(() {
              if (type != null) {
                node.type = type;
                stateStore.updateEdgesAndNodesState();
              }
            });
          },
        ),
        const SizedBox(height: 10),
        if (node.type == NodeType.sink)
          SizedBox(
            width: 200,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sinkFlowController,
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) {
                          try {
                            final formatedString =
                                value.replaceAllMapped(',', (f) => '.');
                            node.sinkFlow = double.parse(formatedString) /
                                ((sinkFlowMeasure == SinkFlowMeasure.perHour)
                                    ? 3600
                                    : 1);
                            print('set target sink flow to ${node.sinkFlow}');
                            _sinkFlowController.text = formatedString;
                          } catch (e) {
                            node.sinkFlow = 0;
                            _sinkFlowController.value =
                                const TextEditingValue(text: '0');
                          }
                        },
                        decoration: InputDecoration(
                          labelText:
                              'Расход, ${sinkFlowMeasure == SinkFlowMeasure.perSec ? 'М^3/c' : 'М^3/ч'}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                            child: Text(
                                'в М^3/${sinkFlowMeasure == SinkFlowMeasure.perHour ? 'ч' : 'c'}')),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: sinkFlowMeasure == SinkFlowMeasure.perHour,
                            onChanged: (bool value) {
                              setState(() {
                                value
                                    ? sinkFlowMeasure = SinkFlowMeasure.perHour
                                    : sinkFlowMeasure = SinkFlowMeasure.perSec;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        if (node.type == NodeType.source)
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onTap: () {},
                    controller: _pressureController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (value) {
                      try {
                        final formatedString =
                            value.replaceAllMapped(',', (f) => '.');
                        node.pressure = double.parse(formatedString) *
                            ((pressureMeasure == PressureMeasure.PA)
                                ? 1
                                : 1e+6);
                        print('set target preassure to ${node.pressure}');
                        _pressureController.text = formatedString;
                      } catch (e) {
                        node.sinkFlow = 0;
                        _pressureController.value =
                            const TextEditingValue(text: '0');
                      }
                    },
                    decoration: InputDecoration(
                      labelText:
                          'Давление, ${pressureMeasure == PressureMeasure.PA ? 'Па' : 'МПА'}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child: Text(pressureMeasure == PressureMeasure.PA
                            ? 'в Па'
                            : 'в МПа')),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: pressureMeasure == PressureMeasure.MPA,
                        onChanged: (bool value) {
                          setState(() {
                            value
                                ? pressureMeasure = PressureMeasure.MPA
                                : pressureMeasure = PressureMeasure.PA;
                          });
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
      ],
    ));
  }
}

class _EdgeEditingFields extends StatefulObserverWidget {
  const _EdgeEditingFields();

  @override
  State<_EdgeEditingFields> createState() => _EdgeEditingFieldsState();
}

class _EdgeEditingFieldsState extends State<_EdgeEditingFields> {
  final FocusNode _edgeTypeFocusNode =
      FocusNode(debugLabel: '_edgeTypeFocusNode');
  final FocusNode _edgeLenFocusNode =
      FocusNode(debugLabel: '_edgeLenFocusNode');
  final FocusNode _edgeDiamFocusNode =
      FocusNode(debugLabel: '_edgeDiamFocusNode');
  final FocusNode _roughnessFocusNode =
      FocusNode(debugLabel: '_roughnessFocusNode');
  final FocusNode _reducerFocusNode =
      FocusNode(debugLabel: '_reducerLenFocusNode');
  final FocusNode _valvePowConductanceCoefficientNode =
      FocusNode(debugLabel: '_reducerLenFocusNode');
  final FocusNode _heaterPowerNode =
      FocusNode(debugLabel: '_heaterPowerFocusNode');
  final TextEditingController _lenController = TextEditingController();
  final TextEditingController _diamController = TextEditingController();
  final TextEditingController _roughnessController = TextEditingController();
  final TextEditingController _reducerController = TextEditingController();
  final TextEditingController _heaterPowerController = TextEditingController();
  final TextEditingController _valvePowConductanceCoefficientController =
      TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final Edge edge = stateStore.singleSelectedElement as Edge;
    _lenController.text = edge.length.toString();
    _diamController.text = edge.diameter.toString();
    _roughnessController.text = edge.roughness.toString();
    _reducerController.text =
        (edge.reducerTargetPressure * 1e-6).toStringAsFixed(2);
    _valvePowConductanceCoefficientController.text =
        edge.valvePowConductanceCoefficient.toStringAsFixed(2);
    _heaterPowerController.text = edge.heaterPower.toStringAsFixed(2);
    return (Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {
                      stateStore.rotateEdge(edge);
                    },
                    icon: const Icon(Icons.rotate_left)),
                MaterialButton(
                  onPressed: () {
                    stateStore.deleteElement(edge);
                  },
                  color: Colors.red,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Удалить'),
                      Icon(
                        Icons.delete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Тип участка',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black54),
            ),
            DropdownButton<EdgeType>(
              value: edge.type,
              items: EdgeType.values
                  .map<DropdownMenuItem<EdgeType>>((EdgeType type) {
                return DropdownMenuItem<EdgeType>(
                  value: type,
                  child: Text(
                    type.value,
                  ),
                );
              }).toList(),
              onChanged: (EdgeType? type) {
                setState(() {
                  if (type != null) {
                    edge.type = type;
                    stateStore.updateEdgesAndNodesState();
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          title: 'Общие параметры',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                child: Builder(builder: (context) {
                  void save() {
                    try {
                      final value = _lenController.text;
                      final formatedString =
                          value.replaceAllMapped(',', (f) => '.');
                      edge.length = double.parse(formatedString);
                      print('set len to ${edge.length}');
                      _lenController.text = formatedString;
                      _edgeLenFocusNode.parent?.requestFocus();
                    } catch (e) {
                      edge.length = 0;
                      _lenController.value = const TextEditingValue(text: '0');
                    }
                  }

                  return TextField(
                    focusNode: _edgeLenFocusNode,
                    controller: _lenController,
                    keyboardType: TextInputType.number,
                    onTapOutside: (_) => save(),
                    onEditingComplete: () => save(),
                    decoration: const InputDecoration(
                      labelText: 'Длина, м',
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
                      final value = _diamController.text;
                      final formatedString =
                          value.replaceAllMapped(',', (f) => '.');
                      edge.diameter = double.parse(formatedString);
                      print('set diam to ${edge.diameter}');
                      _diamController.text = formatedString;
                      _edgeDiamFocusNode.parent?.requestFocus();
                    } catch (e) {
                      edge.diameter = 0;
                      _diamController.value = const TextEditingValue(text: '0');
                    }
                  }

                  return TextField(
                    focusNode: _edgeDiamFocusNode,
                    controller: _diamController,
                    keyboardType: TextInputType.number,
                    onTapOutside: (_) => save(),
                    onEditingComplete: () => save(),
                    decoration: const InputDecoration(
                      labelText: 'Диаметр, м',
                      border: OutlineInputBorder(),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: SizedBox(
                  width: 150,
                  child: Builder(builder: (context) {
                    void save() {
                      try {
                        final value = _roughnessController.text;
                        final formatedString =
                            value.replaceAllMapped(',', (f) => '.');
                        edge.roughness = double.parse(formatedString);
                        print('set roughness to ${edge.roughness}');
                        _roughnessController.text = formatedString;
                        _roughnessFocusNode.parent?.requestFocus();
                      } catch (e) {
                        //edge.roughness = 0.0001;
                        _roughnessController.value =
                            const TextEditingValue(text: '0');
                      }
                    }

                    return TextField(
                      focusNode: _roughnessFocusNode,
                      controller: _roughnessController,
                      keyboardType: TextInputType.number,
                      onTapOutside: (_) => save(),
                      onEditingComplete: () => save(),
                      decoration: const InputDecoration(
                        labelText: 'Шераховатость, мкм',
                        border: OutlineInputBorder(),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        if (edge.type == EdgeType.reducer)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: AppCard(
              title: 'Регулятор давления',
              subTitle: const Text('Установите давление регулятора'),
              child: Builder(builder: (context) {
                void save() {
                  try {
                    final value = _reducerController.text;
                    final formatedString =
                        value.replaceAllMapped(',', (f) => '.');
                    edge.reducerTargetPressure =
                        double.parse(formatedString) * 1e6;
                    print('set reduser value to ${edge.reducerTargetPressure}');
                    _reducerController.text = formatedString;
                    _reducerFocusNode.parent?.requestFocus();
                  } catch (e) {
                    edge.reducerTargetPressure = 0;
                    _reducerController.value =
                        const TextEditingValue(text: '0');
                  }
                }

                return TextField(
                  focusNode: _reducerFocusNode,
                  controller: _reducerController,
                  keyboardType: TextInputType.number,
                  onTapOutside: (_) => save(),
                  onEditingComplete: () => save(),
                  decoration: const InputDecoration(
                    labelText: 'Давление, МПа',
                    border: OutlineInputBorder(),
                  ),
                );
              }),
            ),
          ),
        if (edge.type == EdgeType.percentageValve)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: AppCard(
              title: "Регулируемый кран",
              subTitle: const Text(
                'Выберете процент открытия с помощью слайдера',
                style: TextStyle(fontSize: 12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                      value: edge.percentageValve,
                      onChanged: (value) {
                        setState(() {
                          edge.percentageValve = value;
                          stateStore.updateEdgesAndNodesState();
                        });
                      }),
                  Text(
                      'Процент открытия: ${(edge.percentageValve * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 10),
                  const Text(
                    'Коэф степенной функции сопротивления крана',
                    style: TextStyle(fontSize: 12, height: 1),
                  ),
                  const SizedBox(height: 5),
                  Builder(builder: (context) {
                    void save() {
                      try {
                        final value =
                            _valvePowConductanceCoefficientController.text;
                        final formatedString =
                            value.replaceAllMapped(',', (f) => '.');
                        edge.valvePowConductanceCoefficient =
                            double.parse(formatedString);
                        print(
                            'set valvePowConductanceCoefficient value to ${edge.valvePowConductanceCoefficient}');
                        _valvePowConductanceCoefficientController.text =
                            formatedString;
                        _valvePowConductanceCoefficientNode.parent
                            ?.requestFocus();
                      } catch (e) {
                        edge.valvePowConductanceCoefficient = 2;
                        _valvePowConductanceCoefficientController.value =
                            const TextEditingValue(text: '0');
                      }
                    }

                    return TextField(
                      focusNode: _valvePowConductanceCoefficientNode,
                      controller: _valvePowConductanceCoefficientController,
                      keyboardType: TextInputType.number,
                      onTapOutside: (_) => save(),
                      onEditingComplete: () => save(),
                      decoration: const InputDecoration(
                        labelText: 'Коэфициент',
                        border: OutlineInputBorder(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        if (edge.type == EdgeType.valve)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: AppCard(
              title: 'Нерегулируемый кран',
              subTitle: const Text(
                'Два положения',
                style: TextStyle(fontSize: 12),
              ),
              child: Builder(builder: (context) {
                bool isOpen = edge.percentageValve != 0;
                return MaterialButton(
                    onPressed: () {
                      setState(() {
                        isOpen
                            ? edge.percentageValve = 0
                            : edge.percentageValve = 1;
                        stateStore.updateEdgesAndNodesState();
                      });
                    },
                    color: isOpen ? Colors.green : Colors.red,
                    child: Text(isOpen ? 'Открыт' : 'Закрыт'));
              }),
            ),
          ),
        if (edge.type == EdgeType.adorizer)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: AppCard(
              title: 'Адоризатор',
              child: Builder(builder: (context) {
                return MaterialButton(
                    onPressed: () {
                      setState(() {
                        edge.adorizerOn = !edge.adorizerOn;
                        stateStore.updateEdgesAndNodesState();
                      });
                    },
                    color: edge.adorizerOn ? Colors.green : Colors.red,
                    child: Text(edge.adorizerOn
                        ? 'Арозирация вкл'
                        : 'Адоризация выкл'));
              }),
            ),
          ),
        if (edge.type == EdgeType.heater)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: AppCard(
              title: 'Нагреватель',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: SizedBox(
                      width: 150,
                      child: Builder(builder: (context) {
                        void save() {
                          try {
                            final value = _heaterPowerController.text;
                            final formatedString =
                                value.replaceAllMapped(',', (f) => '.');
                            edge.heaterPower = double.parse(formatedString);
                            print('set heaterPower to ${edge.heaterPower}');
                            _heaterPowerController.text = formatedString;
                            _heaterPowerNode.parent?.requestFocus();
                          } catch (e) {
                            _heaterPowerController.value =
                                const TextEditingValue(text: '0');
                          }
                        }

                        return TextField(
                          focusNode: _heaterPowerNode,
                          controller: _heaterPowerController,
                          keyboardType: TextInputType.number,
                          onTapOutside: (_) => save(),
                          onEditingComplete: () => save(),
                          decoration: const InputDecoration(
                            labelText: 'Мощность, Ватт',
                            border: OutlineInputBorder(),
                          ),
                        );
                      }),
                    ),
                  ),
                  MaterialButton(
                      onPressed: () {
                        setState(() {
                          edge.heaterOn = !edge.heaterOn;
                          stateStore.updateEdgesAndNodesState();
                        });
                      },
                      color: edge.heaterOn ? Colors.green : Colors.red,
                      child: Text(edge.heaterOn ? 'Нагрев' : 'Выключен')),
                ],
              ),
            ),
          ),
      ],
    ));
  }
}

class _EdgeInformationFields extends StatelessObserverWidget {
  const _EdgeInformationFields({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final Edge edge = stateStore.singleSelectedElement as Edge;
    return AppCard(
      title: 'Результаты расчета',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Поток: ${edge.flowPerHour.abs().toStringAsFixed(1)} М^3/ч'),
          Text(
              'Температура: ${(edge.temperature - 273.15).toStringAsFixed(1)} °C'),
          Text('Давление: ${(edge.pressure).toStringAsFixed(1)} Па'),
          Text(
            edge.isAdorize ? 'Адоризирован' : 'не адоризирован',
            style: TextStyle(color: edge.isAdorize ? Colors.green : Colors.red),
          ),
          // GestureDetector(
          //     onTap: () {
          //       Clipboard.setData(ClipboardData(text: selectedElement.id))
          //           .then((_) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text("id copied to clipboard")));
          //       });
          //     },
          //     child: Text('id: ${selectedElement.id}')),
        ],
      ),
    );
  }
}

class _NodeInformationFields extends StatelessObserverWidget {
  const _NodeInformationFields({super.key});

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final Node node = stateStore.singleSelectedElement as Node;
    return AppCard(
        title: 'Результаты расчета',
        child: Column(
          children: [
            Text('Давление: ${node.pressure.toStringAsFixed(0)} Па'),
            Text(
                'Температура: ${(node.temperature - 273.15).toStringAsFixed(1)} °C'),
            GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: node.id)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("id copied to clipboard")));
                  });
                },
                child: Text('id: ${node.id}')),
          ],
        ));
  }
}
