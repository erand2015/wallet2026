// lib/screens/trending_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/trending_service.dart';
import '../services/price_service.dart';
import '../theme/theme.dart';
import 'coin_detail_screen.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final TrendingService _trendingService = TrendingService();
  final PriceService _priceService = PriceService();
  List<Map<String, dynamic>> _coins = [];
  List<Map<String, dynamic>> _wartPriceHistory = [];
  bool _isLoading = true;
  bool _isChartLoading = true;
  String? _errorMessage;
  double _wartPrice = 0.15;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.wait([
      _loadCoins(),
      _loadWartData(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCoins() async {
    try {
      final coins = await _trendingService.getTopCoins();
      setState(() {
        _coins = coins;
      });
    } catch (e) {
      print('Error loading coins: $e');
    }
  }

  Future<void> _loadWartData() async {
    try {
      setState(() {
        _isChartLoading = true;
      });
      
      final price = await _priceService.getCurrentPrice();
      final history = await _priceService.getPriceHistory(days: _selectedDays);
      
      setState(() {
        _wartPrice = price;
        _wartPriceHistory = history;
        _isChartLoading = false;
      });
    } catch (e) {
      print('Error loading WART data: $e');
      setState(() {
        _isChartLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Trending',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: WarthogColors.primaryYellow,
        backgroundColor: const Color(0xFF1A1A1A),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(WarthogColors.primaryOrange),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========== WARTHOG SPECIAL SECTION ==========
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            WarthogColors.primaryOrange,
                            WarthogColors.primaryYellow,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '🐗',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Warthog (WART)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Native Coin',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Price',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${_wartPrice.toStringAsFixed(4)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getWartPriceChange() >= 0 ? Icons.trending_up : Icons.trending_down,
                                          color: _getWartPriceChange() >= 0 ? Colors.green : Colors.red,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_getWartPriceChange() >= 0 ? '+' : ''}${_getWartPriceChange().toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: _getWartPriceChange() >= 0 ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Time selector
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildTimeButton(7, '7D'),
                                  const SizedBox(width: 8),
                                  _buildTimeButton(14, '14D'),
                                  const SizedBox(width: 8),
                                  _buildTimeButton(30, '30D'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Chart
                              SizedBox(
                                height: 180,
                                child: _isChartLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : _wartPriceHistory.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No data available',
                                              style: TextStyle(color: Colors.white70),
                                            ),
                                          )
                                        : LineChart(
                                            LineChartData(
                                              gridData: const FlGridData(show: false),
                                              titlesData: FlTitlesData(
                                                show: true,
                                                bottomTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 20,
                                                    getTitlesWidget: (value, meta) {
                                                      final index = value.toInt();
                                                      if (index >= 0 && index < _wartPriceHistory.length) {
                                                        final date = _wartPriceHistory[index]['timestamp'] as DateTime;
                                                        return Padding(
                                                          padding: const EdgeInsets.only(top: 4),
                                                          child: Text(
                                                            DateFormat('dd').format(date),
                                                            style: const TextStyle(
                                                              color: Colors.white54,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return const Text('');
                                                    },
                                                  ),
                                                ),
                                                leftTitles: const AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                                topTitles: const AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                                rightTitles: const AxisTitles(
                                                  sideTitles: SideTitles(showTitles: false),
                                                ),
                                              ),
                                              borderData: FlBorderData(show: false),
                                              lineBarsData: [
                                                LineChartBarData(
                                                  spots: _wartPriceHistory.asMap().entries.map((entry) {
                                                    return FlSpot(
                                                      entry.key.toDouble(),
                                                      entry.value['price'],
                                                    );
                                                  }).toList(),
                                                  isCurved: true,
                                                  color: Colors.white,
                                                  barWidth: 2,
                                                  dotData: const FlDotData(show: false),
                                                  belowBarData: BarAreaData(
                                                    show: true,
                                                    color: Colors.white.withOpacity(0.2),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // View details button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CoinDetailScreen(
                                          coin: {
                                            'id': 'warthog',
                                            'symbol': 'WART',
                                            'name': 'Warthog',
                                            'current_price': _wartPrice,
                                            'price_change_percentage_24h': _getWartPriceChange(),
                                            'market_cap': 0,
                                            'total_volume': 0,
                                            'high_24h': _wartPrice * 1.05,
                                            'low_24h': _wartPrice * 0.95,
                                            'image': '',
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // ========== OTHER COINS SECTION ==========
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Other Cryptocurrencies',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    // Lista e coin-ve të tjerë
                    if (_errorMessage != null)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_coins.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No data available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _coins.length,
                        itemBuilder: (context, index) {
                          final coin = _coins[index];
                          final isPositive = coin['price_change_percentage_24h'] >= 0;
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CoinDetailScreen(coin: coin),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              child: ListTile(
                                leading: coin['image'] != null && coin['image'].isNotEmpty
                                    ? Image.network(
                                        coin['image'],
                                        width: 40,
                                        height: 40,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                            child: Text(
                                              coin['symbol'][0],
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: Text(
                                            coin['symbol'][0],
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                title: Text(
                                  '${coin['name']} (${coin['symbol']})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Market Cap: \$${_formatNumber(coin['market_cap'])}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${coin['current_price'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPositive
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${isPositive ? '+' : ''}${coin['price_change_percentage_24h'].toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: isPositive ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimeButton(int days, String label) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDays = days;
        });
        _loadWartData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? WarthogColors.primaryOrange : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  double _getWartPriceChange() {
    if (_wartPriceHistory.length < 2) return 0;
    final firstPrice = _wartPriceHistory.first['price'];
    final lastPrice = _wartPriceHistory.last['price'];
    if (firstPrice == 0) return 0;
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  String _formatNumber(double number) {
    if (number >= 1e12) return '${(number / 1e12).toStringAsFixed(2)}T';
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(2)}M';
    return number.toStringAsFixed(0);
  }
}