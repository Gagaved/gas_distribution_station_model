import 'package:dart_mappable/dart_mappable.dart';

part 'pipeline_element_type.mapper.dart';

@MappableEnum()
enum EdgeType {
  segment('Участок'),
  valve('Кран'),
  percentageValve('Регулируемый кран'),
  heater('Нагреватель'),
  adorizer('Адоризатор'),
  meter('Счетчик'),
  reducer('Регулятор давления'),
  filter('Фильтр');

  const EdgeType(this.value);

  final String value;
}
