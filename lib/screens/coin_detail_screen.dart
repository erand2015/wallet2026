// lib/screens/coin_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/trending_service.dart';
import '../theme/theme.dart';

class CoinDetailScreen extends StatefulWidget {
  final Map<String, dynamic> coin;

  const CoinDetailScreen({super.key, required this.coin});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final TrendingService _trendingService = TrendingService();
  List<Map<String, dynamic>> _priceHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedDays = 7;
  bool _isPriceHidden = false;

  // Të dhëna lokale për Warthog
  List<Map<String, dynamic>> _getLocalWarthogHistory(int days) {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();
    final currentPrice = widget.coin['current_price'] ?? 0.092;
    
    for (int i = days; i >= 0; i--) {
      final change = (i % 3 == 0 ? 0.025 : -0.015) + (i % 5 == 0 ? 0.03 : 0);
      double price = currentPrice * (1 + change);
      if (price < 0.05) price = 0.05;
      if (price > 0.15) price = 0.15;
      
      history.add({
        'timestamp': now.subtract(Duration(days: i)),
        'price': price,
      });
    }
    return history;
  }

  @override
  void initState() {
    super.initState();
    _loadPriceHistory();
  }

  Future<void> _loadPriceHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> history;
      
      // Nëse është Warthog, përdor të dhëna lokale
      if (widget.coin['id'] == 'warthog' || widget.coin['isWarthog'] == true) {
        history = _getLocalWarthogHistory(_selectedDays);
      } else {
        history = await _trendingService.getCoinPriceHistory(
          widget.coin['id'],
          days: _selectedDays,
        );
      }
      
      setState(() {
        _priceHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading price history: $e');
      // Nëse ka gabim dhe është Warthog, përdor të dhëna lokale
      if (widget.coin['id'] == 'warthog' || widget.coin['isWarthog'] == true) {
        setState(() {
          _priceHistory = _getLocalWarthogHistory(_selectedDays);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load price data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.coin['price_change_percentage_24h'] >= 0;
    final price = widget.coin['current_price']?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            if (widget.coin['image'] != null && widget.coin['image'].isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.coin['image']),
                backgroundColor: Colors.transparent,
                onBackgroundImageError: (_, __) {},
              )
            else if (widget.coin['id'] == 'warthog' || widget.coin['isWarthog'] == true)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: WarthogColors.primaryOrange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '🐗',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.coin['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.coin['symbol'],
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isPriceHidden ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isPriceHidden = !_isPriceHidden;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(WarthogColors.primaryOrange),
              ),
            )
          : _errorMessage != null
              ? Center(
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
                        onPressed: _loadPriceHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPriceHidden ? '******' : '\$${price.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${isPositive ? '+' : ''}${widget.coin['price_change_percentage_24h'].toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Price Chart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<int>(
                                value: _selectedDays,
                                dropdownColor: const Color(0xFF1A1A1A),
                                underline: const SizedBox(),
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 7, child: Text('7D')),
                                  DropdownMenuItem(value: 14, child: Text('14D')),
                                  DropdownMenuItem(value: 30, child: Text('30D')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDays = value;
                                    });
                                    _loadPriceHistory();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_priceHistory.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'No price data available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 250,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: (price * 0.1),
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade700,
                                      strokeWidth: 0.5,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < _priceHistory.length) {
                                          final date = _priceHistory[index]['timestamp'] as DateTime;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              DateFormat('dd/MM').format(date),
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '\$${value.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 10,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _priceHistory.asMap().entries.map((entry) {
                                      return FlSpot(
                                        entry.key.toDouble(),
                                        entry.value['price'],
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: WarthogColors.primaryOrange,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: WarthogColors.primaryOrange.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade800,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow('Market Cap', '\$${_formatNumber(widget.coin['market_cap'])}'),
                            const Divider(color: Color(0xFF2A2A2A)),
                            _buildStatRow('24h High', '\$${_formatNumber(widget.coin['high_24h'] ?? price * 1.05)}'),
                            const Divider(color: Color(0xFF2A2A2A)),
                            _buildStatRow('24h Low', '\$${_formatNumber(widget.coin['low_24h'] ?? price * 0.95)}'),
                            const Divider(color: Color(0xFF2A2A2A)),
                            _buildStatRow('24h Volume', '\$${_formatNumber(widget.coin['total_volume'] ?? 0)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1e12) return '${(number / 1e12).toStringAsFixed(2)}T';
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(2)}M';
    return number.toStringAsFixed(0);
  }
}