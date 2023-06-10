import 'dart:math';
import 'dart:ui';

import 'package:gas_distribution_station_model/data/entities/edge.dart';
import 'package:gas_distribution_station_model/data/entities/point.dart';
import 'package:gas_distribution_station_model/models/gds_element_type.dart';

extension MyFancyList<T> on List<T> {
  bool isInside(T elem) => where((element) => elem == element).isNotEmpty;

  bool isNotInside(T elem) => where((element) => elem == element).isEmpty;
}

class GraphPipeline {
  double GAS_DENSITY = 0.657;
   Map<int, GraphPoint> points = {};
   Map<String, GraphEdge> edges = {};

  GraphPipeline(List<Point> pointsDB, List<Edge> edgesDB){
    for(var pointDB in pointsDB){
      points[pointDB.id] = GraphPoint.fromDbPoint(pointDB);
      _lastId = max(pointDB.id,_lastId);
    }
    for(var edgeDB in edgesDB){
      String key = "${min(edgeDB.p1id,edgeDB.p2id)}-${max(edgeDB.p1id, edgeDB.p2id)}";
      edges[key] = GraphEdge(edgeDB.diam, points[edgeDB.p1id]!, points[edgeDB.p2id]!, GdsElementType.values[edgeDB.typeId]);
    }
  }

  GraphEdge? getEdgeBy2Points(GraphPoint p1, GraphPoint p2) {
    String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
    return edges[key];
  }


  ///
  ///
  ///возвращает все ребра с которыми соеденена точка
  List<GraphEdge> getEdgesByPoint(GraphPoint p) {
    List<GraphEdge> list = [];
    for (var point in p.points) {
      var edge = getEdgeBy2Points(p, point);
      if (edge != null) {
        list.add(edge);
      } else {
        throw Exception("retard");
      }
    }
    return list;
  }

  ///
  ///
  ///удаляет ребро по двум точкам
  removeEdgeBy2Points(GraphPoint p1, GraphPoint p2) {
    String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
    edges.remove(key);
    p1.points.remove(p2);
    p2.points.remove(p1);
  }

  ///
  ///
  ///удаляет точку
  removePoint(GraphPoint p) {
    for (var point in p.points) {
      point.points.remove(p);
      removeEdgeBy2Points(p, point);
    }
    points.remove(p.id);
  }

  ///
  ///
  /// связывает две точки
  void link(GraphPoint p1, GraphPoint p2, double diam, GdsElementType type,
      double len,
      [double sourceFlow = 0.0]) {
    var newEdge = GraphEdge(diam, p1, p2, type, len, sourceFlow);
    String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
    if (p1.points.isNotInside(p2)) {
      p1.points.add(p2);
    }
    ;
    if (p2.points.isNotInside(p1)) {
      p2.points.add(p1);
    }
    ;
    edges[key] = newEdge;
    if (type == GdsElementType.source) {
      p1.pressure = newEdge.pressure;
      p2.pressure = newEdge.pressure;
    }
  }

  ///
  ///
  /// возвращает объедененную вершину
  GraphPoint mergePoints(GraphPoint basePoint, GraphPoint targetPoint) {
    removeEdgeBy2Points(basePoint, targetPoint);
    List<GraphPoint> basePoints = []..addAll(basePoint.points);
    for (var p in basePoints) {
      if (targetPoint.points.isNotInside(p)) {
        GraphEdge oldEdge = getEdgeBy2Points(basePoint, p)!;
        link(targetPoint, p, oldEdge.diam, oldEdge.type, oldEdge.sourceFlow);
        removeEdgeBy2Points(basePoint, p);
      }
    }
    removePoint(basePoint);
    return targetPoint;
  }

  ///
  ///
  /// Добавляет новую вершину в граф
  GraphPoint addPoint(
      {double sourceFlow = 0, bool isSink = false, required Offset position}) {
    var newPoint = GraphPoint(generateId(),position);
    points[newPoint.id] = newPoint;
    return newPoint;
  }

  _calculateMinCrossSections(GraphPoint point, List<GraphPoint> way) {
    GraphEdge? lastEdge = getEdgeBy2Points(point, way[0]);
    List<GraphEdge> lockEdges = [lastEdge!];
    double minCross = lastEdge.crossSection;
    List<GraphPoint> destinations =
        _getAvailableDestinations(point, way, lockEdges);
    while (destinations.length == 1 && (point.points.length == 2)) {
      var edge = getEdgeBy2Points(point, destinations[0])!;
      point = destinations[0];
      lockEdges.add(edge);
      if (minCross > edge.crossSection) {
        minCross = edge.crossSection;
      }
      destinations = _getAvailableDestinations(point, way, lockEdges);
    }
    for (var edge in lockEdges) {
      edge.minCrossSectionOfThisPart = min(minCross,edge.minCrossSectionOfThisPart);
    }
  }

  ///
  ///
  /// done функция для получения ребер у точки, которые не входят в путь way, и не содержатся в lockEdges
  List<GraphPoint> _getAvailableDestinations(
      GraphPoint point, List<GraphPoint> way, List<GraphEdge> lockEdges) {
    var resultList = <GraphPoint>[];
    for (var destinationPoint in point.points) {
      if (way.isInside(destinationPoint)) continue;
      GraphEdge edge = getEdgeBy2Points(point, destinationPoint)!;
      if (lockEdges.isNotInside(edge)) {
        resultList.add(destinationPoint);
      }
    }
    return resultList;
  }

  ///
  /// Рекурсивная метод для распределения потока.
  /// done?
  double _distributeFlowRecurrent(
      GraphPoint point, double flow, List<GraphPoint> way) {
    GraphEdge? lastEdge =
        way.isNotEmpty ? getEdgeBy2Points(point, way.last)! : null;

    ///проверка на посещеную вершину (избегаем случая прохода по вершине несколько раз)
    if (way.isInside(point)) {
      return flow;
    }

    /// для точки потребления:
    if (lastEdge != null && lastEdge.type == GdsElementType.sink) {
      // if (edge.throughputFlow - edge.flow < forwardedFlow) {
      //       forwardedFlow = edge.throughputFlow - edge.flow;
      //    }
      double flow_p = flow;
      lastEdge.flow += flow_p;
      lastEdge.flowDirection = point;
      point.flow += flow_p;

      return flow - flow_p;
    }

    /// Для всех остальных точек:
    List<GraphEdge> lockEdges = [];
    double flowDebt = flow;
    List<GraphPoint> availableDestinations =
        _getAvailableDestinations(point, way, lockEdges);
    bool canDistributeDebtFlow = availableDestinations.isNotEmpty;
    while (canDistributeDebtFlow) {
      double oldFlowDebt = flowDebt;
      double n = availableDestinations.length.toDouble();
      double sumCrossSection = 0;
      for (var destination in availableDestinations) {
        var edge = getEdgeBy2Points(point, destination);
        _calculateMinCrossSections(destination, [point, destination]);
        sumCrossSection += edge!.minCrossSectionOfThisPart;
      }
      if(sumCrossSection==0){
        canDistributeDebtFlow = false;
        continue;
      }
      for (GraphPoint destination in availableDestinations) {
        double forwardedFlow;
        GraphEdge edge = getEdgeBy2Points(point, destination)!;
        forwardedFlow =
            oldFlowDebt * (edge.minCrossSectionOfThisPart / sumCrossSection);
        ///
        // if (edge.flowDirection == point) {
        //   if (edge.crossSection + edge.flow < forwardedFlow) {
        //     forwardedFlow = edge.throughputFlow + edge.flow;
        //   }
        // } else {
        //   if (edge.throughputFlow - edge.flow < forwardedFlow) {
        //     forwardedFlow = edge.throughputFlow - edge.flow;
        //   }
        // }

        List<GraphPoint> newWay = []
          ..addAll(way)
          ..add(point);
        double remainder =
            _distributeFlowRecurrent(destination, forwardedFlow, newWay);
        flowDebt -= (forwardedFlow - remainder);
        if (forwardedFlow - remainder != 0) {
          point.flowWays.add(FlowWay(newWay, forwardedFlow - remainder));
        }
      }
      availableDestinations = _getAvailableDestinations(point, way, lockEdges);
      if (availableDestinations.isEmpty ||
          (flowDebt * 100).toInt() == 0 ||
          oldFlowDebt == flowDebt) {
        canDistributeDebtFlow = false;
      }
    }

    /// Устанавливаем значение потока для точки и ребра
    point.flow += flow - flowDebt;
    if (lastEdge != null) {
      if (lastEdge.flowDirection == point || lastEdge.flowDirection == null) {
        lastEdge.flow += flow - flowDebt;
        lastEdge.flowDirection = point;
      } else {
        lastEdge.flow = lastEdge.flow - (flow - flowDebt);
        if (lastEdge.flow < 0) {
          lastEdge.reverseFlowDirection();
          lastEdge.flow = lastEdge.flow.abs();
        }
      }
    }

    return flowDebt;
  }

  void _calculatePressureRecurrent(
      GraphPoint point, double pressureFromLastEdge, List<GraphPoint> way) {
    GraphEdge? lastEdge =
        way.isNotEmpty ? getEdgeBy2Points(point, way.last)! : null;

    ///проверка на посещеную вершину (избегаем случая прохода по вершине несколько раз)
    if (way.isInside(point)) {
      return;
    }
    switch (lastEdge?.type) {
      case GdsElementType.reducer:
        {
          if (pressureFromLastEdge>lastEdge!.targetPressure) point.pressure = lastEdge!.targetPressure;
        }
        break;
      default:
        {
          late double coeffHydraulicFriction;
          double dynamicViscosityOfMethane = 1000;
          double kinematicviscosityofmethane = 14.3 * 10e-6;
          double reinoldsCoef = 0.0354 *
              lastEdge!.flow *
              3600 /
              (lastEdge!.diam * 100 * kinematicviscosityofmethane);
          if (reinoldsCoef < 100000) {
            coeffHydraulicFriction =
                1 / pow((1.821 * 9.81 * reinoldsCoef - 1.64), 2);
            //coeffHydraulicFriction = 0.3164 / pow(reinoldsCoef, 0.25);
          } else {
            coeffHydraulicFriction =
                1 / pow((1.821 * 9.81 * reinoldsCoef - 1.64), 2);
          }
          coeffHydraulicFriction =
              0.11 * pow((0.01 / lastEdge.diam * 100 + 68 / reinoldsCoef), 2);
          double newPressureValue = sqrt(-0.00012687 *
                      coeffHydraulicFriction *
                      (lastEdge!.flow * 3600) *
                      GAS_DENSITY *
                      lastEdge.len /
                      pow(lastEdge!.diam * 100, 5) +
                  pow(pressureFromLastEdge / 1000000, 2)) *
              1000000;
          if (newPressureValue > point.pressure) {
            point.pressure = newPressureValue;
          }
        }
    }
    lastEdge.pressure = point.pressure;

    if (lastEdge.type == GdsElementType.reducer) {}

    List<GraphEdge> lockEdges = [];
    List<GraphPoint> availableDestinations =
        _getAvailableDestinations(point, way, lockEdges);
    for (GraphPoint destination in availableDestinations) {
      GraphEdge edge = getEdgeBy2Points(point, destination)!;
      if (edge.flowDirection != destination) {
        continue;
      }
      List<GraphPoint> newWay = []
        ..addAll(way)
        ..add(point);
      _calculatePressureRecurrent(destination, point.pressure, newWay);
    }
  }

  ///
  ///
  ///функция распределения потока
  void distributeFlowAndCalculatePressure() {
    GraphEdge? sourceEdge;
    for (var point in points.values) {
      point.flow = 0;
      point.flowWays = [];
      point.pressure = 0;
    }
    for (var edge in edges.values) {
      if (edge.type == GdsElementType.source) {
        sourceEdge = edge;
        sourceEdge.p1.pressure = sourceEdge.pressure;
        sourceEdge.p2.pressure = sourceEdge.pressure;
      } else {
        edge.pressure = 0;
      }
      edge.flow = 0;
      edge.minCrossSectionOfThisPart = edge.crossSection;
    }
    _distributeFlowRecurrent(sourceEdge!.p1, sourceEdge.sourceFlow!, []);
    _calculatePressureRecurrent(
        sourceEdge!.p2, sourceEdge.pressure, [sourceEdge.p1]);
  }

  static int _lastId = 0;

  static int generateId() {
    _lastId += 1;
    return _lastId;
  }
}

class GraphPoint {

  List<GraphPoint> points = []; //точки связнные с this
  int id;

  ///
  /// давление в паскалях
  double pressure = 0;
  double flow = 0;
  Offset position;
  List<FlowWay> flowWays = [];

  GraphPoint(this.id,
  this.position,);

  static Point toPointDB(GraphPoint graphPoint) {
    return Point(id: graphPoint.id, positionX: graphPoint.position.dx, positionY: graphPoint.position.dy);
  }

  static GraphPoint fromDbPoint(Point pointDB) {
    return GraphPoint(pointDB.id,Offset(pointDB.positionX,pointDB.positionY));
  }
}

class FlowWay {
  FlowWay(this.way, this.flow);

  List<GraphPoint> way;
  double flow;
}

class GraphEdge {
  GraphEdge(this.diam, this.p1, this.p2, this.type,
      [this.len = 100, flow = 0.0]) {
    switch (type) {
      case GdsElementType.source:
        pressure = 10000000;
    }
    sourceFlow = flow;
    _crossSection = pi * pow(diam / 2, 2);
  }

  int id = GraphPipeline.generateId();
  GraphPoint p1;
  GraphPoint p2;

  ///
  /// давление в паскалях
  double pressure = 0;

  ///
  ///для редуктора... todo добавить возможноть изменять
  double targetPressure = 1200000;

  ///
  /// длина участка, в м
  double len;

  ///
  /// поперечное сечение участка в м^2
  double _crossSection = 0;

  double get crossSection => _crossSection * openPercentage;

  ///
  /// минимальное поперечное сечение среди всех участков от и до ближайших узловых точек
  double minCrossSectionOfThisPart = 0;

  ///
  /// процент открытия участка запорной или регулирующей армотурой
  double openPercentage = 1.0;

  ///
  ///точка в которую двигается поток flow, null, когда flow = 0;
  GraphPoint? flowDirection;

  ///
  ///точка откуда двигается поток flow, null, когда flow = 0;
  GraphPoint? get flowStart {
    if (flowDirection == null) {
      return null;
    }
    if (flowDirection == p1) {
      return p2;
    }
    return p1;
  }

  GdsElementType type;

  ///
  /// диаметр трубы
  double diam;

  ///
  /// источник потока
  double sourceFlow = 0;

  double flow = 0;

  void changeThroughputFlowPercentage(double value) {
    if (value > 1 || value < 0) {
      throw Exception(
          "Bad value changeThroughputFlowPercentage(), value:${value}");
    }
    openPercentage = value;
  }

  GraphPoint? reverseFlowDirection() {
    if (flowDirection == p1) {
      flowDirection = p2;
      return flowDirection;
    } else if (flowDirection == p2) {
      flowDirection = p1;
      return flowDirection;
    }
    return null;
  }

  Edge toEdgeDB() {
    return Edge(id: id, p1id: p1.id, p2id: p2.id, typeId: type.index, diam: diam, len: len);
  }
}
