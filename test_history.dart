// test_history.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final address = '4b46557f77181950326fa319c409e64c410fb0c4d5904b1b';
  final response = await http.get(
    Uri.parse('http://217.182.64.43:3001/account/$address/history/0'),
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}