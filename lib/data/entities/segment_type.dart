import 'package:floor/floor.dart';
@entity
class SegmentType{
  @PrimaryKey(autoGenerate: true)
  final int id;
  final String name;
  SegmentType({required this.id,required this.name,});
}