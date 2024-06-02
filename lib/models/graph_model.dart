// import 'dart:isolate';
// import 'dart:math';
// import 'dart:ui';
//
// import 'package:gas_distribution_station_model/data/entities/edge.dart';
// import 'package:gas_distribution_station_model/data/entities/point.dart';
// import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
// import 'package:tuple/tuple.dart';
//
// extension MyFancyList<T> on List<T> {
//   bool isInside(T elem) => where((element) => elem == element).isNotEmpty;
//
//   bool isNotInside(T elem) => where((element) => elem == element).isEmpty;
// }
//
// class GraphPipeline {
//   static GraphPipeline _singleton = GraphPipeline._internal();
//
//   factory GraphPipeline() {
//     return _singleton;
//   }
//
//   GraphPipeline._internal();
//
//   static const double gasDensity = 0.657;
//   Map<int, GraphPoint> points = {};
//   Map<String, GraphEdge> edges = {};
//
//   GraphPipeline.fromPointsAndEdges(List<Point> pointsDB, List<Edge> edgesDB) {
//     for (var pointDB in pointsDB) {
//       points[pointDB.id] = GraphPoint.fromPoint(pointDB);
//       _lastId = max(pointDB.id, _lastId);
//     }
//     for (var edgeDB in edgesDB) {
//       String key =
//           "${min(edgeDB.p1id, edgeDB.p2id)}-${max(edgeDB.p1id, edgeDB.p2id)}";
//       edges[key] = GraphEdge.fromEdge(edge: edgeDB, graphPipeline: this);
//       edges[key]!.p1.points.add(edges[key]!.p2);
//       edges[key]!.p2.points.add(edges[key]!.p1);
//     }
//     _singleton = this;
//   }
//
//   GraphEdge? getEdgeBy2Points(GraphPoint p1, GraphPoint p2) {
//     String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
//     return edges[key];
//   }
//
//   ///
//   ///
//   ///возвращает все ребра с которыми соеденена точка
//   List<GraphEdge> getEdgesByPoint(GraphPoint p) {
//     List<GraphEdge> list = [];
//     for (var point in p.points) {
//       var edge = getEdgeBy2Points(p, point);
//       if (edge != null) {
//         list.add(edge);
//       } else {
//         throw Exception("retard");
//       }
//     }
//     return list;
//   }
//
//   ///
//   ///
//   ///удаляет ребро по двум точкам
//   removeEdgeBy2Points(GraphPoint p1, GraphPoint p2) {
//     String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
//     edges.remove(key);
//     p1.points.remove(p2);
//     p2.points.remove(p1);
//   }
//
//   ///
//   ///
//   ///удаляет точку
//   removePoint(GraphPoint p) {
//     for (var point in p.points) {
//       point.points.remove(p);
//       removeEdgeBy2Points(p, point);
//     }
//     points.remove(p.id);
//   }
//
//   ///
//   ///
//   /// связывает две точки
//   GraphEdge link(GraphPoint p1, GraphPoint p2, double diam,
//       PipelineElementType type, double len,
//       [double sourceFlow = 0.0]) {
//     var newEdge = GraphEdge(
//         graphPipeline: this,
//         diam: diam,
//         p1id: p1.id,
//         p2id: p2.id,
//         typeId: type.index,
//         len: len,
//         id: generateId());
//     String key = "${min(p1.id, p2.id)}-${max(p1.id, p2.id)}";
//     if (p1.points.isNotInside(p2)) {
//       p1.points.add(p2);
//     }
//     ;
//     if (p2.points.isNotInside(p1)) {
//       p2.points.add(p1);
//     }
//     ;
//     edges[key] = newEdge;
//     if (type == PipelineElementType.source) {
//       p1.pressure = newEdge.pressure;
//       p2.pressure = newEdge.pressure;
//     }
//     return newEdge;
//   }
//
//   ///
//   ///
//   /// возвращает объедененную вершину
//   GraphPoint mergePoints(GraphPoint basePoint, GraphPoint targetPoint) {
//     removeEdgeBy2Points(basePoint, targetPoint);
//     List<GraphPoint> basePoints = [...basePoint.points];
//     for (var p in basePoints) {
//       if (targetPoint.points.isNotInside(p)) {
//         GraphEdge oldEdge = getEdgeBy2Points(basePoint, p)!;
//         link(targetPoint, p, oldEdge.diam, oldEdge.type, oldEdge.sourceFlow);
//         removeEdgeBy2Points(basePoint, p);
//       }
//     }
//     removePoint(basePoint);
//     return targetPoint;
//   }
//
//   ///
//   ///
//   /// Добавляет новую вершину в граф
//   GraphPoint addPoint(
//       {double sourceFlow = 0, bool isSink = false, required Offset position}) {
//     var newPoint = GraphPoint(
//         id: generateId(), positionX: position.dx, positionY: position.dy);
//     points[newPoint.id] = newPoint;
//     return newPoint;
//   }
//
//   GraphPoint? getPointById(int id) {
//     return points[id];
//   }
// }
//
// class GraphPoint extends Point {
//   Offset get position {
//     return Offset(positionX, positionY);
//   }
//
//   set position(Offset offset) {
//     positionX = offset.dx;
//     positionY = offset.dy;
//   }
//
//   GraphPoint(
//       {required super.id, required super.positionX, required super.positionY});
//
//   GraphPoint.fromPoint(Point point)
//       : super(
//             id: point.id,
//             positionY: point.positionY,
//             positionX: point.positionX);
// }
//
// class GraphEdge extends Edge {
//   double targetFlow = 0;
//
//   GraphEdge.fromEdge({required Edge edge, required this.graphPipeline})
//       : super(
//             id: edge.id,
//             diam: edge.diam,
//             len: edge.diam,
//             p1id: edge.p1id,
//             p2id: edge.p2id,
//             typeId: edge.typeId) {
//     p1 = graphPipeline!.getPointById(p1id)!;
//     p2 = graphPipeline!.getPointById(p2id)!;
//     type = PipelineElementType.values[typeId];
//   }
//
//   GraphEdge(
//       {required super.id,
//       required super.p1id,
//       required super.p2id,
//       required super.typeId,
//       required super.diam,
//       required super.len,
//       required this.graphPipeline}) {
//     p1 = graphPipeline!.getPointById(p1id)!;
//     p2 = graphPipeline!.getPointById(p2id)!;
//     type = PipelineElementType.values[typeId];
//   }
//
//   GraphPipeline? graphPipeline;
//   late GraphPoint p1;
//   late GraphPoint p2;
//
//   late PipelineElementType type;
//
//   ///
//   /// источник потока
//   double sourceFlow = 0;
//
//   ///
//   /// мощность нагревателя
//   double? heaterPower = 000;
//
//   double flow = 0;
//
//   Edge toEdgeDB() {
//     return Edge(
//         id: id,
//         p1id: p1.id,
//         p2id: p2.id,
//         typeId: type.index,
//         diam: diam,
//         len: len);
//   }
// }
