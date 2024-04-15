// game_status_widget.dart
import 'package:flutter/material.dart';

class GameStatusWidget extends StatelessWidget {
  final int gameId;
  final bool matched;
  final int player;

  GameStatusWidget({
    required this.gameId,
    required this.matched,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Game ID: $gameId'),
        Text('Matched: $matched'),
        Text('Player: $player'),
      ],
    );
  }
}
