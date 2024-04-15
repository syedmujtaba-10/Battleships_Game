// home_screen.dart
import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'battleships_setup.dart';
import 'game_status_widget.dart';
import 'gameService.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  final Future<void> Function() onLogout;
  final String accessToken;

  HomeScreen({required this.onLogout, required this.accessToken});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameStatusWidget? _gameStatus;
  List<GameInfo>? _games;
  List<GameDetails>? _gameplay;
  bool showCompletedGames = false;
  GameService gameService = GameService(baseUrl: 'http://165.227.117.48');

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  void refreshState() {
    fetchGames();
  }

  Future<void> fetchGames() async {
    try {
      List<GameInfo> games = await gameService.getAllGames(widget.accessToken);
      print('passed token');

      setState(() {
        _games = showCompletedGames
            ? games
                .where((game) => (game.turn == 0 && game.status != 0))
                .toList()
            : games
                .where((game) => (game.turn != 0 || game.status == 0))
                .toList();
      });
    } catch (e) {
      print('Error fetching games: $e');
    }
  }

  Future<void> _cancelGame(int gameId) async {
    try {
      await gameService.cancelGame(widget.accessToken, gameId);
      refreshState();
    } catch (e) {
      print('Error canceling game: $e');
    }
  }

  void onToggleGames(bool value) {
    setState(() {
      showCompletedGames = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<GameInfo>? filteredGames = showCompletedGames
        ? _games?.where((game) => game.turn == 0).toList()
        : _games;
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              refreshState();
            },
          ),
        ],
      ),
      drawer: DrawerWidget(
        showCompletedGames: showCompletedGames,
        onLogout: () async {
          await widget.onLogout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
        onNewGame: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BattleshipsSetupScreen(accessToken: widget.accessToken),
            ),
          ).then((gameStatus) {
            if (gameStatus is GameStatusWidget) {
              setState(() {
                _gameStatus = gameStatus;
              });
            }
            refreshState();
          });
        },
        onNewAIGame: () {
          Navigator.of(context).pop();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Select AI Opponent'),
              content: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleshipsSetupScreen(
                            accessToken: widget.accessToken,
                            selectedAI: "random",
                          ),
                        ),
                      ).then((gameStatus) {
                        if (gameStatus is GameStatusWidget) {
                          setState(() {
                            _gameStatus = gameStatus;
                          });
                        }
                        refreshState();
                      });
                    },
                    child: Text('Play against Random AI'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleshipsSetupScreen(
                            accessToken: widget.accessToken,
                            selectedAI: "perfect",
                          ),
                        ),
                      ).then((gameStatus) {
                        if (gameStatus is GameStatusWidget) {
                          setState(() {
                            _gameStatus = gameStatus;
                          });
                        }
                        refreshState();
                      });
                    },
                    child: Text('Play against Perfect AI'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleshipsSetupScreen(
                            accessToken: widget.accessToken,
                            selectedAI: "One ship (A1)",
                          ),
                        ),
                      ).then((gameStatus) {
                        if (gameStatus is GameStatusWidget) {
                          setState(() {
                            _gameStatus = gameStatus;
                          });
                        }
                        refreshState();
                      });
                    },
                    child: Text('Play against One Ship AI'),
                  ),
                ],
              ),
            ),
          );
        },
        onToggleGames: (value) {
          setState(() {
            showCompletedGames = value;
          });
          fetchGames();
        },
      ),
      body: Center(
        child: Column(
          children: [
            Text('Welcome to the Home Screen!'),
            if (filteredGames != null && filteredGames.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    return ListTile(
                      title: Text('Game ID: ${game.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${game.player1} vs ${game.player2}'),
                          //Text('Player 2: ${game.player2}'),
                          //Text('Position: ${game.position}'),
                          Text('${game.status == 0 ? "matchMaking" : ""}'),
                          Text(
                              '${game.status == 1 ? "${game.player1} Won" : (game.status == 2 ? "${game.player2} Won" : "")}'),
                          //Text('Turn: ${game.turn}'),
                          Text(
                              'Turn: ${game.turn == 1 ? "${game.player1}'s Turn" : "${game.player2}'s Turn"}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _cancelGame(game.id);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                                gameId: game.id,
                                accessToken: widget.accessToken,
                                position: game.position),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DrawerWidget extends StatelessWidget {
  final Future<void> Function() onLogout;
  final VoidCallback onNewGame;
  final VoidCallback onNewAIGame;
  final ValueChanged<bool> onToggleGames;
  final bool showCompletedGames;

  DrawerWidget(
      {required this.onLogout,
      required this.onNewGame,
      required this.onNewAIGame,
      required this.onToggleGames,
      required this.showCompletedGames});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Options'),
          ),
          ListTile(
            title: Text('Logout'),
            onTap: () async {
              Navigator.of(context).pop();
              await onLogout();
            },
          ),
          ListTile(
            title: Text('New Game'),
            onTap: onNewGame,
          ),
          ListTile(
            title: Text('New AI Game'),
            onTap: onNewAIGame,
          ),
          SwitchListTile(
            title: Text('Show Completed Games'),
            value: showCompletedGames,
            onChanged: (value) {
              onToggleGames(value);
            },
          ),
        ],
      ),
    );
  }
}
