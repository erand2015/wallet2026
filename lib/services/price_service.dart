// lib/services/price_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceService {
  static const String _coingeckoUrl = 'https://api.coingecko.com/api/v3';
  static const String _wartId = 'warthog';  // ID e saktë nga CoinGecko!
  
  double _cachedPrice = 0.0933;
  DateTime? _lastUpdate;
  List<Map<String, dynamic>> _cachedHistory = [];
  
  Future<double> getCurrentPrice() async {
    // Nëse cache është e freskët (< 2 minuta), ktheje
    if (_lastUpdate != null && 
        DateTime.now().difference(_lastUpdate!) < const Duration(minutes: 2)) {
      return _cachedPrice;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_coingeckoUrl/simple/price?ids=$_wartId&vs_currencies=usd'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey(_wartId) && data[_wartId].containsKey('usd')) {
          _cachedPrice = data[_wartId]['usd'].toDouble();
          _lastUpdate = DateTime.now();
          print('✅ WART price updated: \$$_cachedPrice');
          return _cachedPrice;
        }
      }
      
      print('⚠️ WART price API returned no data, using cached: $_cachedPrice');
      return _cachedPrice;
      
    } catch (e) {
      print('❌ Error fetching WART price: $e');
      return _cachedPrice;
    }
  }
  
  Future<List<Map<String, dynamic>>> getPriceHistory({int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_coingeckoUrl/coins/$_wartId/market_chart?vs_currency=usd&days=$days'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = data['prices'] as List<dynamic>;
        
        _cachedHistory = prices.map((item) {
          return {
            'timestamp': DateTime.fromMillisecondsSinceEpoch(item[0].toInt()),
            'price': item[1].toDouble(),
          };
        }).toList();
        print('✅ WART history updated: ${_cachedHistory.length} points');
        return _cachedHistory;
      }
      
      print('⚠️ WART history API failed, using cached');
      return _cachedHistory.isNotEmpty ? _cachedHistory : _generateMockHistory(days);
      
    } catch (e) {
      print('❌ Error fetching WART history: $e');
      return _cachedHistory.isNotEmpty ? _cachedHistory : _generateMockHistory(days);
    }
  }
  
  List<Map<String, dynamic>> _generateMockHistory(int days) {
    final history = <Map<String, dynamic>>[];
    final now = DateTime.now();
    double price = _cachedPrice;
    
    for (int i = days; i >= 0; i--) {
      final change = (i % 3 == 0 ? 0.02 : -0.01) + (i % 5 == 0 ? 0.015 : 0);
      price = price * (1 + change);
      history.add({
        'timestamp': now.subtract(Duration(days: i)),
        'price': price.clamp(0.05, 0.15),
      });
    }
    return history;
  }
}
