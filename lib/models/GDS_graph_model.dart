import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

extension MyFancyList<T> on List<T> {
  bool isInside(T elem) => where((element) => elem == element).isNotEmpty;

  bool isNotInside(T elem) => where((element) => elem == element).isEmpty;
}

class GraphPipeline {
  List<GraphPoint> points = [];
  Map<String, GraphEdge> edges = {};

  GraphPoint? sourcePoint; //(S) источник потока
  GraphPoint? sinkPoint; //(T) сток потока
  void link(Offset p1, Offset p2, GraphPoint fromPoint, GraphPoint toPoint,
      int maxFlow) {
    var newEdge = GraphEdge(fromPoint, toPoint, maxFlow,p1,p2);
    edges["${fromPoint.id}-${toPoint.id}"] = newEdge;

    fromPoint.edgesFromPoint.add(newEdge);
    toPoint.edgesToPoint.add(newEdge);
  }

  int _lastId = 0;

  int _generateId() {
    _lastId += 1;
    return _lastId;
  }

  void addPoint(
      {bool isSource = false, double sourceFlow = 0, bool isSink = false}) {
    var newPoint = GraphPoint(_generateId());
    if (isSource) {
      newPoint.sourceFlow = sourceFlow;
      newPoint.isSource = true;
      sourcePoint = newPoint;
    }
    if (isSink) {
      sinkPoint = newPoint;
      newPoint.isSink = true;
    }
    points.add(newPoint);
  }

  void distributeFlow() {
    ///
    ///
    /// Список ребер по которым уже нельзя пропустить новый поток.
    List<GraphEdge> lockEdges = [];

    ///
    ///
    /// функция для получения ребер у точки, по для которых допустимо применить функцию распределения
    List<GraphEdge> _getAvailableEdgesForDistributeFlow(
        GraphPoint point) {
      var resultList = <GraphEdge>[];
      for (GraphEdge edge in point.edgesFromPoint) {
        if ((edge.throughputFlow - edge.flow ).toInt()> 0 &&
            lockEdges.isNotInside(edge)) {
          resultList.add(edge);
        }
      }
      return resultList;
    }

    ///
    ///
    /// Рекурсивная функция распределения потока.
    double distributeFlowRecurrent(
        GraphPoint point, double flow, GraphEdge? parentEdge) {
      ///
      ///
      /// для точки потребления:
      if (point.isSink) {
        parentEdge!.flow +=
            flow;
        point.flow += flow;
        return 0;
      }

      ///
      ///
      /// Для всех остальных точек:
      double flowDebt = flow;
      List<GraphEdge> availableEdges =
          _getAvailableEdgesForDistributeFlow(point);
      bool canDistributeDebtFlow = availableEdges.isNotEmpty;
      while (canDistributeDebtFlow) {
        double n = availableEdges.length.toDouble();
        double flowOptimal = flowDebt / n;
        if(n==3){
          print('object');
        }
        for (GraphEdge edge in availableEdges) {
          double forwardedFlow;
          if (edge.throughputFlow - edge.flow >= flowOptimal) {
            forwardedFlow = flowOptimal;
          } else {
            forwardedFlow = edge.throughputFlow - edge.flow;
          }
          double remainder =
              distributeFlowRecurrent(edge.toPoint, forwardedFlow, edge);
          flowDebt -= forwardedFlow - remainder;
          if (remainder != 0) {
            lockEdges.add(edge);
          }
        }
        availableEdges = _getAvailableEdgesForDistributeFlow(point);
        if (availableEdges.isEmpty || flowDebt.toInt() == 0) {
          canDistributeDebtFlow = false;
        }
      }
      if (parentEdge != null) {
        //проверка на source точку
        parentEdge.flow += flow - flowDebt;
      }
      point.flow += flow - flowDebt;
      return flowDebt;
    }
    distributeFlowRecurrent(sourcePoint!, sourcePoint!.sourceFlow, null);
  }
}

class GraphPoint {
  GraphPoint(
    this.id,
  );

  List<GraphEdge> edgesFromPoint = []; //есть ребро из this в childPoints
  List<GraphEdge> edgesToPoint = []; //есть ребро из parentPoints[i] в this
  int id;
  bool isSource = false;
  double flow = 0;
  double sourceFlow = 0; // производимое sourcePoint значение потока
  bool isSink = false;
}

class GraphEdge {
  GraphEdge(
      this.fromPoint, this.toPoint, this.throughputFlow,this.p1,this.p2);
  GraphPoint fromPoint;
  GraphPoint toPoint;
  int throughputFlow;
  double flow = 0;
  Offset? p1;
  Offset? p2;
}
