// game_screen.dart
import 'package:flutter/material.dart';
import 'gameService.dart';
//import 'battleships_setup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'game_status_widget.dart';

class GameScreen extends StatefulWidget {
  final int gameId;
  final String accessToken;
  final int position;

  GameScreen(
      {required this.gameId,
      required this.accessToken,
      required this.position});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late String gameStatus = '';
  late List<String> remainingShips = [];
  late List<String> wrecks = [];
  late List<String> shots = [];
  late List<String> sunk = [];
  late bool isMyTurn = false;
  late int chance = 5;

  List<String> selectedBlocks = [];

  @override
  void initState() {
    super.initState();
    // Fetch game details when the screen is initialized
    fetchGameDetails();
  }

  Future<void> fetchGameDetails() async {
    try {
      final gameService = GameService(baseUrl: 'http://165.227.117.48');
      final List<GameInfo> games =
          await gameService.getAllGames(widget.accessToken);

      final GameInfo currentGame =
          games.firstWhere((game) => game.id == widget.gameId);

      final GameDetails gameDetails =
          await gameService.getGameDetails(widget.accessToken, widget.gameId);

      setState(() {
        gameStatus = gameDetails.status.toString();
        remainingShips = gameDetails.ships;
        wrecks = gameDetails.wrecks;
        shots = gameDetails.shots;
        sunk = gameDetails.sunk;
        isMyTurn = gameDetails.turn == widget.position;
        chance = gameDetails.turn;
      });
    } catch (e) {
      print('Error fetching game details: $e');
    }
  }

  Future<void> playShot(String accessToken, int gameId, String shot) async {
    try {
      final response = await http.put(
        Uri.parse('http://165.227.117.48/games/$gameId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'shot': shot}),
      );

      print('Play Shot Request URL: ${response.request?.url}');
      print('Play Shot Request Headers: ${response.request?.headers}');
      print('Play Shot Response Status Code: ${response.statusCode}');
      print('Play Shot Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String message = responseData['message'];
        final bool sunkShip = responseData['sunk_ship'];
        final bool won = responseData['won'];
        print(message);

        setState(() {
          shots.add(shot);
          if (sunkShip) {
            sunk.add(shot);
          }
          if (won) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Congratulations!'),
                  content: Text('You won the game!'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        });
      } else {
        throw Exception(
            'Failed to play shot. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error playing shot: $e');
    }
  }

  Future<void> playMyShot(String shot) async {
    try {
      await playShot(widget.accessToken, widget.gameId, shot);

      fetchGameDetails();
      if (sunk.contains(shot)) {
        final snackBar = SnackBar(
          content: Text(
            'Enemy Hit',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      print('Error playing shot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game ID: ${widget.gameId}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                final row =
                    String.fromCharCode('A'.codeUnitAt(0) + (index ~/ 5));
                final column = (index % 5) + 1;
                final coordinate = '$row$column';

                final hasShip = remainingShips.contains(coordinate);
                final isSelected = selectedBlocks.contains(coordinate);
                final isShot = shots.contains(coordinate);
                final isSunk = sunk.contains(coordinate);
                final isWreck = wrecks.contains(coordinate);

                return InkWell(
                  onTap: () {
                    if (isMyTurn) {
                      setState(() {
                        if (isSelected) {
                          selectedBlocks.clear();
                        } else {
                          selectedBlocks.clear();
                          selectedBlocks.add(coordinate);
                        }
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      color: hasShip
                          ? Colors.blue
                          : (isShot
                              ? Colors.red
                              : (isSelected ? Colors.yellow : Colors.white)),
                    ),
                    child: Center(
                      child: isShot
                          ? isSunk
                              ? Icon(Icons.fireplace_sharp, color: Colors.black)
                              : Icon(Icons.fiber_manual_record,
                                  color: Colors.black)
                          : (isWreck
                              ? Icon(Icons.animation, color: Colors.black)
                              : (hasShip
                                  ? Icon(Icons.airlines_sharp,
                                      color: Colors.black)
                                  : Text(
                                      coordinate,
                                      style: TextStyle(
                                        color: hasShip
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ))),
                    ),
                  ),
                );
                //);
              },
            ),
          ),
          if (isMyTurn)
            Center(
              child: ElevatedButton(
                onPressed: (gameStatus == '1' || gameStatus == '2')
                    ? null
                    : () {
                        print('Selected Blocks: $selectedBlocks');

                        for (String block in selectedBlocks) {
                          //playMyShot(block);
                          if (shots.contains(block)) {
                            final snackBar = SnackBar(
                              content: Text(
                                'Shot Already Played',
                              ),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } else {
                            playMyShot(block);
                            //fetchGameDetails();
                            final snackBar = SnackBar(
                              content: Text(
                                'Shot Played',
                              ),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }
                        }
                      },
                child: Text('Submit'),
              ),
            ),
        ],
      ),
    );
  }
}
