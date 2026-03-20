import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final address = '4b46557f77181950326fa319c409e64c410fb0c4d5904b1b';
  final response = await http.get(
    Uri.parse('https://warthognode.duckdns.org/account/$address/history/0'),
  );
  
  print('Status: ${response.statusCode}');
  final data = json.decode(response.body);
  print('Body e plotë: ${JsonEncoder.withIndent('  ').convert(data)}');
}