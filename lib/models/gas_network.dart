import 'dart:isolate';
import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'pipeline_element_type.dart';

part 'gas_network.mapper.dart';
part 'gas_network_calculator.dart';

@MappableClass()
final class GasNetwork with GasNetworkMappable {
  List<Node> nodes;
  List<Edge> edges;

  Future<void> calculateGasNetwork({
    required double epsilon,
    required double viscosity,
    required double zFactor,
    required double molarMass,
    required double universalGasConstant,
    required double specificHeat,
  }) async {
    _clear();
    final result = await Isolate.run(() =>
        GasNetworkCalculator(nodesList: nodes, edgesList: edges).calculate(
            epsilon: epsilon,
            viscosity: viscosity,
            zFactor: zFactor,
            molarMass: molarMass,
            universalGasConstant: universalGasConstant,
            specificHeat: specificHeat));
    nodes = result.$1;
    edges = result.$2;
  }

  Node nodeById(String id) {
    return nodes.firstWhere((element) => element.id == id);
  }

  void _clear() {
    for (var edge in edges) {
      edge._reducerConductanceCoefficient = 1;
      edge.flow = 0;
      edge._frictionFactor = null;
      edge._conductance = 0.0;
      edge.temperature = 293.15;
      edge.isAdorize = false;
    }
    for (var node in nodes) {
      if (node.type == NodeType.base || node.type == NodeType.sink) {
        node.pressure = 101000;
        node.temperature = 293.15;
      }
    }
  }

  GraphElement? getElementById(String id) {
    return [...nodes, ...edges]
        .where((element) => element.id == id)
        .firstOrNull;
  }

  GasNetwork({required this.nodes, required this.edges});
  // Конструктор из точек и ребер
  factory GasNetwork.fromPointsAndEdges(List<Node> nodes, List<Edge> edges) {
    return GasNetwork(nodes: nodes, edges: edges);
  }

  void removeLoopEdges() {
    edges.removeWhere((edge) => edge.startNodeId == edge.endNodeId);
  }

  // Удаление ребра по двум точкам
  void removeEdgeBy2Points(Node first, Node second) {
    edges.removeWhere((edge) =>
        (edge.startNodeId == first.id && edge.endNodeId == second.id) ||
        (edge.startNodeId == second.id && edge.endNodeId == first.id));
  }

  // Удаление ребра по двум точкам
  bool removeEdge(Edge edge) => edges.remove(edge);

  // Добавление новой вершины в граф
  Node addNode(Offset position) {
    var newNode = Node(position: position);
    nodes.add(newNode);
    return newNode;
  }

  // Связывание двух вершин ребром
  Edge link(String startNodeId, String endNodeId, double diameter,
      double length, double roughness) {
    var newEdge = Edge(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      diameter: diameter,
      length: length,
      roughness: roughness,
    );
    edges.add(newEdge);
    return newEdge;
  }

  // Объединение двух вершин
  Node mergePoints(Node basePoint, Node targetPoint) {
    for (var edge in edges) {
      if (edge.startNodeId == basePoint.id) {
        edge.startNodeId = targetPoint.id;
      }
      if (edge.endNodeId == basePoint.id) {
        edge.endNodeId = targetPoint.id;
      }
    }
    nodes.remove(basePoint);
    return targetPoint;
  }

  bool canRemoveNode(Node node) {
    return (edges
        .where(
            (edge) => edge.startNodeId == node.id || edge.endNodeId == node.id)
        .isEmpty);
  }

  bool removeNode(Node graphElement) {
    return (canRemoveNode(graphElement)) ? nodes.remove(graphElement) : false;
  }

  void rotateEdge(Edge edge) {
    final String endNodeId = edge.endNodeId;
    edge.endNodeId = edge.startNodeId;
    edge.startNodeId = endNodeId;
  }
}

@MappableClass()
sealed class GraphElement {
  static const Uuid _uuid = Uuid();
  final String id;

  GraphElement({String? id}) : id = id ?? GraphElement._uuid.v1();
}

@MappableClass()
class Edge extends GraphElement with EdgeMappable {
  String startNodeId;
  String endNodeId;

  /// Диаметр трубы (ребра) в метрах
  double diameter;

  /// Длина трубы (ребра) в метрах
  double length;

  /// Шероховатость внутренней поверхности трубы (ребра)
  double roughness;

  double _conductance;

  double? _frictionFactor;

  bool withoutConductance;

  /// Коэффициент проводимости для расчета потока газа через ребро
  double get conductance => withoutConductance ? 1 : _conductance;

  /// Расход газа через ребро, вычисляется в процессе расчета
  double flow;

  String get flowEndNodeId => flow >= 0 ? endNodeId : startNodeId;
  String get flowStartNodeId => flow >= 0 ? startNodeId : endNodeId;

  double get flowPerHour => flow * 3600;

  double temperature;
  bool adorizerOn;
  bool isAdorize;

  ///Мощность нагревателя Ватт
  double heaterPower;

  ///кпд нагревателя
  double heaterEfficiency;

  ///only for heater
  double maxHeaterPower;

  /// Процент открытия крана на этом участке,
  /// влияет только если EdgeType.valve или EdgeType.percentageValve
  /// 0 <= percentageValve <= 1
  double _percentageValve;

  double get percentageValve => _percentageValve;
  double valvePowConductanceCoefficient;
  double reducerTargetPressure;
  double _reducerConductanceCoefficient = 1.0;

  double get reducerConductanceCoefficient => _reducerConductanceCoefficient;

  double _pressure;

  ///только для информации, не учавствует в расчетах.
  double get pressure => _pressure;

  set reducerConductanceCoefficient(double value) {
    _reducerConductanceCoefficient = max(min(1, value), 0);
  }

  ///только для нагревателя
  bool heaterOn = false;

  set percentageValve(double value) {
    _percentageValve = min(max(value, 0), 1);
  }

  EdgeType type;

  Edge({
    required this.startNodeId,
    required this.endNodeId,
    required this.diameter,
    required this.length,
    required this.roughness,
    super.id,
    this.type = EdgeType.segment,
    this.reducerTargetPressure = 0,
    this.valvePowConductanceCoefficient = 2,
    double? percentageValve,
    this.temperature = 293.15,
    this.heaterPower = 0,
    this.maxHeaterPower = 0,
    this.heaterOn = false,
    this.heaterEfficiency = 0.8,
    this.flow = 0,
    this.isAdorize = false,
    this.adorizerOn = false,
    double pressure = 0,
    this.withoutConductance = false,
  })  : _conductance = 0.0,
        _percentageValve = percentageValve ?? 0,
        _pressure = pressure;
}

@MappableEnum()
enum NodeType {
  base('Точка'),
  sink('Сток'),
  source('Источник');

  const NodeType(this.value);

  final String value;
}

@MappableClass(includeCustomMappers: [OffsetMapper()])
class Node extends GraphElement with NodeMappable {
  /// Тип узла, только для визуальной части
  NodeType type;

  /// Давление в точке, задается вручную для NodeType.source,
  /// для остальных случаев расчитывается алгоримом
  /// В паскалях
  double _pressure;

  /// Давление в точке, задается вручную для NodeType.source,
  /// для остальных случаев расчитывается алгоримом
  /// В паскалях
  double get pressure => _pressure;

  /// Давление в точке, задается вручную для NodeType.source,
  /// для остальных случаев расчитывается алгоримом
  /// В паскалях
  set pressure(double value) {
    _pressure = max(value, 1);
  }

  ///
  /// Постоянный максимальный объемный расход газа точкой, только для NodeType.sink,
  /// В реальном мире отображает потребление газа на конце расчиваемой схемы. м^3/c
  double sinkFlow;

  /// Позиция точки в графе
  Offset position;

  double temperature;
  Node({
    super.id,
    this.type = NodeType.base,
    required this.position,
    double pressure = 0, //атмосферное давление
    this.sinkFlow = 0,
    this.temperature = 293.15,
  }) : _pressure = pressure;
}

class OffsetMapper extends SimpleMapper<Offset> {
  const OffsetMapper();

  @override
  Offset decode(dynamic value) {
    if (value is Map<String, dynamic>) {
      double dx = value['dx']?.toDouble() ?? 0.0;
      double dy = value['dy']?.toDouble() ?? 0.0;
      return Offset(dx, dy);
    } else {
      throw ArgumentError('Invalid value for decoding to Offset');
    }
  }

  @override
  dynamic encode(Offset self) {
    return {
      'dx': self.dx,
      'dy': self.dy,
    };
  }
}
