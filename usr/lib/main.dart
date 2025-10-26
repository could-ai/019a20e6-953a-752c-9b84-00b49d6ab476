import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoTradeAI-Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const Text('Trading Page - Coming Soon'),
    const Text('Settings Page - Coming Soon'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoTradeAI-Pro'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.candlestick_chart),
            label: 'Trading',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _tickers = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchTickers();
    _timer = Timer.periodic(const Duration(seconds: 30), (Timer t) => _fetchTickers());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTickers() async {
    try {
      final response = await http.get(Uri.parse('https://api.bybit.com/v5/market/tickers?category=linear'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['retCode'] == 0) {
          final List<dynamic> allTickers = data['result']['list'];
          final desiredSymbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT'];
          setState(() {
            _tickers = allTickers.where((ticker) => desiredSymbols.contains(ticker['symbol'])).toList();
            _isLoading = false;
          });
        }
      } else {
        // Handle error
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
       setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RiskDisclaimer(),
                  const SizedBox(height: 16),
                  const Text('Live Market Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildCryptoGrid(),
                  const SizedBox(height: 24),
                  const Text('AI Recommendation History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildRecommendationHistory(),
                ],
              ),
            ),
          );
  }

  Widget _buildCryptoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _tickers.length,
      itemBuilder: (context, index) {
        final ticker = _tickers[index];
        return CryptoCard(ticker: ticker);
      },
    );
  }

  Widget _buildRecommendationHistory() {
    // Mock data for now
    final history = [
      {'pair': 'BTC/USDT', 'signal': 'Buy', 'reason': 'RSI oversold', 'time': '10:32 AM'},
      {'pair': 'ETH/USDT', 'signal': 'Sell', 'reason': 'MACD crossover', 'time': '10:28 AM'},
      {'pair': 'BNB/USDT', 'signal': 'Hold', 'reason': 'Low volatility', 'time': '10:25 AM'},
    ];

    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            leading: Icon(
              item['signal'] == 'Buy' ? Icons.arrow_upward : (item['signal'] == 'Sell' ? Icons.arrow_downward : Icons.pause),
              color: _getSignalColor(item['signal']!),
            ),
            title: Text('${item['pair']} - ${item['signal']}'),
            subtitle: Text(item['reason']!),
            trailing: Text(item['time']!),
          );
        },
      ),
    );
  }
}

class CryptoCard extends StatelessWidget {
  final dynamic ticker;

  const CryptoCard({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(ticker['lastPrice'] ?? '0') ?? 0;
    final priceChange = double.tryParse(ticker['price24hPcnt'] ?? '0') ?? 0;
    final recommendation = _getAIRecommendation();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticker['symbol'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(
                  priceChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: priceChange >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            // Placeholder for mini chart
            Container(
              height: 50,
              color: Colors.grey.withOpacity(0.2),
              child: const Center(child: Text('Mini Chart')),
            ),
            Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20)),
            Text('${(priceChange * 100).toStringAsFixed(2)}%', style: TextStyle(color: priceChange >= 0 ? Colors.green : Colors.red)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSignalColor(recommendation['signal']),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(recommendation['signal'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            Text(recommendation['reason'], style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getAIRecommendation() {
    // Mock AI logic
    final signals = ['Buy', 'Sell', 'Hold'];
    final reasons = ['RSI oversold', 'MACD crossover', 'MA bullish', 'RSI overbought', 'MA bearish'];
    final signal = signals[DateTime.now().second % 3];
    final reason = reasons[DateTime.now().second % 5];
    return {'signal': signal, 'reason': reason};
  }
}

class RiskDisclaimer extends StatelessWidget {
  const RiskDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Trading involves risk. No guarantee of profit or no loss. Use at your own risk.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

Color _getSignalColor(String signal) {
  switch (signal) {
    case 'Buy':
      return Colors.green;
    case 'Sell':
      return Colors.red;
    case 'Hold':
      return Colors.yellow;
    default:
      return Colors.grey;
  }
}
