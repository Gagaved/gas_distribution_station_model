import 'package:floor/floor.dart';
@entity
class Edge {
  @PrimaryKey(autoGenerate: false)
  final int id;
  final int p1id;
  final int p2id;
  final int typeId;
  final double diam;
  final double len;

  Edge({
    required this.id,
    required this.p1id,
    required this.p2id,
    required this.typeId,
    required this.diam,
    required this.len,
  });

  factory Edge.fromJson(Map<String, dynamic> json) {
    return Edge(
      id: json['id'],
      p1id: json['p1id'],
      p2id: json['p2id'],
      typeId: json['typeId'],
      diam: json['diam'],
      len: json['len'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'p1id': p1id,
    'p2id': p2id,
    'typeId': typeId,
    'diam': diam,
    'len': len,
  };
}