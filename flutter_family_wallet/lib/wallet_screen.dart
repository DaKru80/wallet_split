import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_form.dart';
import 'history_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletScreen extends StatefulWidget {
  final String benutzer;

  WalletScreen({required this.benutzer});

  @override
  // ignore: library_private_types_in_public_api
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchTotalSum();
  }

  Map<String, double> userSums = {};

  Future<void> _fetchTotalSum() async {
    try {
      final data =
          await supabase.from('transaktionen').select('benutzer, preis');

      Map<String, double> sums = {};

      for (var item in data) {
        final preisValue = item['preis'];
        double preis;
        if (preisValue is int) {
          preis = preisValue.toDouble();
        } else if (preisValue is double) {
          preis = preisValue;
        } else {
          preis = 0.0;
        }

        String benutzer = item['benutzer'] ?? 'Unbekannt';

        if (sums.containsKey(benutzer)) {
          sums[benutzer] = sums[benutzer]! + preis;
        } else {
          sums[benutzer] = preis;
        }
      }

      setState(() {
        userSums = sums;
        _calculateDifference();
      });
    } catch (error) {
      //print('Fehler beim Laden der Summe: $error');
    }
  }

  void _navigateToForm(BuildContext context, String typ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionForm(benutzer: widget.benutzer, typ: typ),
      ),
    ).then((value) {
      _fetchTotalSum(); // Aktualisiere die Summe nach Rückkehr
    });
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    ).then((value) {
      _fetchTotalSum(); // Aktualisiere die Summen nach Rückkehr
    });
  }

  String? userWithHigherSum;
  double difference = 0.0;

  void _calculateDifference() {
    if (userSums.length >= 2) {
      List<double> sums = userSums.values.map((e) => e.abs()).toList();
      sums.sort();
      double sum1 = sums[sums.length - 1];
      double sum2 = sums[sums.length - 2];
      difference = sum1 - sum2;

      // Benutzer mit der höchsten Summe finden
      userWithHigherSum = userSums.entries
          .firstWhere((element) => element.value.abs() == sum1)
          .key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Willkommen ${widget.benutzer}'),
        centerTitle: true, // Titel zentriert
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Übersicht der Summen je Benutzer in einem Card-Widget
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summen je Benutzer:',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    for (var entry in userSums.entries)
                      Text(
                        '${entry.key}: ${formatter.format(entry.value)}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    const SizedBox(height: 20),
                    if (userWithHigherSum != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Benutzer mit der höheren Summe:',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$userWithHigherSum',
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Differenz: ${formatter.format(difference)}',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Prominente Buttons für Kauf, Verkauf und Verlauf
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                    context, 'Kauf', Icons.shopping_cart, Colors.redAccent),
                _buildActionButton(
                    context, 'Verkauf', Icons.attach_money, Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 20), // Abstand zwischen den Button-Reihen

            _buildActionButton(
                context, 'Verlauf', Icons.history, Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  // Methode zur Erstellung der Aktionsbuttons
  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {
        if (label == 'Kauf' || label == 'Verkauf') {
          _navigateToForm(context, label);
        } else if (label == 'Verlauf') {
          _navigateToHistory(context);
        }
      },
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 20),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        backgroundColor: color, // Hintergrundfarbe
        foregroundColor: Colors.white, // Textfarbe
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Leicht abgerundete Ecken
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
