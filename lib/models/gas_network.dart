import 'dart:isolate';
import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'pipeline_element_type.dart';

part 'gas_network.mapper.dart';

@MappableClass()
final class GasNetwork with GasNetworkMappable {
  List<Node> nodes;
  List<Edge> edges;

  (List<Node>, List<Edge>) calculateFlowsAndPressures(
      double epsilon, double viscosity, double density) {
    bool hasConverged;
    int iteration = 0;
    _updateConductances(viscosity, density);
    do {
      hasConverged = true;
      for (var node in nodes) {
        if (node.type != NodeType.base) {
          continue;
        }

        var incomingEdges =
            edges.where((edge) => edge.endNodeId == node.id).toList();
        var outgoingEdges =
            edges.where((edge) => edge.startNodeId == node.id).toList();

        double prevPressure = node.pressure;

        double numerator = 0.0;
        double denominator = 0.0;

        for (var edge in incomingEdges) {
          numerator += edge.conductance *
              nodes.firstWhere((n) => n.id == edge.startNodeId).pressure;
          denominator += edge.conductance;
        }
        for (var edge in outgoingEdges) {
          numerator += edge.conductance *
              nodes.firstWhere((n) => n.id == edge.endNodeId).pressure;
          denominator += edge.conductance;
        }

        if (denominator > 0) {
          node.pressure = numerator / denominator;
        }

        if ((node.pressure - prevPressure).abs() > epsilon) {
          hasConverged = false;
        }
      }

      for (var edge in edges) {
        edge.flow = edge.conductance *
            (nodes.firstWhere((n) => n.id == edge.startNodeId).pressure -
                nodes.firstWhere((n) => n.id == edge.endNodeId).pressure);
      }

      // Обновляем давление в точке стока
      for (var node in nodes) {
        if (node.calculationType == NodeCalculationType.flow) {
          adjustPressureNodePressure(node);
        }
      }

      _updateConductances(viscosity, density);
      iteration++;
      print('Iteration $iteration:');
      for (var node in nodes) {
        print(
            'P${node.id} ${node.calculationType == NodeType.sink ? 'SINK' : ''} = ${node.pressure}');
      }
      for (var edge in edges) {
        print('Q${edge.startNodeId}${edge.endNodeId} = ${edge.flow}');
      }
    } while (!hasConverged && iteration < 10000);

    print('Converged after $iteration iterations.');
    for (var node in nodes) {
      print(
          'Final ${node.calculationType == NodeType.sink ? 'SINK' : ''} P${node.id} = ${node.pressure}');
    }
    for (var edge in edges) {
      print('Final Q${edge.startNodeId}-${edge.endNodeId} = ${edge.flow}');
    }
    return (nodes, edges);
  }

  void adjustPressureNodePressure(Node node) {
    // Проверяем, что переданная точка является точкой стока
    if (node.calculationType != NodeCalculationType.pressure) {
      throw ArgumentError('The provided node is not a sink node.');
    }

    // Находим все входящие ребра для этой точки стока
    var incomingEdges =
        edges.where((edge) => edge.endNodeId == node.id).toList();

    // Вычисляем сумму входящих потоков
    double totalIncomingFlow =
        incomingEdges.fold(0.0, (sum, edge) => sum + edge.flow);

    // Вычисляем коэффициент недостающего потока
    double missingFlowCoefficient = 1 - (node.sinkFlow / totalIncomingFlow);

    // Вычисляем дополнительное давление
    double additionalPressure = 0.0;
    for (var edge in incomingEdges) {
      var startNode = nodes.firstWhere((n) => n.id == edge.startNodeId);
      double pressureDifference = startNode.pressure - node.pressure;
      double edgeFlowContribution = edge.flow / totalIncomingFlow;
      additionalPressure += edgeFlowContribution * pressureDifference;
    }

    // Умножаем дополнительное давление на коэффициент недостающего потока
    additionalPressure *= missingFlowCoefficient;
    print('additionalPressure $additionalPressure');
    // Увеличиваем давление в точке
    node.pressure += additionalPressure;
  }

  Node nodeById(String id) {
    return nodes.firstWhere((element) => element.id == id);
  }

  GraphElement? getElementById(String id) {
    return [...nodes, ...edges]
        .where((element) => element.id == id)
        .firstOrNull;
  }

  GasNetwork({required this.nodes, required this.edges});

  void _clear() {
    for (var edge in edges) {
      edge.flow = 0;
      edge._conductance = 0.0;
    }
    for (var node in nodes) {
      if (node.type == NodeType.base) node.pressure = 101000;
    }
  }

  double calculateFrictionFactor({
    required double diameter,
    required double roughness,
    required double velocity,
    required double viscosity,
    double frictionFactor = 0.02, // Initial guess for friction factor
  }) {
    // Reynolds number: Re = (velocity * diameter) / viscosity
    double reynoldsNumber = (velocity * diameter) / viscosity;

    // Iteratively solve Colebrook-White equation
    if (reynoldsNumber > 4000) {
      for (int i = 0; i < 10; i++) {
        frictionFactor = 1.0 /
            pow(
                -2.0 *
                    log((roughness / (14.8 * (diameter / 4))) +
                        (2.51 / (reynoldsNumber * sqrt(frictionFactor)))),
                2);
      }
    } else {
      for (int i = 0; i < 10; i++) {
        frictionFactor = 1.0 /
            pow(
                -2.0 *
                    log((roughness / (3.7 * diameter)) +
                        (2.51 / (reynoldsNumber * sqrt(frictionFactor)))),
                2);
      }
    }

    return frictionFactor;
  }

  double calculateConductance(double diameter, double length, double roughness,
      double velocity, double viscosity, double density) {
    double frictionFactor = calculateFrictionFactor(
        diameter: diameter,
        roughness: roughness,
        velocity: velocity,
        viscosity: viscosity);
    double area = pi * pow(diameter, 2) / 4.0;
    double conductance =
        area * sqrt(2.0 / (frictionFactor * (length / diameter) * density));
    return conductance;
  }

  void _updateConductances(double viscosity, double density) {
    for (var edge in edges) {
      double velocity = max(1, edge.flow / (pi * pow(edge.diameter, 2) / 4));
      double baseConductance = calculateConductance(edge.diameter, edge.length,
          edge.roughness, velocity, viscosity, density);

      if (edge.type == EdgeType.valve ||
          edge.type == EdgeType.percentageValve) {
        edge._conductance = baseConductance *
            pow(edge.percentageValve, edge.valvePowConductanceCoefficient);
        print('ce to ${edge._conductance}');
      } else if (edge.type == EdgeType.reducer) {
        Node startNode = nodes.firstWhere((n) => n.id == edge.startNodeId);
        Node endNode = nodes.firstWhere((n) => n.id == edge.endNodeId);

        double pressureDifference =
            endNode.pressure - edge.reducerTargetPressure;
        double conductanceCoefficient = (pressureDifference > 0)
            ? 1.0
            : pow(1 + (pressureDifference.abs() / edge.reducerTargetPressure),
                    2)
                .toDouble();
        edge._conductance = baseConductance * conductanceCoefficient;
        print(
            'baseConductance $baseConductance * reducerConductanceCoefficient $conductanceCoefficient = \n'
            '${edge._conductance}');
        edge._conductance = baseConductance;
      } else {
        edge._conductance = baseConductance;
      }
    }
  }

  Future<void> calculateGasNetwork(
      double epsilon, double viscosity, double density) async {
    final result = await Isolate.run(() {
      _clear();
      return calculateFlowsAndPressures(epsilon, viscosity, density);
    });
    nodes = result.$1;
    edges = result.$2;
  }

  // Конструктор из точек и ребер
  factory GasNetwork.fromPointsAndEdges(List<Node> nodes, List<Edge> edges) {
    return GasNetwork(nodes: nodes, edges: edges);
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

  /// Коэффициент проводимости для расчета потока газа через ребро
  double get conductance => _conductance;

  /// Расход газа через ребро, вычисляется в процессе расчета
  double flow = 0.0;

  double get flowPerHour => flow * 3600;

  /// Процент открытия крана на этом участке,
  /// влияет только если EdgeType.valve или EdgeType.percentageValve
  /// 0 <= percentageValve <= 1
  double _percentageValve = 0;

  double get percentageValve => _percentageValve;
  double valvePowConductanceCoefficient = 2;
  double reducerTargetPressure = 0;
  double get reducerConductance => _reducerConductance;
  double _reducerConductance = 0.0;

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
  }) : _conductance = 0.0;
}

@MappableEnum()
enum NodeType {
  base('Точка'),
  sink('Сток'),
  source('Источник');

  const NodeType(this.value);

  final String value;
}

@MappableEnum()
enum NodeCalculationType {
  flow('Поток'),
  pressure('Давление');

  const NodeCalculationType(this.value);

  final String value;
}

@MappableClass(includeCustomMappers: [OffsetMapper()])
class Node extends GraphElement with NodeMappable {
  /// Тип узла, только для визуальной части
  NodeType _type;

  /// Тип узла, только для визуальной части
  NodeType get type => _type;

  /// Тип узла, только для визуальной части
  set type(NodeType value) {
    _type = value;
    if (value != NodeType.base) {
      calculationType = calculationType ?? NodeCalculationType.pressure;
    }
  }

  ///не null только для type = sink or source
  NodeCalculationType? calculationType;

  /// Давление в точке, задается вручную для NodeType.source,
  /// для остальных случаев расчитывается алгоримом
  /// В паскалях
  double pressure;

  ///
  /// Постоянный максимальный объемный расход газа точкой, только для NodeType.sink,
  /// В реальном мире отображает потребление газа на конце расчиваемой схемы. м^3/c
  double sinkFlow;

  /// Позиция точки в графе
  Offset position;

  Node({
    super.id,
    NodeType type = NodeType.base,
    this.calculationType = NodeCalculationType.pressure,
    required this.position,
    this.pressure = 0, //атмосферное давление
    this.sinkFlow = 0,
  }) : _type = type;
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
