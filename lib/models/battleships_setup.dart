import 'package:battleships/models/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'LoginScreen.dart';
import 'game_status_widget.dart';
import 'home_screen.dart';

class BattleshipsSetupScreen extends StatefulWidget {
  final String accessToken;
  final String? selectedAI;

  BattleshipsSetupScreen({required this.accessToken, this.selectedAI});

  @override
  _BattleshipsSetupScreenState createState() => _BattleshipsSetupScreenState();
}

class _BattleshipsSetupScreenState extends State<BattleshipsSetupScreen> {
  final String serverUrl = 'http://165.227.117.48';
  List<String> selectedShips = [];
  HomeScreen? homeScreen;

  Future<void> submitShips(BuildContext context, {String? selectedAI}) async {
    print('Submit Ships button pressed.');

    if (selectedShips.length < 5) {
      return;
    }

    final Map<String, dynamic> requestBody = {
      'ships': selectedShips,
      'ai': widget.selectedAI
    };

    final response = await http.post(
      Uri.parse('$serverUrl/games'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode(requestBody),
    );

    // Printing information for debugging purposes

    print('Request URL: ${response.request?.url}');
    print('Request Headers: ${response.request?.headers}');
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('AI Selected: ${widget.selectedAI}');

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = jsonDecode(response.body);

      if (data != null &&
          data.containsKey('id') &&
          data.containsKey('player') &&
          data.containsKey('matched')) {
        final int gameId = data['id'];
        final int player = data['player'];
        final bool matched = data['matched'] ?? false;

        final snackBar = SnackBar(
          content: Text(
            'Ships submitted successfully. Game ID: $gameId, Matched: $matched',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        await Future.delayed(Duration(seconds: 2));

        Navigator.pop(
          context,
          GameStatusWidget(gameId: gameId, matched: matched, player: player),
        );
      } else {
        final snackBar = SnackBar(
          content: Text('Failed to create a new game. Please try again.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      final snackBar = SnackBar(
        content: Text(
          'Failed to create a new game. Status Code: ${response.statusCode}, Response: ${response.body}',
        ),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battleships Setup'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 1.5),
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                final position =
                    String.fromCharCode('A'.codeUnitAt(0) + (index ~/ 5)) +
                        ((index % 5) + 1).toString();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedShips.contains(position)) {
                        selectedShips.remove(position);
                      } else {
                        selectedShips.add(position);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      color: selectedShips.contains(position)
                          ? Colors.blue
                          : Colors.white,
                    ),
                    child: Center(
                      child: Text(position),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => submitShips(context),
            child: Text('Submit Ships'),
          ),
        ],
      ),
    );
  }
}
