import 'dart:convert';
import 'dart:io';
import 'package:gas_distribution_station_model/data/entities/edge.dart';
import 'package:gas_distribution_station_model/data/entities/point.dart';

class FileManager {
  static List<Point> parsePoints(List<dynamic> pointsJson) {
    return pointsJson.map((json) => Point.fromJson(json)).toList();
  }

  static List<Edge> parseEdges(List<dynamic> edgesJson) {
    return edgesJson.map((json) => Edge.fromJson(json)).toList();
  }

  static File writePointsAndEdgesToFile(List<Point> points, List<Edge> edges, String filename) {
    final data = {
      'points': points.map((point) => point.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
    };
    final jsonString = jsonEncode(data);
    final file = File(filename);
    file.writeAsStringSync(jsonString);
    return file;
  }

  static (List<Point>, List<Edge>) readPointsAndEdgesFromFile(File file) {
    final jsonString = file.readAsStringSync();
    final data = jsonDecode(jsonString);
    final List<dynamic> pointsJson = data['points'];
    final List<dynamic> edgesJson = data['edges'];
    final List<Point> points = parsePoints(pointsJson);
    final List<Edge> edges = parseEdges(edgesJson);
    return (points, edges);
  }
}