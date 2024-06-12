import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobx/mobx.dart';

import '../../models/gas_network.dart';

part 'editor_state_mobx.g.dart';

class EditorStateStore = EditorState with _$EditorStateStore;

abstract class EditorState with Store {
  static EditorState of(BuildContext context) =>
      context.read<EditorStateStore>();

  void init() {
    var nodes = [
      Node(
          type: NodeType.source,
          pressure: 1000000.0,
          position:
              const Offset(50, 100)), // P0, источник с постоянным давлением
      Node(position: const Offset(150, 100)), // P1
      Node(position: const Offset(250, 100)), // P2
      Node(position: const Offset(350, 100)), // P3
      Node(
          type: NodeType.sink,
          pressure: 0,
          position: const Offset(450, 100)) // P4, сток с максимальным расходом
    ];

    // Определяем рёбра (трубопроводы)
    var edges = [
      Edge(nodes[0].id, nodes[1].id, 0.1, 100, 0.0001), // Q01
      Edge(nodes[1].id, nodes[2].id, 0.1, 100, 0.0001), // Q12
      Edge(nodes[1].id, nodes[3].id, 0.1, 100, 0.0001), // Q13
      Edge(nodes[2].id, nodes[3].id, 0.1, 100, 0.0001), // Q23
      Edge(nodes[3].id, nodes[4].id, 0.1, 100, 0.0001), // Q34
    ];
    _graph = GasNetwork(edges: edges, nodes: nodes);
    this.edges = _graph.edges;
    this.nodes = _graph.nodes;
  }

  // Задаем параметры газа
  @observable
  double viscosity = 0.000011; // Вязкость газа в Па·с

  @observable
  double density = 0.8; // Плотность газа в кг/м³

  @observable
  double epsilon = 1e-8; // Допустимая погрешность

  @observable
  Map<Offset, List<Node>> magneticGrid = {};

  @observable
  CalculateStatus calculateStatus = CalculateStatus.complete;

  late final GasNetwork _graph;
  @observable
  late List<Edge> edges;
  @observable
  late List<Node> nodes;

  @observable
  ObservableSet<String> selectedElementIds = ObservableSet();

  @computed
  GraphElement? get singleSelectedElement => selectedElementIds.length == 1
      ? _graph.getElementById(selectedElementIds.first)
      : null;

  @observable
  ToolType? selectedTool;

  @action
  void updateEdgesAndNodesState() {
    edges = [..._graph.edges];
    nodes = [..._graph.nodes];
    selectedElementIds.removeWhere((id) => _graph.getElementById(id) == null);
    if (_lastCreatedNodeIdForEdgeTool != null) {
      lastCreatedNodeForEdgeTool =
          _graph.getElementById(_lastCreatedNodeIdForEdgeTool!) as Node?;
    }
    //debugPrint('selectedElementsIds: $selectedElementIds');
  }

  // @action
  // void addNewEdge(double diam) {
  //   var newEdge = _addNewEdge(diam);
  //   selectedElement = newEdge;
  // }

  GraphElement getGraphElementById(String id) => _graph.getElementById(id)!;

  @action
  void deleteSelectedElement() {
    for (var id in selectedElementIds) {
      deleteElement(_graph.getElementById(id)!);
    }
    updateEdgesAndNodesState();
  }

  @action
  Future<void> calculateGasNetwork() async {
    calculateStatus = CalculateStatus.process;
    await _graph.calculateGasNetwork(epsilon, viscosity, density);
    calculateStatus = CalculateStatus.complete;
  }

  @action
  void tapOnElement(GraphElement element) {
    if (selectedTool == null) {
      var found = selectedElementIds.lookup(element.id);
      if (found != null) {
        selectedElementIds.remove(found);
      } else {
        selectedElementIds.add(element.id);
      }
      updateEdgesAndNodesState();
    }
  }

  @action
  void deselectElements() {
    if (selectedTool != null) {
      selectedTool = null;
      _lastCreatedNodeIdForEdgeTool = null;
      lastCreatedNodeForEdgeTool = null;
    } else {
      selectedElementIds.clear();
    }
    updateEdgesAndNodesState();
  }

  @action
  void moveElement(Offset offset) {
    final Set draggablePoints = <Node>{};

    if (selectedElementIds.length == 1 &&
        selectedElementIds.map((id) => _graph.getElementById(id)).first
            is Node) {
      moveNode(selectedElementIds.first, offset);
      return;
    }
    final selectedElements =
        selectedElementIds.map((id) => _graph.getElementById(id));
    selectedElements.whereType<Edge>().forEach((element) {
      draggablePoints.add(_graph.nodeById(element.endNodeId));
      draggablePoints.add(_graph.nodeById(element.startNodeId));
    });
    draggablePoints.addAll(selectedElements.whereType<Node>());
    for (var element in draggablePoints) {
      (_graph.getElementById((element).id) as Node).position += offset;
    }

    updateEdgesAndNodesState();
  }

  @action
  void moveNode(String nodeId, Offset delta) {
    Node p = _graph.nodeById(nodeId);
    p.position += delta;
    mergePointIfPossible(p);
    updateEdgesAndNodesState();
  }

  @action
  void changeSelectedToolType(ToolType type) {
    selectedTool = selectedTool == type ? null : type;
    if (selectedTool == null) {
      _lastCreatedNodeIdForEdgeTool = null;
      lastCreatedNodeForEdgeTool = null;
    }
    updateEdgesAndNodesState();
  }

  @observable
  String? _lastCreatedNodeIdForEdgeTool;
  @observable
  Node? lastCreatedNodeForEdgeTool;
  @action
  void createElement(Offset localPosition) {
    switch (selectedTool) {
      case null:
      case ToolType.edge:
        if (_lastCreatedNodeIdForEdgeTool != null) {
          final newNode = _graph.addNode(localPosition);
          _graph.link(
              _lastCreatedNodeIdForEdgeTool!, newNode.id, 0.2, 5, 0.0001);
          _lastCreatedNodeIdForEdgeTool = newNode.id;
        } else {
          lastCreatedNodeForEdgeTool = _graph.addNode(localPosition);
          _lastCreatedNodeIdForEdgeTool = lastCreatedNodeForEdgeTool!.id;
        }
      case ToolType.node:
        _graph.addNode(localPosition);
    }
    updateEdgesAndNodesState();
  }

  @action
  void changeThroughputFlowPercentage(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  void changeHeaterPower(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  void changeSinkTargetFlow(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  void changeLen(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  void changeDiam(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  void changeSourcePressure(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  void changeTargetPressure(Edge element, double value) {
    // TODO: Implement this method.
  }

  @action
  Future<void> exportToFile() async {
    // TODO: Implement this method.
  }

  @action
  Future<void> clear() async {
    // TODO: Implement this method.
  }

  @action
  Future<void> loadFromFile() async {
    // TODO: Implement this method.
  }
  bool isMagneticSurfaceEnable = true;
  double magneticStep = 5;
  double magneticRadius = 3;
  double minDeltaForce = 0.2; // Максимальное допустимое значение силы дельты

  Node? mergePointIfPossible(Node point) {
    double magneticRange = 5;
    for (Node otherPoint in _graph.nodes) {
      if (point != otherPoint &&
          (point.position.dx - otherPoint.position.dx).abs() <= magneticRange &&
          (point.position.dy - otherPoint.position.dy).abs() <= magneticRange) {
        point.position = otherPoint.position;
        _graph.mergePoints(point, otherPoint);
        updateEdgesAndNodesState();
        return otherPoint;
      }
    }
    updateEdgesAndNodesState();
    return null;
  }

  Edge _addNewEdge(double diam) {
    var p1 = _graph.addNode(const Offset(300, 300));
    var p2 = _graph.addNode(const Offset(300, 400));
    final newEdge = _graph.link(p1.id, p2.id, diam, 100, 0.0001);
    updateEdgesAndNodesState();
    return newEdge;
  }

  bool deleteElement(GraphElement graphElement) {
    late final bool removeResult;
    switch (graphElement) {
      case Node():
        removeResult = _graph.removeNode(graphElement);
        print('removeResult: $removeResult');
      case Edge():
        removeResult = _graph.removeEdge(graphElement);
        print('removeResult: $removeResult');
    }
    if (removeResult) {
      selectedElementIds.remove(graphElement.id);
      updateEdgesAndNodesState();
    }
    return removeResult;
  }

  nodeById(String id) => _graph.nodeById(id);
}

enum ToolType {
  edge,
  node,
}

enum CalculateStatus {
  complete,
  process,
}
