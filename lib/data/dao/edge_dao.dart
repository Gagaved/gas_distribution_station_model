import 'package:floor/floor.dart';
import 'package:gas_distribution_station_model/data/entities/edge.dart';
@dao
abstract class EdgeDAO{
  @Query("SELECT * FROM Edge")
  Future<List<Edge>> getAllEdges();

  @Query("SELECT * FROM Edge WHERE id=:id")
  Future<List<Edge>> getEdgeById(int id);

  @Query("DELETE FROM Edge")
  Future<void> deleteAllEdges();


  @insert
  Future<void> insertEdge(Edge edge);

  @insert
  Future<void> insertEdges(List<Edge> edges);

  @update
  Future<void> updateEdge(Edge edge);

  @delete
  Future<void> deleteEdge(Edge edge);

}