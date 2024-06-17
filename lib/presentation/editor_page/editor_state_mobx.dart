import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gas_distribution_station_model/data/util/FileManager.dart';
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
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
          calculationType: NodeCalculationType.pressure,
          pressure: 3000000.0,
          position:
              const Offset(50, 100)), // P0, источник с постоянным давлением
      Node(position: const Offset(150, 100)), // P1
      Node(position: const Offset(250, 100)), // P2
      Node(position: const Offset(350, 100)), // P2
      Node(position: const Offset(450, 100)), // P3
      Node(
          type: NodeType.sink,
          calculationType: NodeCalculationType.flow,
          pressure: 100000,
          sinkFlow: 2,
          position: const Offset(550, 100)) // P4, сток с максимальным расходом
    ];

    // Определяем рёбра (трубопроводы)
    var edges = [
      Edge(
          startNodeId: nodes[0].id,
          endNodeId: nodes[1].id,
          diameter: 0.1,
          length: 10,
          roughness: 0.0001), // Q01
      Edge(
          startNodeId: nodes[1].id,
          endNodeId: nodes[2].id,
          diameter: 0.1,
          length: 10,
          roughness: 0.0001), // Q12
      Edge(
          startNodeId: nodes[2].id,
          endNodeId: nodes[3].id,
          diameter: 0.1,
          length: 10,
          roughness: 0.0001,
          type: EdgeType.reducer,
          reducerTargetPressure: 1000000), // Q12
      Edge(
          startNodeId: nodes[3].id,
          endNodeId: nodes[4].id,
          diameter: 0.1,
          length: 10,
          roughness: 0.0001), // Q23
      Edge(
          startNodeId: nodes[4].id,
          endNodeId: nodes[5].id,
          diameter: 0.1,
          length: 10,
          roughness: 0.0001), // Q34
    ];
    _graph = GasNetwork(edges: edges, nodes: nodes);
    this.edges = _graph.edges;
    this.nodes = _graph.nodes;
  }

  // Задаем параметры газа
  @observable
  double viscosity = 0.000011; // Вязкость газа в Па·с
  @observable
  double molarMass = 0.016; //кг/моль
  @observable
  double zFactor = 0.9981; //фактор сжимаемости
  @observable
  double epsilon = 1e-1; // Допустимая погрешность
  @observable
  double universalGasConstant = 8.314; // Дж/(моль·К)
  @observable
  double specificHeat = 2483;

  @observable
  double? maxFlow;
  @observable
  double? maxTemperature;
  @observable
  double? maxPressure;
  @observable
  Map<Offset, List<Node>> magneticGrid = {};

  @observable
  CalculateStatus calculateStatus = CalculateStatus.complete;

  late GasNetwork _graph;
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
    final start = DateTime.now();

    try {
      await _graph.calculateGasNetwork(
        epsilon: epsilon,
        viscosity: viscosity,
        zFactor: zFactor,
        molarMass: molarMass,
        universalGasConstant: universalGasConstant,
        specificHeat: specificHeat,
      );

      updateEdgesAndNodesState();
      maxFlow = 0;
      maxTemperature = 0;
      maxPressure = 0;
      for (var e in edges) {
        if (maxFlow! < e.flow) maxFlow = e.flow;
        if (maxTemperature! < e.temperature) maxTemperature = e.temperature;
        if (maxPressure! < e.pressure) maxPressure = e.pressure;
      }
      edges.sort((f, s) => f.flow.abs() < s.flow.abs() ? 1 : 0);
      maxFlow = edges.firstOrNull?.flow.abs();
    } on Exception catch (e) {
      print(e);
    } finally {
      calculateStatus = CalculateStatus.complete;
      final end = DateTime.now();
      print(end.difference(start));
    }
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
    } else if (element is Node) {
      if (_lastCreatedNodeIdForEdgeTool == null) {
        lastCreatedNodeForEdgeTool = element;
        _lastCreatedNodeIdForEdgeTool = element.id;
      } else {
        _graph.link(_lastCreatedNodeIdForEdgeTool!, element.id, 0.1, 5, 0.0001);
        _lastCreatedNodeIdForEdgeTool = null;
        lastCreatedNodeForEdgeTool = null;
      }
    }
    updateEdgesAndNodesState();
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
  Future<void> exportToFile() async {
    FileManager.writeGasNetwork(_graph, 'gas_network');
  }

  @action
  Future<void> clear() async {
    _graph = GasNetwork(nodes: [], edges: []);
    selectedElementIds.clear();
    updateEdgesAndNodesState();
  }

  @action
  Future<void> loadFromFile() async {
    final graph = await FileManager.getGraphFromFile();
    if (graph != null) {
      _graph = graph;
      _graph.removeLoopEdges();
      selectedElementIds.clear();
      updateEdgesAndNodesState();
    }
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
    final newEdge = _graph.link(p1.id, p2.id, diam, 5, 0.0001);
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

  void rotateEdge(Edge edge) {
    _graph.rotateEdge(edge);
    updateEdgesAndNodesState();
  }
}

enum ToolType {
  edge('Участок'),
  node('Узел');

  const ToolType(this.value);

  final String value;
}

enum CalculateStatus {
  complete,
  process,
}
