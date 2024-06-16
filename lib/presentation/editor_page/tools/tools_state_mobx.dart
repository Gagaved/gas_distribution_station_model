import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

part 'tools_state_mobx.g.dart';

class ToolsStateStore = ToolsState with _$ToolsStateStore;

abstract class ToolsState with Store {
  @observable
  bool calculationToolVisible = true;
  static ToolsState of(BuildContext context) => context.read<ToolsStateStore>();
}
