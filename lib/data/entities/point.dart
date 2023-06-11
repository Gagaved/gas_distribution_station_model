import 'package:floor/floor.dart';
@entity
class Point {
  @PrimaryKey(autoGenerate: false)
  final int id;
  double positionX;
  double positionY;

  Point({required this.id, required this.positionX, required this.positionY});

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'],
      positionX: json['positionX'],
      positionY: json['positionY'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'positionX': positionX,
    'positionY': positionY,
  };
}