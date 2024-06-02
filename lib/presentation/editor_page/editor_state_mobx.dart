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
    edges = _graph.edges;
    nodes = _graph.nodes;
  }

  // Задаем параметры газа
  @observable
  double viscosity = 0.0000181; // Вязкость газа в Па·с

  @observable
  double density = 1.225; // Плотность газа в кг/м³

  @observable
  double epsilon = 1e-6; // Допустимая погрешность

  @observable
  Map<Offset, List<Node>> magneticGrid = {};

  @observable
  CalculateStatus calculateStatus = CalculateStatus.complete;

  final GasNetwork _graph = GasNetwork(edges: [], nodes: []);
  @observable
  late List<Edge> edges;
  @observable
  late List<Node> nodes;

  @observable
  ObservableSet<String> selectedElementIds = ObservableSet();

  @observable
  ToolType? selectedTool;

  void _updateEdgesAndNodesState() {
    edges = [..._graph.edges];
    nodes = [..._graph.nodes];
    if (_lastCreatedNodeIdForEdgeTool != null) {
      lastCreatedNodeForEdgeTool =
          _graph.getElementById(_lastCreatedNodeIdForEdgeTool!);
    }
  }

  // @action
  // void addNewEdge(double diam) {
  //   var newEdge = _addNewEdge(diam);
  //   selectedElement = newEdge;
  // }

  @action
  void deleteSelectedElement() {
    for (var id in selectedElementIds) {
      _deleteElement(_graph.getElementById(id));
    }
    _updateEdgesAndNodesState();
  }

  @action
  Future<void> calculateFlow() async {
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
      _updateEdgesAndNodesState();
    }
  }

  @action
  void deselectElements() {
    if (selectedTool != null) {
      selectedTool = null;
    } else {
      selectedElementIds.clear();
    }
    _updateEdgesAndNodesState();
  }

  @action
  void moveElement(Offset offset) {
    final Set draggablePoints = <Node>{};
    final selectedElements =
        selectedElementIds.map((id) => _graph.getElementById(id));
    selectedElements.whereType<Edge>().forEach((element) {
      draggablePoints.add(_graph.nodeById(element.endNodeId));
      draggablePoints.add(_graph.nodeById(element.startNodeId));
    });
    draggablePoints.addAll(selectedElements.whereType<Node>());
    for (var element in draggablePoints) {
      _graph.getElementById((element).id).position += offset;
    }

    _updateEdgesAndNodesState();
  }

  @action
  void moveNode(String nodeId, Offset delta) {
    Node p = _graph.nodeById(nodeId);
    p.position += delta;
    Node? otherPoint = magnatePoint(p);
    if (otherPoint != null) {
      _graph.mergePoints(p, otherPoint);
    }
    _updateEdgesAndNodesState();
  }

  @action
  void changeSelectedToolType(ToolType type) {
    selectedTool = selectedTool == type ? null : type;
    _updateEdgesAndNodesState();
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
          _graph.link(_lastCreatedNodeIdForEdgeTool!, newNode.id, 10, 10, 1);
        } else {
          _lastCreatedNodeIdForEdgeTool = _graph.addNode(localPosition).id;
        }

      case ToolType.node:
        _graph.addNode(localPosition);
    }
    _updateEdgesAndNodesState();
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

  Node? magnatePoint(Node point) {
    double magneticRange = 7;
    for (Node otherPoint in _graph.nodes) {
      if (point != otherPoint &&
          (point.position.dx - otherPoint.position.dx).abs() <= magneticRange &&
          (point.position.dy - otherPoint.position.dy).abs() <= magneticRange) {
        point.position = otherPoint.position;
        _graph.mergePoints(point, otherPoint);
        _updateEdgesAndNodesState();
        return otherPoint;
      }
    }
    _updateEdgesAndNodesState();
    return null;
  }

  Edge _addNewEdge(double diam) {
    var p1 = _graph.addNode(const Offset(300, 300));
    var p2 = _graph.addNode(const Offset(300, 400));
    final newEdge = _graph.link(p1.id, p2.id, diam, 100, 0.0001);
    _updateEdgesAndNodesState();
    return newEdge;
  }

  void _deleteElement(GraphElement graphElement) {
    switch (graphElement) {
      case Node():
        _graph.removeNode(graphElement);
      case Edge():
        _graph.removeEdge(graphElement);
    }
    _updateEdgesAndNodesState();
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
