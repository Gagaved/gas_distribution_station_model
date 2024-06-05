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
    if (_lastCreatedNodeIdForEdgeTool != null) {
      lastCreatedNodeForEdgeTool =
          _graph.getElementById(_lastCreatedNodeIdForEdgeTool!);
    }
    //debugPrint('selectedElementsIds: $selectedElementIds');
  }

  // @action
  // void addNewEdge(double diam) {
  //   var newEdge = _addNewEdge(diam);
  //   selectedElement = newEdge;
  // }

  GraphElement getGraphElementById(String id) => _graph.getElementById(id);

  @action
  void deleteSelectedElement() {
    for (var id in selectedElementIds) {
      _deleteElement(_graph.getElementById(id));
    }
    updateEdgesAndNodesState();
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
      _graph.getElementById((element).id).position += offset;
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
          _graph.link(_lastCreatedNodeIdForEdgeTool!, newNode.id, 10, 10, 1);
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

  void _deleteElement(GraphElement graphElement) {
    switch (graphElement) {
      case Node():
        _graph.removeNode(graphElement);
      case Edge():
        _graph.removeEdge(graphElement);
    }
    updateEdgesAndNodesState();
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
