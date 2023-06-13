import 'dart:io';

import 'package:floor/floor.dart';
import 'package:gas_distribution_station_model/data/dao/edge_dao.dart';
import 'package:gas_distribution_station_model/data/dao/point_dao.dart';
import 'package:gas_distribution_station_model/data/entities/edge.dart';
import 'package:gas_distribution_station_model/data/entities/point.dart';
import 'package:gas_distribution_station_model/data/util/FileManager.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart';

@Database(version: 1, entities: [Edge, Point])
abstract class AppDatabase extends FloorDatabase {
  PointDAO get pointDAO;

  EdgeDAO get edgeDAO;

  Future<void> replaceDBDataFromFile(File file) async {
    await pointDAO.deleteAllPoints();
    await edgeDAO.deleteAllEdges();
    var (points,edges) = FileManager.readPointsAndEdgesFromFile(file);
    await pointDAO.insertPoints(points);
    await edgeDAO.insertEdges(edges);
  }
  Future<File> writeDBDataToFile(String filename) async {
    var points = await pointDAO.getAllPoints();
    var edges = await edgeDAO.getAllEdges();
    return FileManager.writePointsAndEdgesToFile(points,edges,filename);
  }
}
