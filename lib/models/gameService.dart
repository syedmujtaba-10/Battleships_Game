import 'package:http/http.dart' as http;
import 'dart:convert';

class GameService {
  final String baseUrl;

  GameService({required this.baseUrl});

  Future<List<GameInfo>> getAllGames(String accessToken) async {
    print('Received token : $accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/games'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    print('Request URL: ${response.request?.url}');
    print('Request Headers: ${response.request?.headers}');
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> gamesData = responseData['games'];

      return gamesData.map((gameData) => GameInfo.fromJson(gameData)).toList();
    } else {
      throw Exception(
          'Failed to load games. Status Code: ${response.statusCode}');
    }
  }

  Future<GameDetails> getGameDetails(String accessToken, int gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/games/$gameId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return GameDetails.fromJson(responseData);
    } else {
      throw Exception(
          'Failed to load game details. Status Code: ${response.statusCode}');
    }
  }

  Future<void> cancelGame(String accessToken, int gameId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = jsonDecode(response.body);
        final String message = data?['message'] ?? 'Game canceled successfully';
        print('Game canceled: $message');
      } else {
        print(
            'Failed to cancel game. Status Code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('Error canceling game: $e');
    }
  }
}

class GameInfo {
  final int id;
  final String player1;
  final String? player2;
  final int position;
  final int status;
  final int turn;

  GameInfo({
    required this.id,
    required this.player1,
    required this.player2,
    required this.position,
    required this.status,
    required this.turn,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      id: json['id'],
      player1: json['player1'],
      player2: json['player2'],
      position: json['position'],
      status: json['status'],
      turn: json['turn'],
    );
  }
}

class GameDetails {
  final int id;
  final int status;
  final int position;
  final int turn;
  final String player1;
  final String player2;
  final List<String> ships;
  final List<String> wrecks;
  final List<String> shots;
  final List<String> sunk;

  GameDetails({
    required this.id,
    required this.status,
    required this.position,
    required this.turn,
    required this.player1,
    required this.player2,
    required this.ships,
    required this.wrecks,
    required this.shots,
    required this.sunk,
  });

  factory GameDetails.fromJson(Map<String, dynamic> json) {
    return GameDetails(
      id: json['id'],
      status: json['status'],
      position: json['position'],
      turn: json['turn'],
      player1: json['player1'],
      player2: json['player2'],
      ships: List<String>.from(json['ships'] ?? []),
      wrecks: List<String>.from(json['wrecks'] ?? []),
      shots: List<String>.from(json['shots'] ?? []),
      sunk: List<String>.from(json['sunk'] ?? []),
    );
  }
}
