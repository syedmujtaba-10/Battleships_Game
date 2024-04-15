import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String serverUrl = 'http://165.227.117.48';
  String message = '';
  late SharedPreferences prefs;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    initSharedPreferences();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    final String? savedToken = prefs.getString('accessToken');
    if (savedToken != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(onLogout: logoutUser, accessToken: savedToken),
        ),
      );
    }
  }

  Future<void> loginUser(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    final response = await http.post(
      Uri.parse('$serverUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String accessToken = data['access_token'];
      // Save the access token to SharedPreferences
      prefs.setString('accessToken', accessToken);
      print('Login successful! Access Token: $accessToken');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(onLogout: logoutUser, accessToken: accessToken),
        ),
      );
    } else {
      setState(() {
        message = 'Login failed. Status Code: ${response.statusCode}';
      });
    }
  }

  Future<void> registerUser(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    final response = await http.post(
      Uri.parse('$serverUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String accessToken = data['access_token'];

      prefs.setString('accessToken', accessToken);
      print('Registration successful! Access Token: $accessToken');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(onLogout: logoutUser, accessToken: accessToken),
        ),
      );
    } else {
      setState(() {
        message = 'Registration failed. Status Code: ${response.statusCode}';
      });
    }
  }

  Future<void> logoutUser() async {
    prefs.remove('accessToken');
    if (_isMounted) {
      setState(() {
        message = 'Logout successful';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => loginUser(context),
                  child: Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () => registerUser(context),
                  child: Text('Register'),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              message,
              style: TextStyle(
                color:
                    message.contains('successful') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
