import 'package:flutter/material.dart';

class SimulatedStatusBar extends StatelessWidget {
  const SimulatedStatusBar({super.key, this.backgroundColor = Colors.white});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.paddingOf(context).top > 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 52,
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '9:30',
              style: TextStyle(
                color: Color(0xFF1C1B1F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF1C1B1F),
              shape: BoxShape.circle,
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 17, color: Color(0xFFE5E5E5)),
                SizedBox(width: 5),
                Icon(
                  Icons.signal_cellular_alt,
                  size: 17,
                  color: Color(0xFF1C1B1F),
                ),
                SizedBox(width: 5),
                Icon(Icons.battery_full, size: 17, color: Color(0xFF1C1B1F)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
