import 'package:floor/floor.dart';
import 'package:gas_distribution_station_model/data/entities/point.dart';
@dao
abstract class PointDAO{
  @Query("SELECT * FROM Point")
  Future<List<Point>> getAllPoints();

  @Query("SELECT * FROM Point WHERE id=:id")
  Future<List<Point>> getPointById(int id);

  @Query("DELETE FROM Point")
  Future<void> deleteAllPoints();


  @insert
  Future<void> insertPoint(Point point);

  @insert
  Future<void> insertPoints(List<Point> points);


  @update
  Future<void> updatePoint(Point point);

  @delete
  Future<void> deletePoint(Point point);


}