part of 'gas_network.dart';

class OptimizeNode {
  final Set<String> incomingEdgesIds;
  final Set<String> outcomesEdgesIds;
  final Node node;
  OptimizeNode({
    required this.node,
    required this.incomingEdgesIds,
    required this.outcomesEdgesIds,
  });
}

class GasNetworkCalculator {
  late final Map<String, Edge> edgesMap;
  late final Map<String, OptimizeNode> nodesMap;
  GasNetworkCalculator({
    required List<Node> nodesList,
    required List<Edge> edgesList,
  }) {
    edgesMap = {for (var e in edgesList) e.id: e};
    nodesMap = {
      for (var e in nodesList)
        e.id: OptimizeNode(
            node: e,
            incomingEdgesIds: edgesList
                .where((edge) => edge.endNodeId == e.id)
                .map((ed) => ed.id)
                .toSet(),
            outcomesEdgesIds: edgesList
                .where((edge) => edge.startNodeId == e.id)
                .map((ed) => ed.id)
                .toSet()),
    };
  }
  (List<Node>, List<Edge>) calculate({
    required double epsilon,
    required double viscosity,
    required double zFactor,
    required double molarMass,
    required double universalGasConstant,
    required double specificHeat,
  }) {
    bool innerConverged;
    int innerIteration = 0;
    _updateConductances(
      zFactor: zFactor,
      viscosity: viscosity,
      universalGasConstant: universalGasConstant,
      molarMass: molarMass,
    );
    for (var node in nodesMap.values) {
      if (node.node.type != NodeType.source) {
        node.node.pressure = 101000;
      }
    }
    do {
      innerConverged = true;
      for (var node in nodesMap.values) {
        if (node.node.type != NodeType.base) {
          continue;
        }

        double prevPressure = node.node.pressure;

        double numerator = 0.0;
        double denominator = 0.0;

        for (var edgeId in node.incomingEdgesIds) {
          final edge = edgesMap[edgeId]!;
          numerator +=
              edge.conductance * nodesMap[edge.startNodeId]!.node.pressure;
          denominator += edge.conductance;
        }
        for (var edgeId in node.outcomesEdgesIds) {
          final edge = edgesMap[edgeId]!;
          numerator +=
              edge.conductance * nodesMap[edge.endNodeId]!.node.pressure;
          denominator += edge.conductance;
        }

        if (denominator > 0 && denominator.isFinite && numerator.isFinite) {
          node.node.pressure = numerator / denominator;
        }

        if ((node.node.pressure - prevPressure).abs() > epsilon) {
          innerConverged = false;
        }
      }

      for (var edge in edgesMap.values) {
        final firstNode = nodesMap[edge.startNodeId]!;
        final secondNode = nodesMap[edge.endNodeId]!;
        edge.flow = edge.conductance *
            (firstNode.node.pressure - secondNode.node.pressure);
        edge.temperature = _calculateEdgeTemperature(edge, specificHeat);
      }

      // Обновляем давление в точке стока
      for (var node in nodesMap.values) {
        if (node.node.type == NodeType.sink && node.node.sinkFlow != 0) {
          _adjustPressureNodePressure(node);
        }
        if (node.node.type != NodeType.source) {
          final newNodeTemp = _calculateNodeTemperature(node);
          node.node.temperature = newNodeTemp;
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
      for (var node in nodesMap.values) {
        print(
            'Final ${node.node.type == NodeType.sink ? 'SINK' : ''} P${node.node.id} = ${node.node.pressure}, T = ${node.node.temperature}');
      }
      for (var edge in edgesMap.values) {
        print(
            'Final Q${edge.startNodeId}-${edge.endNodeId} = ${edge.flow}, T = ${edge.temperature}');
      }
      print('Final iterations $innerIteration');
    }
    _adorize();
    _addPressureToEdges();
    return (
      nodesMap.values.map((e) => e.node).toList(),
      edgesMap.values.toList()
    );
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
  double _calculateEdgeTemperature(Edge edge, specificHeat) {
    double temperatureDrop = 0;

    // Эффект Джоуля-Томсона

    final flowEndNode = nodesMap[edge.flowEndNodeId]!;
    final flowStartNode = nodesMap[edge.flowStartNodeId]!;
    double result = flowStartNode.node.temperature;
    if (edge.type == EdgeType.reducer) {
      temperatureDrop =
          (flowStartNode.node.pressure - flowEndNode.node.pressure) *
              1e-5; // Примерный коэффициент
    }
    result -= temperatureDrop;
    if (edge.type == EdgeType.heater &&
        edge.heaterOn &&
        edge.flow.isFinite &&
        edge.flow != 0) {
      double heaterTemperatureIncrease = edge.heaterPower *
          edge.heaterEfficiency /
          (edge.flow.abs() * specificHeat);
      result += heaterTemperatureIncrease;
    }
    return result;
  }

  double _calculateNodeTemperature(OptimizeNode node) {
    double denominator = 0.0;

    final connectedEdges = [...node.outcomesEdgesIds, ...node.incomingEdgesIds]
        .where((edgeId) {
          final edge = edgesMap[edgeId]!;
          return ((edge.endNodeId == node.node.id ||
                  edge.startNodeId == node.node.id) &&
              edge.flow != 0 &&
              edge.flowEndNodeId == node.node.id);
        })
        .map((id) => edgesMap[id]!)
        .toList();

    for (var edge in connectedEdges) {
      denominator += edge.flow.abs();
    }
    double numerator = 0;
    for (var edge in connectedEdges) {
      numerator += edge.flow.abs() * edge.temperature;
    }
    if (denominator != 0 && denominator.isFinite && denominator.isFinite) {
      final result = numerator / denominator;
      return result;
    } else {
      return node.node.temperature;
    }
  }

  void _adjustPressureNodePressure(OptimizeNode node) {
    // Проверяем, что переданная точка является точкой стока
    if (node.node.type != NodeType.sink) {
      throw ArgumentError('The provided node is not a sink node.');
    }

    // Вычисляем суммы входящих и исходящих потоков
    double totalFlow = 0.0;

    for (var edgeId in [...node.incomingEdgesIds, ...node.outcomesEdgesIds]) {
      totalFlow += edgesMap[edgeId]!.flow;
    }

    // Вычисляем коэффициент недостающего потока
    double overFlow = (totalFlow - node.node.sinkFlow);
    final additionalPressure = overFlow / node.node.sinkFlow;
    // if (kDebugMode) {
    //   print('additionalPressure $additionalPressure');
    // }
    // Увеличиваем давление в точке
    node.node.pressure += additionalPressure;
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

  double _calculateConductance(double diameter, double length, double roughness,
      double velocity, double viscosity, double density, Edge edge) {
    double frictionFactor = calculateFrictionFactor(
        diameter: diameter,
        roughness: roughness,
        velocity: velocity,
        viscosity: viscosity,
        frictionFactor: edge._frictionFactor ?? 0.02);
    double area = pi * pow(diameter, 2) / 4.0;
    edge._frictionFactor = frictionFactor;
    double conductance =
        area * sqrt(2.0 / (frictionFactor * (length / diameter) * density));
    return conductance;
  }

  void _updateConductances(
      {required double zFactor,
      required double viscosity,
      required double molarMass,
      required double universalGasConstant}) {
    for (var edge in edgesMap.values) {
      double velocity = max(1, edge.flow / (pi * pow(edge.diameter, 2) / 4));

      final density = calculateDensity(
        temperature: edge.temperature,
        pressure: nodesMap[edge.startNodeId]!.node.pressure,
        zFactor: zFactor,
        universalGasConstant: universalGasConstant,
        molarMass: molarMass,
      );

      double baseConductance = _calculateConductance(edge.diameter, edge.length,
          edge.roughness, velocity, viscosity, density, edge);

      if (edge.type == EdgeType.valve ||
          edge.type == EdgeType.percentageValve) {
        edge._conductance = baseConductance *
            pow(edge.percentageValve, edge.valvePowConductanceCoefficient);
        // print('_conductance to ${edge._conductance}');
      } else if (edge.type == EdgeType.reducer) {
        const double adjustmentFactor =
            1; // Фактор шага для регулировки коэффициента
        const double minAdjustment = 1e-6; // Минимальная величина корректировки

        final startNode = nodesMap[edge.startNodeId]!.node;
        final endNode = nodesMap[edge.endNodeId]!.node;

        if (startNode.pressure > endNode.pressure) {
          //Вычисляем целевой коэффициент проводимости редуктора
          final targetConductanceCoefficient =
              edge.reducerConductanceCoefficient *
                  1 /
                  (endNode.pressure / edge.reducerTargetPressure);

          // Вычисляем разницу между текущим и целевым коэффициентом проводимости
          // if (kDebugMode) {
          //   print(
          //       "cal:${targetConductanceCoefficient - edge.reducerConductanceCoefficient}");
          // }
          final conductanceDifference =
              targetConductanceCoefficient - edge.reducerConductanceCoefficient;

          // Плавная корректировка текущего коэффициента с учетом разницы
          edge.reducerConductanceCoefficient +=
              adjustmentFactor * conductanceDifference;
          if (kDebugMode) {
            //Ограничиваем минимальную величину корректировки
            // if (edge.reducerConductanceCoefficient.abs() < minAdjustment) {
            //   //edge.reducerConductanceCoefficient = minAdjustment;
            //   print('WARN');
            // }

            // print(
            //     'Updated reducerConductanceCoefficient: ${edge.reducerConductanceCoefficient}');
          }
        }
        edge._conductance =
            baseConductance * edge._reducerConductanceCoefficient;
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
      final node = nodesMap[nodeId]!.node;
      var connectedEdges = edgesMap.values
          .where((edge) =>
              ((edge.endNodeId == node.id || edge.startNodeId == node.id) &&
                  edge.flowEndNodeId != node.id))
          .toList();
      for (final edge in connectedEdges) {
        edge.isAdorize = true;
        if (edge.flow != 0) {
          visit(edge.flowEndNodeId);
        }
      }
    }

    for (final edge in edgesMap.values.where((edge) =>
        edge.type == EdgeType.adorizer && edge.flow != 0 && edge.adorizerOn)) {
      edge.isAdorize = true;
      visit(edge.flowEndNodeId);
    }
  }

  _addPressureToEdges() {
    for (final edge in edgesMap.values) {
      edge._pressure = nodesMap[edge.flowEndNodeId]!.node.pressure;
    }
  }
}
