import 'package:flutter/material.dart';
import '../wallet_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _selectUser(BuildContext context, String user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WalletScreen(benutzer: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Split', style: TextStyle(fontSize: 24)),
        centerTitle: true, // Titel zentriert
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optionaler Bereich für Willkommensnachricht oder Logo
            const Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Text(
                'Willkommen!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            // Benutzerbuttons C und D
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Button für Benutzer "C"
                _buildUserButton(
                    context, 'C', const Color.fromARGB(255, 218, 143, 114)),
                const SizedBox(width: 40), // Abstand zwischen den Buttons
                // Button für Benutzer "D"
                _buildUserButton(
                    context, 'D', const Color.fromARGB(255, 95, 152, 226)),
              ],
            ),

            // Optionaler Bereich für andere Aktionen
            const SizedBox(height: 60),
            ElevatedButton.icon(
              onPressed: () {
                // Button Aktion zum Hinzufügen weiterer Benutzer
              },
              icon: const Icon(Icons.add),
              label: const Text('Benutzer hinzufügen'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Methode zur Erstellung der Benutzerbuttons
  Widget _buildUserButton(BuildContext context, String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        // Navigation zur Wallet-Ansicht für Benutzer "C" oder "D"
        _selectUser(context, label);
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(24),
        backgroundColor: color, // Hintergrundfarbe
        foregroundColor: Colors.white, // Textfarbe
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
      ),
    );
  }
}
