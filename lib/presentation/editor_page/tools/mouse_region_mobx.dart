import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

part 'mouse_region_mobx.g.dart';

class MouserRegionProvider extends StatelessWidget {
  const MouserRegionProvider(
      {super.key, required this.child, required this.transformationController});
  final Widget child;
  final TransformationController transformationController;
  @override
  Widget build(BuildContext context) {
    return Provider(
        create: (_) => MouseRegionPositionStateStore(),
        child: Builder(builder: (context) {
          final stateStore = MouseRegionPositionState.of(context);
          return MouseRegion(
            onEnter: (event) {
              print(event);
              stateStore.inVisibleArea = true;
            },
            onExit: (event) {
              print(event);
              stateStore.inVisibleArea = false;
            },
            onHover: (event) {
              stateStore.position =
                  transformationController.toScene(event.localPosition);
            },
            child: child,
          );
        }));
  }
}

class MouseRegionPositionStateStore = MouseRegionPositionState
    with _$MouseRegionPositionStateStore;

abstract class MouseRegionPositionState with Store {
  @observable
  Offset? position;
  @observable
  bool inVisibleArea = false;
  static MouseRegionPositionState of(BuildContext context) =>
      context.read<MouseRegionPositionStateStore>();
}
