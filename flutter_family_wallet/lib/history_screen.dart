import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'transaction_form.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;

  String? selectedUser;
  String? selectedTransactionType;
  DateTime? selectedMonth;

  List<dynamic> transactions = [];
  bool isLoading = false;
  int limit = 20; // max. Anzahl der Einträge je Seite
  int offset = 0; // StartIndex für aktuelle Seite
  int currentPage = 1; // aktuelle Seite
  int totalItems = 0; // Gesamte Anzahl der Einträge in der DB
  TextEditingController pageController =
      TextEditingController(); // Controller für das Seitenzahl-Eingabefeld

  @override
  void initState() {
    super.initState();
    _fetchTotalCount();
    _fetchTransactions();
  }

  // Abfrage der Einträge für aktuelle Liste
  Future<void> _fetchTransactions() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    try {
      var query = supabase
          .from('transaktionen')
          .select('*')
          .order('datum', ascending: false)
          .range(offset, offset + limit - 1);

      var queryFilter = supabase.from('transaktionen').select('*');
      bool isFiltered = false;

      // Benutzerfilter
      if (selectedUser != null && selectedUser != 'Alle') {
        queryFilter = queryFilter.eq('benutzer', selectedUser as Object);
        isFiltered = true;
      }

      // Filter nach Transaktionstyp (Kauf oder Verkauf)
      if (selectedTransactionType != null &&
          selectedTransactionType != 'Alle') {
        if (selectedTransactionType == 'Kauf') {
          queryFilter = queryFilter.lt('preis', 0); // Käufe: Preis < 0
        } else if (selectedTransactionType == 'Verkauf') {
          queryFilter = queryFilter.gt('preis', 0); // Verkäufe: Preis > 0
        }
        isFiltered = true;
      }

      // Filter nach Monat
      if (selectedMonth != null) {
        DateTime startDate =
            DateTime(selectedMonth!.year, selectedMonth!.month, 1);
        DateTime endDate = //DateTime.now();
            DateTime(selectedMonth!.year, selectedMonth!.month + 1, 0);

        // Verwandle Datum in das passende String-Format
        String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
        String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

        queryFilter =
            queryFilter.gte('datum', startDateStr).lte('datum', endDateStr);
        isFiltered = true;
      }
      // Sortieren
      queryFilter.order('datum', ascending: false);
      // Limit und Offset für die Paginierung
      queryFilter.range(offset, offset + limit - 1);

      // Führe die Abfrage mit der Zähloption aus
      final response = isFiltered ? await queryFilter : await query;

      setState(() {
        transactions = response;
        isLoading = false;
      });
    } on PostgrestException catch (error) {
      setState(() {
        isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: ${error.message}')),
      );
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unbekannter Fehler: $error')),
      );
    }
  }

// Berechne die Gesamtzahl der Einträge für die Paginierung
  Future<void> _fetchTotalCount() async {
    try {
      final countResponse = await supabase
          .from('transaktionen')
          .select('*')
          //.withHead(true) // Statt 'head: true'
          .count(CountOption.exact); // Statt 'count: CountOption.exact'
      setState(() {
        totalItems = countResponse.count;
      });
    } catch (error) {
      print('Fehler beim Abrufen der Gesamtanzahl: $error');
    }
  }

  // Berechne die Gesamtzahl der Seiten basierend auf den totalItems und dem Limit pro Seite
  int get totalPages => (totalItems / limit).ceil();

  // Funktion, um zur nächsten Seite zu wechseln
  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        offset += limit;
        currentPage++;
        _fetchTransactions();
      });
    }
  }

  // Funktion, um zur vorherigen Seite zu wechseln
  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        offset -= limit;
        currentPage--;
        _fetchTransactions();
      });
    }
  }

  // Funktion, um zu einer bestimmten Seite zu springen
  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= totalPages) {
      setState(() {
        currentPage = pageNumber;
        offset = (currentPage - 1) *
            limit; // Berechne das Offset für die gewählte Seite
        _fetchTransactions();
      });
    }
  }

  Future<List<String>> _fetchUsers() async {
    try {
      final data = await supabase.from('transaktionen').select('benutzer');

      List<dynamic> benutzerListe = data;
      List<String> users = benutzerListe
          .map((item) => item['benutzer'] as String)
          .toSet()
          .toList();
      return users;
    } catch (error) {
      return [];
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final selected = await showMonthPicker(
      context: context,
      initialDate: selectedMonth ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        selectedMonth = selected;
        // Filter geändert, daher Daten zurücksetzen
        resetTransactions();
      });
    } else {
      // Wenn kein Monat ausgewählt wurde, setze selectedMonth auf null (Alle Monate)
      setState(() {
        selectedMonth = null;
        // Filter geändert, daher Daten zurücksetzen
        resetTransactions();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      // Filter angewendet, daher Daten zurücksetzen
      currentPage = 1;
      resetTransactions();
    });
  }

  void resetTransactions() {
    transactions.clear();
    offset = 0;
    //hasMore = true;
    _fetchTransactions();
  }

  void _navigateToEditTransaction(Map<String, dynamic> transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionForm(
          benutzer: transaction['benutzer'],
          typ: transaction['preis'] < 0 ? 'Kauf' : 'Verkauf',
          transaction: transaction, // Übergabe der Transaktionsdaten
        ),
      ),
    ).then((value) {
      setState(() {
        // Aktualisiere die Daten nach dem Bearbeiten
        resetTransactions();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    /* final formatter =
        NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
 */
    return Scaffold(
        appBar: AppBar(
          title: const Text('Verlauf'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Filter Widgets
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Benutzer-Filter
                  Expanded(
                    child: FutureBuilder<List<String>>(
                      future: _fetchUsers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        } else {
                          List<String> users = ['Alle'] + snapshot.data!;
                          return DropdownButton<String>(
                            value: selectedUser ?? 'Alle',
                            isExpanded: true,
                            onChanged: (value) {
                              setState(() {
                                selectedUser = value;
                                // Filter geändert, daher Daten zurücksetzen
                                resetTransactions();
                              });
                            },
                            items: users.map((user) {
                              return DropdownMenuItem(
                                value: user,
                                child: Text(user),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Transaktionstyp-Filter
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedTransactionType ?? 'Alle',
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          selectedTransactionType = value;
                          // Filter geändert, daher Daten zurücksetzen
                          resetTransactions();
                        });
                      },
                      items: ['Alle', 'Kauf', 'Verkauf'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Monats-Filter
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickMonth,
                  ),
                  selectedMonth != null
                      ? Text(DateFormat.yM().format(selectedMonth!))
                      : const Text('Alle Monate'),
                ],
              ),
            ),
            // Aktualisieren-Button
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Filter anwenden'),
            ),
            // Kopfzeile hinzufügen
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              color: Colors.grey[200],
              child: const Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text('Datum',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 3,
                      child: Text('Bezeichnung',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  //Expanded(flex: 3, child: Text('Notiz', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 2,
                      child: Text('Preis',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Keine Daten vorhanden'),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      //scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        final item = transactions[index];

                        final preisValue = item['preis'];
                        double preis;
                        if (preisValue is int) {
                          preis = preisValue.toDouble();
                        } else if (preisValue is double) {
                          preis = preisValue;
                        } else {
                          preis = 0.0;
                        }

                        final datum = DateTime.parse(item['datum']);
                        final formatter = NumberFormat.currency(
                            locale: 'de_DE', symbol: '€', decimalDigits: 2);

                        // Bestimme den Transaktionstyp basierend auf dem Preis
                        final isKauf = preis < 0;

                        // Bestimme die Hintergrundfarbe
                        final rowColor =
                            isKauf ? Colors.red[100] : Colors.green[100];

                        return GestureDetector(
                          onTap: () {
                            _navigateToEditTransaction(item);
                          },
                          child: Container(
                            color: rowColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(DateFormat.yMd().format(datum)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(item['bezeichnung'] ??
                                      'Keine Bezeichnung'),
                                ),
                                /*  Expanded(
                                  flex: 3,
                                  child: Text(item['notiz'] ?? ''),
                                ), */
                                Expanded(
                                  flex: 2,
                                  child: Text(formatter.format(preis)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Paginierung
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? _previousPage : null,
                  child: const Text('Zurück'),
                ),
                const SizedBox(width: 16),

                // Seitenzahl-Anzeige mit der Möglichkeit, eine Seitenzahl einzugeben
                Row(
                  children: [
                    const Text('Seite '),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: pageController
                          ..text = currentPage.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onSubmitted: (value) {
                          final int? pageNumber = int.tryParse(value);
                          if (pageNumber != null) {
                            _goToPage(pageNumber);
                          }
                        },
                      ),
                    ),
                    Text(' von $totalPages'),
                  ],
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: currentPage < totalPages ? _nextPage : null,
                  child: const Text('Weiter'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ));
  }
}
