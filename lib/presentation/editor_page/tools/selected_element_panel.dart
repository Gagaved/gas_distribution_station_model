import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
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
              Edge() => const _EdgeEditingFields(),
              Node() => const _NodeEditingFields(),
            }),
          ));
    }
  }
}

class _NodeEditingFields extends StatefulObserverWidget {
  const _NodeEditingFields({super.key});

  @override
  State<_NodeEditingFields> createState() => _NodeEditingFieldsState();
}

class _NodeEditingFieldsState extends State<_NodeEditingFields> {
  final TextEditingController _nodeTypeController = TextEditingController();
  final TextEditingController _pressureController = TextEditingController();
  final nodeTypeFocusNode = FocusNode(debugLabel: "nodeTypeFocusNode");
  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final Node selectedElement = stateStore.singleSelectedElement as Node;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: (Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          MaterialButton(
            onPressed: () {
              stateStore.deleteElement(selectedElement);
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
            value: selectedElement.type,
            items: NodeType.values
                .map<DropdownMenuItem<NodeType>>((NodeType type) {
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
                  selectedElement.type = type;
                  stateStore.updateEdgesAndNodesState();
                  // nodeTypeFocusNode.unfocus(
                  //     disposition: UnfocusDisposition.previouslyFocusedChild);
                }
              });
            },
          ),
          const SizedBox(height: 10),
          if (selectedElement.type == NodeType.source)
            SizedBox(
              width: 150,
              child: TextField(
                controller: _pressureController,
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  try {
                    final formatedString =
                        value.replaceAllMapped(',', (f) => '.');
                    selectedElement.pressure = double.parse(formatedString);
                    print('set pressure to ${selectedElement.pressure}');
                    _pressureController.text = formatedString;
                  } catch (e) {
                    selectedElement.pressure = 0;
                    _pressureController.value =
                        const TextEditingValue(text: '0');
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Давление, МПа',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      )),
    );
  }
}

class _EdgeEditingFields extends StatefulObserverWidget {
  const _EdgeEditingFields({super.key});

  @override
  State<_EdgeEditingFields> createState() => _EdgeEditingFieldsState();
}

class _EdgeEditingFieldsState extends State<_EdgeEditingFields> {
  final FocusNode _edgeTypeFocusNode =
      FocusNode(debugLabel: '_edgeTypeFocusNode');
  final FocusNode _edgeLenFocusNode =
      FocusNode(debugLabel: '_edgeLenFocusNode');
  final TextEditingController _pressureController = TextEditingController();
  @override
  void initState() {
    _edgeTypeFocusNode.addListener(() {
      print('');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    final Edge selectedElement = stateStore.singleSelectedElement as Edge;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: (Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          MaterialButton(
            onPressed: () {
              stateStore.deleteElement(selectedElement);
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
          DropdownButton<EdgeType>(
            value: selectedElement.type,
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
                  selectedElement.type = type;
                  stateStore.updateEdgesAndNodesState();
                }
              });
            },
          ),
          const SizedBox(height: 10),
          if (selectedElement.type == EdgeType.segment)
            SizedBox(
              width: 150,
              child: Builder(builder: (context) {
                void save() {
                  try {
                    final value = _pressureController.text;
                    final formatedString =
                        value.replaceAllMapped(',', (f) => '.');
                    selectedElement.length = double.parse(formatedString);
                    print('set len to ${selectedElement.length}');
                    _pressureController.text = formatedString;
                    _edgeLenFocusNode.parent?.requestFocus();
                  } catch (e) {
                    selectedElement.length = 0;
                    _pressureController.value =
                        const TextEditingValue(text: '0');
                  }
                }

                return TextField(
                  focusNode: _edgeLenFocusNode,
                  controller: _pressureController,
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
          if (selectedElement.type == EdgeType.percentageValve)
            Row(
              children: [
                Slider(
                    value: selectedElement.percentageValve,
                    onChanged: (value) {
                      setState(() {
                        selectedElement.percentageValve = value;
                        stateStore.updateEdgesAndNodesState();
                      });
                    }),
                Text(
                    'Процент открытия: ${(selectedElement.percentageValve * 100).toStringAsFixed(0)}%')
              ],
            ),
          if (selectedElement.type == EdgeType.valve)
            Builder(builder: (context) {
              bool isOpen = selectedElement.percentageValve != 0;
              return Row(
                children: [
                  MaterialButton(
                      onPressed: () {
                        setState(() {
                          isOpen
                              ? selectedElement.percentageValve = 0
                              : selectedElement.percentageValve = 1;
                          stateStore.updateEdgesAndNodesState();
                        });
                      },
                      color: isOpen ? Colors.green : Colors.red,
                      child: Text(isOpen ? 'Открыт' : 'Закрыт')),
                ],
              );
            })
        ],
      )),
    );
  }
}
