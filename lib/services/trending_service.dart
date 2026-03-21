// lib/services/trending_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TrendingService {
  static const String coinGeckoUrl = 'https://api.coingecko.com/api/v3';
  
  Future<List<Map<String, dynamic>>> getTopCoins() async {
    try {
      final response = await http.get(
        Uri.parse('$coinGeckoUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((coin) {
          return {
            'id': coin['id'],
            'symbol': coin['symbol'].toString().toUpperCase(),
            'name': coin['name'],
            'current_price': coin['current_price']?.toDouble() ?? 0.0,
            'price_change_percentage_24h': coin['price_change_percentage_24h']?.toDouble() ?? 0.0,
            'market_cap': coin['market_cap']?.toDouble() ?? 0.0,
            'total_volume': coin['total_volume']?.toDouble() ?? 0.0,
            'high_24h': coin['high_24h']?.toDouble() ?? 0.0,
            'low_24h': coin['low_24h']?.toDouble() ?? 0.0,
            'image': coin['image'],
          };
        }).toList();
      }
      return _generateMockCoins();
    } catch (e) {
      print('Error getting top coins: $e');
      return _generateMockCoins();
    }
  }
  
  Future<List<Map<String, dynamic>>> getCoinPriceHistory(String coinId, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$coinGeckoUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days'),
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
  
  List<Map<String, dynamic>> _generateMockCoins() {
    return [
      {'id': 'bitcoin', 'symbol': 'BTC', 'name': 'Bitcoin', 'current_price': 65000, 'price_change_percentage_24h': 2.5, 'market_cap': 1200000000000, 'total_volume': 30000000000, 'high_24h': 66000, 'low_24h': 64000, 'image': ''},
      {'id': 'ethereum', 'symbol': 'ETH', 'name': 'Ethereum', 'current_price': 3500, 'price_change_percentage_24h': -1.2, 'market_cap': 420000000000, 'total_volume': 15000000000, 'high_24h': 3550, 'low_24h': 3450, 'image': ''},
      {'id': 'solana', 'symbol': 'SOL', 'name': 'Solana', 'current_price': 180, 'price_change_percentage_24h': 5.8, 'market_cap': 80000000000, 'total_volume': 5000000000, 'high_24h': 185, 'low_24h': 175, 'image': ''},
    ];
  }
  
  List<Map<String, dynamic>> _generateMockPriceHistory(int days) {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();
    double price = 100;
    
    for (int i = days; i >= 0; i--) {
      final change = (i % 3 == 0 ? 5 : -2) + (i % 5 == 0 ? 3 : 0);
      price = price + change;
      if (price < 10) price = 10;
      if (price > 500) price = 500;
      
      history.add({
        'timestamp': now.subtract(Duration(days: i)),
        'price': price,
      });
    }
    return history;
  }
}