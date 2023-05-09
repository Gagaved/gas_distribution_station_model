import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

import 'package:gas_distribution_station_model/models/gds_element_type.dart';

extension MyFancyList<T> on List<T> {
  bool isInside(T elem) => where((element) => elem == element).isNotEmpty;

  bool isNotInside(T elem) => where((element) => elem == element).isEmpty;
}

class GraphPipeline {
  Map<int, GraphPoint> points = {};
  Map<String, GraphEdge> edges = {};

  GraphEdge? getEdgeBy2Points(GraphPoint p1, GraphPoint p2) {
    String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
    return edges[key];
  }

  ///
  ///
  ///done
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
  ///done*
  removeEdgeBy2Points(GraphPoint p1, GraphPoint p2) {
    String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
    edges.remove(key);
    p1.points.remove(p2);
    p2.points.remove(p1);
  }

  ///
  ///
  ///done
  removePoint(GraphPoint p) {
    for (var point in p.points) {
      point.points.remove(p);
      removeEdgeBy2Points(p, point);
    }
    points.remove(p.id);
  }

  ///
  ///
  /// done
  void link(GraphPoint p1, GraphPoint p2, double maxFlow, GdsElementType type) {
    var newEdge = GraphEdge(maxFlow, p1, p2, type);
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
        link(targetPoint, p, oldEdge.throughputFlow, oldEdge.type);
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
    var newPoint = GraphPoint(position);
    points[newPoint.id] = newPoint;
    return newPoint;
  }

  ///
  ///
  /// done?
  void distributeFlow() {
    GraphEdge? sourceEdge;
    for (var point in points.values) {
      point.flow = 0;
    }
    for (var edge in edges.values) {
      if (edge.type == GdsElementType.source){
        sourceEdge = edge;
      }
      edge.flow = 0;
    }

    ///
    ///
    /// done функция для получения ребер у точки, по для которых допустимо применить функцию распределения
    List<GraphPoint> _getAvailableDestinationsForDistributeFlow(
        GraphPoint point, List<GraphPoint> way, List<GraphEdge> lockEdges) {
      var resultList = <GraphPoint>[];
      for (var destinationPoint in point.points) {
        if (way.isInside(destinationPoint)) continue;
        GraphEdge edge = getEdgeBy2Points(point, destinationPoint)!;
        if ((edge.throughputFlow - edge.flow).toInt() > 0.0 &&
            lockEdges.isNotInside(edge)) {
          resultList.add(destinationPoint);
        }
        //resultList.add(destinationPoint);
      }
      return resultList;
    }

    ///
    /// Рекурсивная функция распределения потока.
    /// done?
    double distributeFlowRecurrent(
        GraphPoint point, double flow, List<GraphPoint> way) {
      GraphEdge? lastEdge =
          way.isNotEmpty ? getEdgeBy2Points(point, way.last)! : null;

      ///проверка на посещеную вершину (избегаем случая прохода по вершине несколько раз)
      if (way.isInside(point)) {
        return flow;
      }

      /// для точки потребления:
      if (lastEdge != null && lastEdge.type == GdsElementType.sink) {
        lastEdge.flow += flow;
        point.flow += flow;
        return 0;
      }

      /// Для всех остальных точек:
      List<GraphEdge> lockEdges = [];
      double flowDebt = flow;
      List<GraphPoint> availableDestinations =
          _getAvailableDestinationsForDistributeFlow(point, way, lockEdges);
      bool canDistributeDebtFlow = availableDestinations.isNotEmpty;
      while (canDistributeDebtFlow) {
        double oldFlowDebt = flowDebt;
        double n = availableDestinations.length.toDouble();
        double sumThroughputFlow = 0;
        for (var destination in availableDestinations) {
          var edge = getEdgeBy2Points(point, destination);
          sumThroughputFlow += edge!.throughputFlow;
        }
        for (GraphPoint destination in availableDestinations) {
          double forwardedFlow;
          GraphEdge edge = getEdgeBy2Points(point, destination)!;
          forwardedFlow =
              oldFlowDebt * (edge.throughputFlow / sumThroughputFlow);

          ///
          if (edge.flowDirection == point) {
            if (edge.throughputFlow + edge.flow < forwardedFlow) {
              forwardedFlow = edge.throughputFlow + edge.flow;
            }
          } else {
            if (edge.throughputFlow - edge.flow < forwardedFlow) {
              forwardedFlow = edge.throughputFlow - edge.flow;
            }
          }

          ///

          List<GraphPoint> newWay = []
            ..addAll(way)
            ..add(point);
          double remainder =
              distributeFlowRecurrent(destination, forwardedFlow, newWay);
          flowDebt -= forwardedFlow - remainder;
          if (remainder != 0) {
            lockEdges.add(edge);
          }
        }
        availableDestinations =
            _getAvailableDestinationsForDistributeFlow(point, way, lockEdges);
        if (availableDestinations.isEmpty || flowDebt.toInt() == 0) {
          canDistributeDebtFlow = false;
        }
      }
      point.flow += flow - flowDebt;
      if (lastEdge != null ){
        //&& lastEdge.type != GdsElementType.source) {
        if (lastEdge.flowDirection == point ||
            lastEdge.flowDirection == null) {
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

    distributeFlowRecurrent(sourceEdge!.p1, sourceEdge.sourceFlow, []);
  }

  static int _lastId = 0;

  static int generateId() {
    _lastId += 1;
    return _lastId;
  }
}

class GraphPoint {
  GraphPoint(
    this.position,
  );

  List<GraphPoint> points = []; //точки связнные с this
  int id = GraphPipeline.generateId();
  double flow = 0;
  Offset position;
}

class GraphEdge {
  GraphEdge(this._throughputFlow, this.p1, this.p2, this.type){
   switch(type){
     case GdsElementType.source:
       sourceFlow = _throughputFlow;
   }
  }

  int id = GraphPipeline.generateId();
  GraphPoint p1;
  GraphPoint p2;

  ///точка в которую двигается поток flow, null, когда flow = 0;
  GraphPoint? flowDirection;

  GdsElementType type;
  double sourceFlow = 0; // производимое sourcePoint значение потока
  double _throughputFlow;

  double get throughputFlow => (_throughputFlow * _throughputFLowPercentage);

  set throughputFlow(double value) {
    _throughputFlow = value;
  }

  double _throughputFLowPercentage = 1.0;

  double get throughputFLowPercentage => _throughputFLowPercentage;
  double flow = 0;

  void changeThroughputFlowPercentage(double value) {
    if (value > 1 || value < 0) {
      throw Exception(
          "Bad value changeThroughputFlowPercentage(), value:${value}");
    }
    _throughputFLowPercentage = value;
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

}
