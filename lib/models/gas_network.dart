import 'dart:isolate';
import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'pipeline_element_type.dart';

part 'gas_network.mapper.dart';

@MappableClass()
final class GasNetwork with GasNetworkMappable {
  List<Node> nodes;
  List<Edge> edges;

  (List<Node>, List<Edge>) calculate({
    required double epsilon,
    required double viscosity,
    required double zFactor,
    required double molarMass,
    required double universalGasConstant,
    required double specificHeat,
    //required List<Node> nodes;
  }) {
    bool innerConverged;
    int innerIteration = 0;
    _clear();
    _updateConductances(
      zFactor: zFactor,
      viscosity: viscosity,
      universalGasConstant: universalGasConstant,
      molarMass: molarMass,
    );
    for (var node in nodes) {
      if (node.calculationType == NodeCalculationType.flow) {
        node.pressure = 101000;
      }
    }
    do {
      innerConverged = true;
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
          innerConverged = false;
        }
      }

      for (var edge in edges) {
        final firstNode = nodes.firstWhere((n) => n.id == edge.startNodeId);
        final secondNode = nodes.firstWhere((n) => n.id == edge.endNodeId);
        edge.flow =
            edge.conductance * (firstNode.pressure - secondNode.pressure);
        edge.temperature = _calculateEdgeTemperature(
            edge, firstNode, secondNode, specificHeat);
      }

      // Обновляем давление в точке стока
      for (var node in nodes) {
        if (node.calculationType == NodeCalculationType.flow) {
          _adjustPressureNodePressure(node);
        }
        if (node.type != NodeType.source) {
          node.temperature = _calculateNodeTemperature(node);
        }
      }

      _updateConductances(
          zFactor: zFactor,
          viscosity: viscosity,
          molarMass: molarMass,
          universalGasConstant: universalGasConstant);
      innerIteration++;
    } while (!innerConverged);
    if (kDebugMode) {
      print('Converged after $innerIteration iterations.');
      for (var node in nodes) {
        print(
            'Final ${node.calculationType == NodeType.sink ? 'SINK' : ''} P${node.id} = ${node.pressure}, T = ${node.temperature}');
      }
      for (var edge in edges) {
        print(
            'Final Q${edge.startNodeId}-${edge.endNodeId} = ${edge.flow}, T = ${edge.temperature}');
      }
      print('Final iterations $innerIteration');
    }
    _adorize();
    return (nodes, edges);
  }

  double calculateDensity({
    required double temperature,
    required double universalGasConstant,
    required double zFactor,
    required double molarMass,
    required double pressure,
  }) {
    final density =
        (pressure * molarMass) / (zFactor * universalGasConstant * temperature);
    return density;
  }

  // Функция для расчета температуры на ребре
  double _calculateEdgeTemperature(
      Edge edge, Node startNode, Node endNode, specificHeat) {
    double temperatureDrop = 0;
    double result = 0;
    // Эффект Джоуля-Томсона

    if (edge.type == EdgeType.reducer) {
      temperatureDrop = (startNode.pressure - endNode.pressure) * 1e-5;
    } // Примерный коэффициент
    result = startNode.temperature - temperatureDrop;
    if (edge.type == EdgeType.heater && edge.heaterOn) {
      double heaterTemperatureIncrease =
          edge.heaterPower * edge.heaterEfficiency / (edge.flow * specificHeat);
      result += heaterTemperatureIncrease;
    }
    return result;
  }

  double _calculateNodeTemperature(Node node) {
    double denominator = 0.0;
    var connectedEdges = edges
        .where((edge) =>
            (edge.endNodeId == node.id && edge.flow > 0) ||
            (edge.startNodeId == node.id && edge.flow < 0))
        .toList();
    for (var edge in connectedEdges) {
      denominator += edge.flow.abs();
    }
    double numerator = 0;
    for (var edge in connectedEdges) {
      numerator += edge.flow.abs() * edge.temperature;
    }
    if (denominator != 0) {
      final result = numerator / denominator;
      return result;
    } else {
      return node.temperature;
    }
  }

  void _adjustPressureNodePressure(Node node) {
    // Проверяем, что переданная точка является точкой стока
    if (node.calculationType != NodeCalculationType.flow) {
      throw ArgumentError('The provided node is not a sink node.');
    }

    // Находим все входящие и исходящие ребра для этой точки
    var connectedEdges = edges
        .where(
            (edge) => edge.startNodeId == node.id || edge.endNodeId == node.id)
        .toList();

    // Вычисляем суммы входящих и исходящих потоков
    double totalFlow = 0.0;

    for (var edge in connectedEdges) {
      if (edge.endNodeId == node.id) {
        //totalIncomingFlow += edge.flow;
      } else if (edge.startNodeId == node.id) {
        //totalOutgoingFlow += edge.flow;
      }
      totalFlow += edge.flow;
    }

    // Вычисляем коэффициент недостающего потока
    double overFlow = (totalFlow - node.sinkFlow);
    final additionalPressure = overFlow / node.sinkFlow * 10;
    if (kDebugMode) {
      print('additionalPressure $additionalPressure');
    }

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
      edge._reducerConductanceCoefficient = 1;
      edge.flow = 0;
      edge._conductance = 0.0;
      edge.temperature = 293.15;
      edge.isAdorize = false;
    }
    for (var node in nodes) {
      if (node.type == NodeType.base ||
          node.type == NodeType.sink &&
              node.calculationType == NodeCalculationType.flow) {
        node.pressure = 101000;
        node.temperature = 293.15;
      }
    }
  }

  double calculateFrictionFactor({
    required double diameter,
    required double roughness,
    required double velocity,
    required double viscosity,
    double frictionFactor = 0.02, // Initial guess for friction factor
  }) {
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

  void removeLoopEdges() {
    edges.removeWhere((edge) => edge.startNodeId == edge.endNodeId);
  }

  double _calculateConductance(double diameter, double length, double roughness,
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

  void _updateConductances(
      {required double zFactor,
      required double viscosity,
      required double molarMass,
      required double universalGasConstant}) {
    for (var edge in edges) {
      double velocity = max(1, edge.flow / (pi * pow(edge.diameter, 2) / 4));

      final density = calculateDensity(
        temperature: edge.temperature,
        pressure:
            nodes.firstWhere((node) => node.id == edge.startNodeId).pressure,
        zFactor: zFactor,
        universalGasConstant: universalGasConstant,
        molarMass: molarMass,
      );

      double baseConductance = _calculateConductance(edge.diameter, edge.length,
          edge.roughness, velocity, viscosity, density);

      if (edge.type == EdgeType.valve ||
          edge.type == EdgeType.percentageValve) {
        edge._conductance = baseConductance *
            pow(edge.percentageValve, edge.valvePowConductanceCoefficient);
        // print('_conductance to ${edge._conductance}');
      } else if (edge.type == EdgeType.reducer) {
        const double adjustmentFactor =
            1; // Фактор шага для регулировки коэффициента
        const double minAdjustment = 1e-6; // Минимальная величина корректировки

        final startNode =
            nodes.firstWhere((node) => node.id == edge.startNodeId);
        final endNode = nodes.firstWhere((node) => node.id == edge.endNodeId);

        if (startNode.pressure > endNode.pressure) {
          //Вычисляем целевой коэффициент проводимости редуктора
          final targetConductanceCoefficient =
              edge.reducerConductanceCoefficient *
                  1 /
                  (endNode.pressure / edge.reducerTargetPressure);

          // Вычисляем разницу между текущим и целевым коэффициентом проводимости
          if (kDebugMode) {
            print(
                "cal:${targetConductanceCoefficient - edge.reducerConductanceCoefficient}");
          }
          final conductanceDifference =
              targetConductanceCoefficient - edge.reducerConductanceCoefficient;

          // Плавная корректировка текущего коэффициента с учетом разницы
          edge.reducerConductanceCoefficient +=
              adjustmentFactor * conductanceDifference;
          if (kDebugMode) {
            //Ограничиваем минимальную величину корректировки
            if (edge.reducerConductanceCoefficient.abs() < minAdjustment) {
              //edge.reducerConductanceCoefficient = minAdjustment;
              print('WARN');
            }

            print(
                'Updated reducerConductanceCoefficient: ${edge.reducerConductanceCoefficient}');
          }
        }
        edge._conductance =
            baseConductance * pow(edge._reducerConductanceCoefficient, 2);
      } else {
        edge._conductance = baseConductance;
      }
    }
  }

  _adorize() {
    Set<String> visitedNodes = {};
    void visit(String nodeId) {
      if (visitedNodes.contains(nodeId)) return;
      visitedNodes.add(nodeId);
      final node = nodes.firstWhere((node) => node.id == nodeId);
      var connectedEdges = edges
          .where((edge) =>
              ((edge.endNodeId == node.id || edge.startNodeId == node.id) &&
                  edge.flowDirectionNodeId != node.id))
          .toList();
      for (final edge in connectedEdges) {
        edge.isAdorize = true;
        if (nodeId != edge.startNodeId) visit(edge.startNodeId);
        if (nodeId != edge.endNodeId) visit(edge.endNodeId);
      }
    }

    for (final edge in edges.where((edge) =>
        edge.type == EdgeType.adorizer && edge.flow != 0 && edge.adorizerOn)) {
      edge.isAdorize = true;
      visit(edge.flowDirectionNodeId);
    }
  }

  Future<void> calculateGasNetwork({
    required double epsilon,
    required double viscosity,
    required double zFactor,
    required double molarMass,
    required double universalGasConstant,
    required double specificHeat,
  }) async {
    final result = await Isolate.run(() => calculate(
        epsilon: epsilon,
        viscosity: viscosity,
        zFactor: zFactor,
        molarMass: molarMass,
        universalGasConstant: universalGasConstant,
        specificHeat: specificHeat));
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

  /// Коэффициент проводимости для расчета потока газа через ребро
  double get conductance => _conductance;

  /// Расход газа через ребро, вычисляется в процессе расчета
  double flow;

  String get flowDirectionNodeId => flow >= 0 ? endNodeId : startNodeId;

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
  })  : _conductance = 0.0,
        _percentageValve = percentageValve ?? 0;
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
  double _pressure;

  /// Давление в точке, задается вручную для NodeType.source,
  /// для остальных случаев расчитывается алгоримом
  /// В паскалях
  double get pressure => _pressure;

  /// Давление в точке, задается вручную для NodeType.source,
  /// для остальных случаев расчитывается алгоримом
  /// В паскалях
  set pressure(double value) {
    _pressure = max(value, 0.0);
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
    NodeType type = NodeType.base,
    this.calculationType = NodeCalculationType.pressure,
    required this.position,
    double pressure = 0, //атмосферное давление
    this.sinkFlow = 0,
    this.temperature = 293.15,
  })  : _pressure = pressure,
        _type = type;
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
