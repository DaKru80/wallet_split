import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionForm extends StatefulWidget {
  final String benutzer;
  final String typ;
  final Map<String, dynamic>? transaction; // Optionales Transaktionsobjekt

  TransactionForm({
    required this.benutzer,
    required this.typ,
    this.transaction,
  });

  @override
  // ignore: library_private_types_in_public_api
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  String? _bezeichnung;
  String? _notiz;
  double? _preis;
  DateTime _datum = DateTime.now();
  int? _transactionId; // ID der Transaktion für die Aktualisierung

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _bezeichnung = widget.transaction!['bezeichnung'];
      _notiz = widget.transaction!['notiz'];
      _preis = (widget.transaction!['preis'] as num).toDouble().abs();
      _datum = DateTime.parse(widget.transaction!['datum']);
      _transactionId = widget.transaction!['id']; // Speichere die ID
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Preis negativ setzen bei 'Kauf'
      double endPreis = widget.typ == 'Kauf' ? -_preis!.abs() : _preis!.abs();

      final transactionData = {
        'benutzer': widget.benutzer,
        'bezeichnung': _bezeichnung,
        'notiz': _notiz,
        'preis': endPreis,
        'datum': DateFormat('yyyy-MM-dd').format(_datum),
      };

      try {
        if (_transactionId != null) {
          // Aktualisiere bestehende Transaktion
          await _updateTransaction(_transactionId!, transactionData);
        } else {
          // Neue Transaktion erstellen
          await supabase.from('transaktionen').insert(transactionData);
        }

        if (!mounted) return; // Überprüfen, ob das Widget noch aktiv ist

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_transactionId != null
                  ? 'Transaktion aktualisiert'
                  : 'Transaktion gespeichert')),
        );
        Navigator.pop(context);
      } on PostgrestException catch (error) {
        if (!mounted) return; // Überprüfen, ob das Widget noch aktiv ist
        //print('PostgrestException: ${error.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: ${error.message}')),
        );
      } catch (error) {
        if (!mounted) return; // Überprüfen, ob das Widget noch aktiv ist
        //print('Allgemeiner Fehler: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unbekannter Fehler: $error')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? neuesDatum = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (neuesDatum != null) {
      setState(() {
        _datum = neuesDatum;
      });
    }
  }

  // Separate Methode zum Aktualisieren der Transaktion und Speichern der alten Werte
  Future<void> _updateTransaction(int transactionId, Map<String, dynamic> transactionData) async {
    try {
      // Vorherige Transaktion abrufen, um den alten Wert zu speichern
      final previousTransaction = await supabase
          .from('transaktionen')
          .select()
          .eq('id', transactionId)
          .single();

      // Extrahiere die vorherigen Werte (z.B. Bezeichnung, Preis oder Notiz)
      String previousContent = '';
      if (previousTransaction != null) {
        // Definiere hier, welche Felder überwacht werden sollen, z. B. 'bezeichnung'
        previousContent = 'Bezeichnung: ${previousTransaction['bezeichnung']}, '
                          'Preis: ${previousTransaction['preis']}, '
                          'Notiz: ${previousTransaction['notiz']}';
      }

      // Füge das 'updated_text'-Feld hinzu, das den alten Wert speichert
      transactionData['updated_text'] = previousContent;

      // Aktualisiere die bestehende Transaktion
      await supabase
          .from('transaktionen')
          .update(transactionData)
          .eq('id', transactionId);
    } catch (error) {
      //print('Fehler beim Aktualisieren der Transaktion: $error');
      rethrow; // Fehler weiterleiten, um in _saveTransaction gefangen zu werden
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${widget.typ} erfassen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Bezeichnung'),
                    initialValue: _bezeichnung,
                    onSaved: (value) => _bezeichnung = value,
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Notiz (optional)'),
                    initialValue: _notiz,
                    onSaved: (value) => _notiz = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Preis (€)'),
                    initialValue: _preis?.toString(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Bitte einen gültigen Preis eingeben';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        // Beim Speichern des Preises sicherstellen, dass es ein double ist
                        _preis = double.parse(value!.replaceAll(',', '.')),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Datum: ${DateFormat.yMd().format(_datum)}'),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Ändern'),
                      )
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _saveTransaction,
                    child: const Text('Speichern'),
                  )
                ],
              )),
        ));
  }
}
