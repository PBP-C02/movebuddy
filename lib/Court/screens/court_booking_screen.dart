import 'package:flutter/material.dart';
import '../helpers/court_api_helper.dart';

class CourtBookingScreen extends StatefulWidget {
  final int courtId;
  final DateTime preSelectedDate;

  const CourtBookingScreen({
    Key? key, 
    required this.courtId, 
    required this.preSelectedDate
  }) : super(key: key);

  @override
  _CourtBookingScreenState createState() => _CourtBookingScreenState();
}

class _CourtBookingScreenState extends State<CourtBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourtApiHelper _api = CourtApiHelper();
  bool _isLoading = false;

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Format YYYY-MM-DD
    String dateStr = "${widget.preSelectedDate.year}-${widget.preSelectedDate.month.toString().padLeft(2,'0')}-${widget.preSelectedDate.day.toString().padLeft(2,'0')}";

    try {
      final response = await _api.createBooking(widget.courtId, dateStr);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Sukses"),
          content: Text("Booking berhasil untuk tanggal $dateStr.\n${response['message']}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke detail
                Navigator.pop(context); // Kembali ke list (opsional)
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal Booking: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Konfirmasi Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Pemesanan", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: "${widget.preSelectedDate.toLocal()}".split(' ')[0],
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Tanggal Booking",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 10),
              // Backend create_booking mengabaikan waktu, jadi kita beri info saja.
              const AlertBox(text: "Booking berlaku untuk satu hari penuh (Full Day)."),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Konfirmasi Booking", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertBox extends StatelessWidget {
  final String text;
  const AlertBox({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}