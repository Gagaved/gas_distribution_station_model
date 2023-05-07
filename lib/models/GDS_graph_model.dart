import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

extension MyFancyList<T> on List<T> {
  bool isInside(T elem) => where((element) => elem == element).isNotEmpty;

  bool isNotInside(T elem) => where((element) => elem == element).isEmpty;
}

class GraphPipeline {
  Map<int, GraphPoint> points = {};
  Map<String, GraphEdge> edges = {};
  GraphPoint? sourcePoint; //(S) источник потока
  GraphPoint? sinkPoint; //(T) сток потока
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
  void link(GraphPoint p1, GraphPoint p2, double maxFlow) {
    var newEdge = GraphEdge(maxFlow, p1, p2);
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
        link(targetPoint, p, oldEdge.throughputFlow);
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
      {bool isSource = false,
      double sourceFlow = 0,
      bool isSink = false,
      required Offset position}) {
    var newPoint = GraphPoint(position);
    if (isSource) {
      newPoint.sourceFlow = sourceFlow;
      newPoint.isSource = true;
      sourcePoint = newPoint;
    }
    if (isSink) {
      sinkPoint = newPoint;
      newPoint.isSink = true;
    }
    points[newPoint.id] = newPoint;
    return newPoint;
  }

  ///
  ///
  /// done?
  void distributeFlow() {
    for (var point in points.values) {
      point.flow = 0;
    }
    for (var edge in edges.values) {
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
      }
      return resultList;
    }

    ///
    /// Рекурсивная функция распределения потока.
    /// done?
    double distributeFlowRecurrent(
        GraphPoint point, double flow, List<GraphPoint> way) {
      ///проверка на посещеную вершину (избегаем случая прохода по вершине несколько раз)
      if (way.isInside(point)) {
        return flow;
      }

      /// для точки потребления:
      if (point.isSink) {
        getEdgeBy2Points(point, way.last)!.flow += flow;
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
        double n = availableDestinations.length.toDouble();
        //double flowOptimal = flowDebt / n;
        for (GraphPoint desitonation in availableDestinations) {
          double forwardedFlow;
          GraphEdge edge = getEdgeBy2Points(point, desitonation)!;

          ///
          if (edge.flowDirection == point) {
            if (edge.throughputFlow + edge.flow >= flowOptimal) {
              forwardedFlow = flowDebt * edge.throughputFlow/sumThroughputFlow;
            } else {
              forwardedFlow = edge.throughputFlow + edge.flow;
            }
          } else {
            if (edge.throughputFlow - edge.flow >= flowOptimal) {
              forwardedFlow = flowOptimal;
            } else {
              forwardedFlow = edge.throughputFlow - edge.flow;
            }
          }

          ///

          List<GraphPoint> newWay = []
            ..addAll(way)
            ..add(point);
          double remainder =
              distributeFlowRecurrent(desitonation, forwardedFlow, newWay);
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
      if (!point.isSource) {
        GraphEdge lastEdge = getEdgeBy2Points(point, way.last)!;
        if (lastEdge.flowDirection == point ||lastEdge.flowDirection==null) {
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

    distributeFlowRecurrent(sourcePoint!, sourcePoint!.sourceFlow, []);
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
  bool isSource = false;
  double flow = 0;
  double sourceFlow = 0; // производимое sourcePoint значение потока
  bool isSink = false;
  Offset position;
}

class GraphEdge {
  int id = GraphPipeline.generateId();
  GraphPoint? reverseFlowDirection(){
    if(flowDirection ==p1){
      flowDirection =p2;
      return flowDirection;
    }else if(flowDirection ==p2){
      flowDirection=p1;
      return flowDirection;
    }
    return null;
  }
  GraphPoint p1;
  GraphPoint p2;

  ///точка в которую двигается поток flow, null, когда flow = 0;
  GraphPoint? flowDirection;

  GraphEdge(this.throughputFlow, this.p1, this.p2);

  double throughputFlow;
  double flow = 0;
//Offset p1;
//Offset p2;
}
