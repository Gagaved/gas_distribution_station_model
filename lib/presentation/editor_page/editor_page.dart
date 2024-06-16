import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gas_distribution_station_model/globals.dart' as globals;
import 'package:gas_distribution_station_model/models/pipeline_element_type.dart';
import 'package:gas_distribution_station_model/presentation/editor_page/editor_state_mobx.dart';
import 'package:provider/provider.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

import '../../models/gas_network.dart';
import '../grapth_visualisator/grapth_visualisator.dart';
import 'tools/calculation_tool.dart';
import 'tools/mouse_region_mobx.dart';
import 'tools/on_cursor_tool_painter_mobx.dart';
import 'tools/selected_element_panel.dart';
import 'tools/side_tools_menu.dart';
import 'tools/tools_state_mobx.dart';

part 'pipeline_element.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/clear_confirmation_popup.dart';
//import 'package:gas_distribution_station_model/presentation/editor_page/pipeline_element.dart';
part 'tools/clear_confirmation_popup.dart';

class EditorPageWidget extends StatelessWidget {
  const EditorPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => ToolsStateStore(),
      child: Provider(
          create: (context) => EditorStateStore()..init(),
          child: const FocusScope(
            child: _KeyboardHandler(
              child: Stack(fit: StackFit.expand, children: [
                Row(
                  children: [
                    /// Панель иструментов редактора
                    SideToolsMenuWidget(),

                    /// Рабочее поле редактора на котором отображается элементы редактора
                    _PipelinePlanWidget(),
                  ],
                ),
                SelectedElementPanel(),
                CalculationTool(),
              ]),
            ),
          )),
    );
  }
}

class _KeyboardHandler extends StatefulWidget {
  const _KeyboardHandler({super.key, required this.child});

  final Widget child;

  @override
  State<_KeyboardHandler> createState() => _KeyboardHandlerState();
}

class _KeyboardHandlerState extends State<_KeyboardHandler> {
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent keyEvent) {
        if (LogicalKeyboardKey.escape == keyEvent.logicalKey) {
          stateStore.deselectElements();
        }
        print(keyEvent);
      },
      child: widget.child,
    );
  }
}

class _PipelinePlanWidget extends StatefulObserverWidget {
  const _PipelinePlanWidget();

  @override
  State<_PipelinePlanWidget> createState() => _PipelinePlanWidgetState();
}

class _PipelinePlanWidgetState extends State<_PipelinePlanWidget> {
  final TransformationController transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final stateStore = EditorState.of(context);
    var listOfElements = <Widget>[];
    {
      for (Edge edge in stateStore.edges) {
        bool isSelect = stateStore.selectedElementIds.lookup(edge.id) != null;
        listOfElements.add(PipelineWidget.edge(edge: edge, isSelect: isSelect));
      }
      for (Node node in stateStore.nodes) {
        bool isSelect = stateStore.selectedElementIds.lookup(node.id) != null;
        listOfElements.add(PipelineWidget.node(
          node: node,
          isSelect: isSelect,
        ));
      }
      listOfElements.add(const EdgeDraftProjector());

      // listOfElements.insert(
      //   0,
      //   Positioned(
      //     height: 1600,
      //     width: 2400,
      //     child: FittedBox(
      //       fit: BoxFit.fill,
      //       child: Image.asset(
      //         'assets/GRS.png',
      //       ),
      //     ),
      //   ),
      // );
      return Expanded(
          child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (stateStore.selectedTool != null) {
            stateStore.createElement(
              transformationController.toScene(details.localPosition),
            );
          }
        },
        onSecondaryTapDown: (TapDownDetails details) {
          stateStore.deselectElements();
        },
        child: MouserRegionProvider(
          transformationController: transformationController,
          child: OnCursorSelectedToolPainter(
            child: InfiniteSurface(
              transformationController: transformationController,
              children: listOfElements,
            ),
          ),
        ),
      ));
    }
  }
}
