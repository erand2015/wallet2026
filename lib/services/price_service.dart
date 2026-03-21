// lib/services/price_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static const String coinGeckoUrl = 'https://api.coingecko.com/api/v3';
  
  Future<double> getCurrentPrice() async {
    try {
      final response = await http.get(
        Uri.parse('$coinGeckoUrl/simple/price?ids=warthog&vs_currencies=usd'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['warthog']['usd'] ?? 0.15;
      }
      return 0.15;
    } catch (e) {
      print('Error getting price: $e');
      return 0.15;
    }
  }
  
  Future<List<Map<String, dynamic>>> getPriceHistory({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$coinGeckoUrl/coins/warthog/market_chart?vs_currency=usd&days=$days'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> prices = data['prices'] ?? [];
        
        return prices.map((item) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(item[0].toInt());
          final price = item[1];
          return {
            'timestamp': timestamp,
            'price': price,
          };
        }).toList();
      }
      return _generateMockPriceHistory(days);
    } catch (e) {
      print('Error getting price history: $e');
      return _generateMockPriceHistory(days);
    }
  }
  
  List<Map<String, dynamic>> _generateMockPriceHistory(int days) {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();
    double price = 0.15;
    
    for (int i = days; i >= 0; i--) {
      final change = (i % 3 == 0 ? 0.02 : -0.01) + (i % 5 == 0 ? 0.03 : 0);
      price = price + change;
      if (price < 0.05) price = 0.05;
      if (price > 0.35) price = 0.35;
      
      history.add({
        'timestamp': now.subtract(Duration(days: i)),
        'price': price,
      });
    }
    return history;
  }
}