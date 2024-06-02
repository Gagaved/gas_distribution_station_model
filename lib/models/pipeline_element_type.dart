import 'package:dart_mappable/dart_mappable.dart';

part 'pipeline_element_type.mapper.dart';

@MappableEnum()
enum PipelineEdgeType {
  segment,
  valve,
  percentageValve,
  // source,
  // sink,
  heater,
  adorizer,
  meter,
  reducer,
  filter,
}
