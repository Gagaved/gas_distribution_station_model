import 'dart:math';

extension MyFancyList<T> on List<T> {
  bool isInside(T elem) => where((element) => elem == element).isNotEmpty;
}

class GraphPipeline {
  List<PipelinePoint> points = [];
  Map<String, PipelineEdge> edges = {};
  List<PipelinePoint> sourcePoints = []; //(S) источник потока
  List<PipelinePoint> sinkPoints = []; //(T) сток потока
  void link(double x, double y, PipelinePoint fromPoint, PipelinePoint toPoint,
      int maxFlow) {
    edges["${fromPoint.id}-${toPoint.id}"] =
        PipelineEdge(x, y, fromPoint, toPoint, maxFlow);
    fromPoint.childPoints.add(toPoint);
  }

  bool _depthSearch(PipelinePoint point, List<PipelineEdge> way) {
    bool wayIsExist = false;
    if (sinkPoints.isInside(point)) {
      //точка - сток
      var minPossibleFlow = (double.maxFinite).toInt();
      for (var element in way) {
        if (element.possibleFlow < minPossibleFlow) {
          minPossibleFlow = element.possibleFlow - element.flow;
        }
      }
      for (var edges in way) {
        edges.flow += minPossibleFlow;
      }
      return true;
    } else {
      for (var child in point.childPoints) {
        List<PipelineEdge> newWay = [...way];
        newWay.add(edges["${point.id}-${child.id}"]!);
        wayIsExist = _depthSearch(child, newWay);
      }
    }
    return wayIsExist;
  }

  bool _rebalanceFlowDepthSearch(
      PipelinePoint point, List<PipelineEdge> way, List<int> directions) {
    bool wayIsExist = false;
    if (sinkPoints.isInside(point)) {
      ///
      ///
      /// если точка - сток
      var minDiffFlow = (double.maxFinite).toInt();
      for (var edge in way) {
        var diffFlow = edge.possibleFlow - edge.flow;
        diffFlow = min(diffFlow, minDiffFlow);
        if (diffFlow <= 0) {
          throw Exception('Diff <=0');
        }
        for (int i = 0; i < way.length; i++) {
          way[i].flow += minDiffFlow * directions[i];
        }
        return true;
      }
    } else {
      for (var child in point.childPoints) {
        var edge = edges["${point.id}-${child.id}"]!;
        if (!way.isInside(edge)) {
          var diffFlow = edge.possibleFlow - edge.flow;
          if (diffFlow != 0) {
            List<PipelineEdge> newWay = [...way];
            List<int> newDirections = [...directions, 1];
            newWay.add(edges["${point.id}-${child.id}"]!);
            bool wayIsExist =
                _rebalanceFlowDepthSearch(child, newWay, newDirections);
            if (wayIsExist) {
              return wayIsExist;
            }
          }
        } else {
          continue;
        }
      }
      for (var parent in point.parentPoints) {
        var edge = edges["${parent.id}-${point.id}"]!;
        if (!way.isInside(edge)) {
          var divFlow = edge.possibleFlow - edge.flow;
          if (divFlow != 0) {
            List<PipelineEdge> newWay = [...way];
            List<int> newDirections = [...directions, -1];
            newWay.add(edges["${parent.id}-${point.id}"]!);
            bool wayIsExist =
                _rebalanceFlowDepthSearch(parent, newWay, directions);
            if (wayIsExist) {
              return wayIsExist;
            }
          }
        } else {
          continue;
        }
      }
    }
    return wayIsExist;
  }

  void flowFordFulkersonAlgorithm() {
    ///первоначальная балансировка. Поиск вглубину.
    bool balancingIsPossible = true;
    while (balancingIsPossible) {
      balancingIsPossible = _depthSearch(sourcePoints[0],
          []); //todo для нескольких точек стока и истока нуждно объеденять, пока доступно только для одной выхода и одного входа
    }

    bool rebalancingIsPossible = true;
    while (rebalancingIsPossible) {
      print("rebalancingIsPossible: ${rebalancingIsPossible}");
      rebalancingIsPossible =
          _rebalanceFlowDepthSearch(sourcePoints[0], [], []);
    }
  }
}

class PipelinePoint {
  PipelinePoint(
    this.id,
  );

  List<PipelinePoint> childPoints = []; //есть ребро из this в childPoints
  List<PipelinePoint> parentPoints = []; //есть ребро из parentPoints[i] в this
  int id;
}

class PipelineEdge {
  PipelineEdge(this.x, this.y, this.fromPoint, this.toPoint, this.possibleFlow);

  double x;
  double y;
  PipelinePoint fromPoint;
  PipelinePoint toPoint;
  int possibleFlow;
  int flow = 0;
}
