import 'dart:isolate';
import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'pipeline_element_type.dart';

part 'gas_network.mapper.dart';

@MappableClass()
sealed class GraphElement {
  static const Uuid _uuid = Uuid();
  final String id;
  GraphElement() : id = GraphElement._uuid.v1();
}

@MappableClass()
class Edge extends GraphElement with EdgeMappable {
  String startNodeId;
  String endNodeId;
  double diameter; // Диаметр трубы (ребра) в метрах
  double length; // Длина трубы (ребра) в метрах
  double roughness; // Шероховатость внутренней поверхности трубы (ребра)
  double _conductance;

  double get conductance =>
      _conductance; // Коэффициент проводимости для расчета потока газа через ребро
  double flow = 0.0; // Расход газа через ребро, вычисляется в процессе расчета

  PipelineEdgeType type;

  Edge(
    this.startNodeId,
    this.endNodeId,
    this.diameter,
    this.length,
    this.roughness, {
    this.type = PipelineEdgeType.segment,
  }) : _conductance = 0.0;
}

@MappableClass()
class Node extends GraphElement with NodeMappable {
  double _pressure; // Давление в узле (точке) в Паскалях

  double get pressure => _pressure;
  bool _isSource;

  bool get isSource => _isSource;
  bool _isSink;

  bool get isSink => _isSink;

  Offset position;

  Node.source({required this.position, required double pressure})
      : _pressure = pressure,
        _isSource = true,
        _isSink = false;

  Node.sink({
    required this.position,
  })  : _pressure = 0,
        _isSource = false,
        _isSink = true;

  Node({
    bool isSource = false,
    bool isSink = false,
    required this.position,
  })  : _isSink = isSink,
        _isSource = isSource,
        _pressure = 0; // Давление по умолчанию - 0 Паскалей;
}

@MappableClass()
final class GasNetwork with GasNetworkMappable {
  List<Node> nodes;
  List<Edge> edges;
  Node nodeById(String id) {
    return nodes.firstWhere((element) => element.id == id);
  }

  getElementById(String id) {
    return [...nodes, ...edges].firstWhere((element) => element.id == id);
  }

  GasNetwork({required this.nodes, required this.edges});

  double calculateFrictionFactor(
      double diameter, double roughness, double velocity, double viscosity) {
    double reynoldsNumber = (velocity * diameter) / viscosity;
    double frictionFactor = 0.02; // Initial guess for friction factor

    for (int i = 0; i < 10; i++) {
      frictionFactor = 1.0 /
          pow(
              -2.0 *
                  log(roughness / (3.7 * diameter) +
                      2.51 / (reynoldsNumber * sqrt(frictionFactor))),
              2);
    }

    return frictionFactor;
  }

  double calculateConductance(double diameter, double length, double roughness,
      double velocity, double viscosity, double density) {
    double frictionFactor =
        calculateFrictionFactor(diameter, roughness, velocity, viscosity);
    double area = pi * pow(diameter, 2) / 4.0;
    double conductance =
        area * sqrt(2.0 / (frictionFactor * (length / diameter) * density));
    return conductance;
  }

  void updateConductances(double viscosity, double density) {
    for (var edge in edges) {
      double velocity =
          1.0; // Предположительное значение скорости, нужно определить более точно
      edge._conductance = calculateConductance(edge.diameter, edge.length,
          edge.roughness, velocity, viscosity, density);
    }
  }

  void calculateFlowsAndPressures(
      double epsilon, double viscosity, double density) {
    bool hasConverged;
    int iteration = 0;

    do {
      hasConverged = true;
      for (var node in nodes) {
        if (node.isSource || node.isSink) {
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
          node._pressure = numerator / denominator;
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

      iteration++;
      print('Iteration $iteration:');
      for (var node in nodes) {
        print('P${node.id} = ${node.pressure}');
      }
      for (var edge in edges) {
        print('Q${edge.startNodeId}${edge.endNodeId} = ${edge.flow}');
      }
    } while (!hasConverged);

    print('Converged after $iteration iterations.');
    for (var node in nodes) {
      print('Final P${node.id} = ${node.pressure}');
    }
    for (var edge in edges) {
      print('Final Q${edge.startNodeId}${edge.endNodeId} = ${edge.flow}');
    }
  }

  Future<void> calculateGasNetwork(
      double epsilon, double viscosity, double density) async {
    await Isolate.run(() {
      updateConductances(viscosity, density);
      calculateFlowsAndPressures(epsilon, viscosity, density);
    });
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
  void removeEdge(Edge edge) {
    edges.remove(edge);
  }

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
      startNodeId,
      endNodeId,
      diameter,
      length,
      roughness,
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

  void removeNode(Node graphElement) {}
}

void main() {
  // Определяем узлы
  var nodes = [
    Node.source(
        pressure: 50.0,
        position: const Offset(0, 0)), // P0, источник с постоянным давлением
    Node(position: const Offset(1, 0)), // P1
    Node(position: const Offset(2, 0)), // P2
    Node(position: const Offset(3, 0)), // P3
    Node.sink(position: const Offset(4, 0)) // P4, сток с максимальным расходом
  ];

  // Определяем рёбра (трубопроводы)
  var edges = [
    Edge(nodes[0].id, nodes[1].id, 0.1, 100, 0.0001), // Q01
    Edge(nodes[1].id, nodes[2].id, 0.1, 100, 0.0001), // Q12
    Edge(nodes[1].id, nodes[3].id, 0.1, 100, 0.0001), // Q13
    Edge(nodes[2].id, nodes[3].id, 0.1, 100, 0.0001), // Q23
    Edge(nodes[3].id, nodes[4].id, 0.1, 100, 0.0001), // Q34
  ];

  // Задаем параметры газа
  double viscosity = 0.0000181; // Вязкость газа в Па·с
  double density = 1.225; // Плотность газа в кг/м³
  double epsilon = 1e-6; // Допустимая погрешность

  // Создаем сеть
  var network = GasNetwork.fromPointsAndEdges(nodes, edges);

  // Обновляем кондуктивности рёбер
  network.updateConductances(viscosity, density);

  // Рассчитываем давления и расходы
  network.calculateFlowsAndPressures(epsilon, viscosity, density);
}
