import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';

class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Cfg.statusLineHeight,
      color: Cfg.panelColor,
      padding: const EdgeInsets.symmetric(horizontal: Cfg.panelGap),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AnimatedOpacity(
              opacity: controller.statusVisible ? 1 : 0,
              duration: Cfg.statusFade,
              child: Text(
                controller.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: Cfg.statusFontSize, color: controller.statusIsError ? Cfg.errorColor : Cfg.labelColor),
              ),
            ),
          ),
          const SizedBox(width: Cfg.panelGap),
          Expanded(
            flex: 3,
            child: Text(
              controller.shaderStatus ?? '',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: Cfg.statusFontSize, color: Cfg.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
