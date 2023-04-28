import 'dart:ffi';
import 'dart:math';

extension MyFancyList<T> on List<T> {
  bool isInside(T elem) => where((element) => elem == element).isNotEmpty;

  bool isNotInside(T elem) => where((element) => elem == element).isEmpty;
}

class GraphPipeline {
  List<PipelinePoint> points = [];
  Map<String, PipelineEdge> edges = {};

  PipelinePoint? sourcePoint; //(S) источник потока
  PipelinePoint? sinkPoint; //(T) сток потока
  void link(double x, double y, PipelinePoint fromPoint, PipelinePoint toPoint,
      int maxFlow) {
    var newEdge = PipelineEdge(x, y, fromPoint, toPoint, maxFlow);
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
    var newPoint = PipelinePoint(_generateId());
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
    List<PipelineEdge> lockEdges = [];

    ///
    ///
    /// функция для получения ребер у точки, по для которых допустимо применить функцию распределения
    List<PipelineEdge> _getAvailableEdgesForDistributeFlow(
        PipelinePoint point) {
      var resultList = <PipelineEdge>[];
      for (PipelineEdge edge in point.edgesFromPoint) {
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
        PipelinePoint point, double flow, PipelineEdge? parentEdge) {
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
      List<PipelineEdge> availableEdges =
      _getAvailableEdgesForDistributeFlow(point);
      bool canDistributeDebtFlow = availableEdges.isNotEmpty;
      while (canDistributeDebtFlow) {
        double n = availableEdges.length.toDouble();
        double flowOptimal = flowDebt / n;
        for (PipelineEdge edge in availableEdges) {
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

class PipelinePoint {
  PipelinePoint(
      this.id,
      );

  List<PipelineEdge> edgesFromPoint = []; //есть ребро из this в childPoints
  List<PipelineEdge> edgesToPoint = []; //есть ребро из parentPoints[i] в this
  int id;
  bool isSource = false;
  double flow = 0;
  double sourceFlow = 0; // производимое sourcePoint значение потока
  bool isSink = false;
}

class PipelineEdge {
  PipelineEdge(
      this.x, this.y, this.fromPoint, this.toPoint, this.throughputFlow);

  double x;
  double y;
  PipelinePoint fromPoint;
  PipelinePoint toPoint;
  int throughputFlow;
  double flow = 0;
}
