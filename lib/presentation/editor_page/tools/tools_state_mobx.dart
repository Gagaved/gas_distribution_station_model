import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

part 'tools_state_mobx.g.dart';

class ToolsStateStore = ToolsState with _$ToolsStateStore;

enum HeatMapState {
  temperature('Температура'),
  pressure('Давление'),
  flow('Расход'),
  adorization('Адоризация');

  const HeatMapState(this.value);

  final String value;
}

abstract class ToolsState with Store {
  @observable
  bool calculationToolVisible = true;

  @observable
  HeatMapState? heatMapState = HeatMapState.flow;
  static ToolsState of(BuildContext context) => context.read<ToolsStateStore>();
}
