import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

part 'tools_state_mobx.g.dart';

class ToolsStateStore = ToolsState with _$ToolsStateStore;

enum HeatMapState {
  temperature('Температура'),
  pressure('Давление'),
  flow('Расход'),
  adorization('Одоризация');

  const HeatMapState(this.value);

  final String value;
}

abstract class ToolsState with Store {
  @observable
  bool calculationToolVisible = true;

  @observable
  HeatMapState? heatMapState = HeatMapState.flow;

  static ToolsState of(BuildContext context) => context.get<ToolsStateStore>();
}

extension ProviderContextExt on BuildContext {
  T get<T>() => Provider.of<T>(this, listen: false);
  T watch<T>() => Provider.of<T>(this);
}
