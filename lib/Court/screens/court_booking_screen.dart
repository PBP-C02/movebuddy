import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/court_api_helper.dart';

class CourtBookingScreen extends StatefulWidget {
  final int courtId;
  final DateTime preSelectedDate;

  const CourtBookingScreen({
    Key? key,
    required this.courtId,
    required this.preSelectedDate,
  }) : super(key: key);

  @override
  State<CourtBookingScreen> createState() => _CourtBookingScreenState();
}

class _CourtBookingScreenState extends State<CourtBookingScreen> {
  bool _isLoading = false;

  Future<void> _openWhatsapp(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak bisa membuka WhatsApp di perangkat ini"),
        ),
      );
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);

    // 1. Ambil CookieRequest dari Provider
    final request = context.read<CookieRequest>();
    final api = CourtApiHelper(request);

    // Format tanggal: YYYY-MM-DD
    final dateStr =
        "${widget.preSelectedDate.year}-${widget.preSelectedDate.month.toString().padLeft(2, '0')}-${widget.preSelectedDate.day.toString().padLeft(2, '0')}";

    try {
      final response = await api.createBooking(widget.courtId, dateStr);
      final waLink = await api.generateWhatsappLink(
        widget.courtId,
        dateStr: dateStr,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking Berhasil! ${response['message'] ?? ''}"),
            backgroundColor: Colors.green,
          ),
        );

        if (waLink != null) {
          await _openWhatsapp(waLink);
        }

        // Kembali ke halaman list (pop 2x: dari booking -> detail -> list)
        // Atau pop sekali ke detail
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Tampilkan pesan error (misal: saldo kurang, atau sudah dibooking orang lain)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal Booking: ${e.toString().replaceAll('Exception:', '')}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format tampilan tanggal
    final displayDate =
        "${widget.preSelectedDate.day}/${widget.preSelectedDate.month}/${widget.preSelectedDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Konfirmasi Booking",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Pesanan",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _rowInfo("Tanggal", displayDate),
                    const Divider(),
                    _rowInfo("Status", "Siap di-booking"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF5E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Kami akan mengarahkan Anda ke WhatsApp pemilik setelah booking berhasil.",
                              style: TextStyle(color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2E2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Konfirmasi Booking",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
