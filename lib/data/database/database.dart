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

  Future<void> replaceDBDataFromFile(String filename) async {
    await pointDAO.deleteAllPoints();
    await edgeDAO.deleteAllEdges();
    var data = FileManager.readPointsAndEdgesFromFile(filename);
    await pointDAO.insertPoints(data.item1);
    await edgeDAO.insertEdges(data.item2);
  }
  Future<void> writeDBDataToFile(String filename) async {
    var points = await pointDAO.getAllPoints();
    var edges = await edgeDAO.getAllEdges();
    FileManager.writePointsAndEdgesToFile(points,edges,filename);
  }
}
