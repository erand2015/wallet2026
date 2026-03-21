// lib/services/trending_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TrendingService {
  static const String coinGeckoUrl = 'https://api.coingecko.com/api/v3';
  
  // Merr çmimet e coin-ve kryesore
  Future<List<Map<String, dynamic>>> getTopCoins() async {
    // Provo CoinGecko
    try {
      final response = await http.get(
        Uri.parse('$coinGeckoUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1&sparkline=false'),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
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
              'image': coin['image'] ?? '',
            };
          }).toList();
        }
      }
    } catch (e) {
      print('CoinGecko error: $e');
    }
    
    // Fallback: të dhëna lokale
    return _getLocalCoins();
  }
  
  // Merr historikun e çmimit për një coin
  Future<List<Map<String, dynamic>>> getCoinPriceHistory(String coinId, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$coinGeckoUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days'),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> prices = data['prices'] ?? [];
        
        if (prices.isNotEmpty) {
          return prices.map((item) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(item[0].toInt());
            final price = item[1];
            return {
              'timestamp': timestamp,
              'price': price,
            };
          }).toList();
        }
      }
    } catch (e) {
      print('Price history error: $e');
    }
    
    // Fallback: të dhëna lokale
    return _getLocalPriceHistory(coinId, days);
  }
  
  // Të dhëna lokale (fallback)
  List<Map<String, dynamic>> _getLocalCoins() {
    return [
      {'id': 'bitcoin', 'symbol': 'BTC', 'name': 'Bitcoin', 'current_price': 65000, 'price_change_percentage_24h': 2.5, 'market_cap': 1200000000000, 'total_volume': 30000000000, 'high_24h': 66000, 'low_24h': 64000, 'image': ''},
      {'id': 'ethereum', 'symbol': 'ETH', 'name': 'Ethereum', 'current_price': 3500, 'price_change_percentage_24h': -1.2, 'market_cap': 420000000000, 'total_volume': 15000000000, 'high_24h': 3550, 'low_24h': 3450, 'image': ''},
      {'id': 'solana', 'symbol': 'SOL', 'name': 'Solana', 'current_price': 180, 'price_change_percentage_24h': 5.8, 'market_cap': 80000000000, 'total_volume': 5000000000, 'high_24h': 185, 'low_24h': 175, 'image': ''},
      {'id': 'cardano', 'symbol': 'ADA', 'name': 'Cardano', 'current_price': 0.45, 'price_change_percentage_24h': -0.5, 'market_cap': 16000000000, 'total_volume': 1000000000, 'high_24h': 0.46, 'low_24h': 0.44, 'image': ''},
      {'id': 'dogecoin', 'symbol': 'DOGE', 'name': 'Dogecoin', 'current_price': 0.12, 'price_change_percentage_24h': 1.8, 'market_cap': 17000000000, 'total_volume': 800000000, 'high_24h': 0.125, 'low_24h': 0.118, 'image': ''},
      {'id': 'ripple', 'symbol': 'XRP', 'name': 'XRP', 'current_price': 0.55, 'price_change_percentage_24h': -0.3, 'market_cap': 30000000000, 'total_volume': 1200000000, 'high_24h': 0.56, 'low_24h': 0.54, 'image': ''},
      {'id': 'polkadot', 'symbol': 'DOT', 'name': 'Polkadot', 'current_price': 8.50, 'price_change_percentage_24h': 3.2, 'market_cap': 11000000000, 'total_volume': 400000000, 'high_24h': 8.70, 'low_24h': 8.30, 'image': ''},
      {'id': 'chainlink', 'symbol': 'LINK', 'name': 'Chainlink', 'current_price': 15.20, 'price_change_percentage_24h': -2.1, 'market_cap': 8500000000, 'total_volume': 350000000, 'high_24h': 15.50, 'low_24h': 15.00, 'image': ''},
    ];
  }
  
  // Të dhëna lokale për grafik
  List<Map<String, dynamic>> _getLocalPriceHistory(String coinId, int days) {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();
    double price = coinId == 'bitcoin' ? 65000 : (coinId == 'ethereum' ? 3500 : 180);
    
    for (int i = days; i >= 0; i--) {
      final change = (i % 3 == 0 ? 0.02 : -0.01) + (i % 5 == 0 ? 0.03 : 0);
      price = price * (1 + change);
      
      history.add({
        'timestamp': now.subtract(Duration(days: i)),
        'price': price,
      });
    }
    return history;
  }
}