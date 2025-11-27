// lib/court/screens/court_detail_screen.dart

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/court.dart';
import '../services/court_service.dart';
import '../utils/court_helpers.dart';
import 'edit_court_screen.dart';

class CourtDetailScreen extends StatefulWidget {
  final int courtId;

  const CourtDetailScreen({
    super.key,
    required this.courtId,
  });

  @override
  State<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends State<CourtDetailScreen> {
  Court? _court;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  bool _isAvailable = true;
  bool _canManage = false;
  bool _isCheckingAvailability = false;

  @override
  void initState() {
    super.initState();
    _loadCourtDetail();
  }

  Future<void> _loadCourtDetail() async {
    await CourtHelpers.ensureLocaleData();

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final courtService = context.read<CourtService>();
      final court = await courtService.getCourtDetail(widget.courtId);
      final availability = await courtService.getAvailability(
        widget.courtId,
        _selectedDate,
      );
      final availableNow = availability['available'] ?? true;

      if (mounted) {
        setState(() {
          _court = court.copyWith(isAvailable: availableNow);
          _isAvailable = availableNow;
          _canManage = availability['can_manage'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading court: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAvailability() async {
    setState(() => _isCheckingAvailability = true);

    try {
      final courtService = context.read<CourtService>();
      final availability = await courtService.getAvailability(
        widget.courtId,
        _selectedDate,
      );
      final availableNow = availability['available'] ?? true;

      if (mounted) {
        setState(() {
          _isAvailable = availableNow;
          _canManage = availability['can_manage'] ?? false;
          if (_court != null) {
            _court = _court!.copyWith(isAvailable: availableNow);
          }
          _isCheckingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingAvailability = false);
        developer.log('Error checking availability', error: e);
      }
    }
  }

  Future<void> _setAvailability(bool available) async {
    try {
      final courtService = context.read<CourtService>();
      final success = await courtService.setAvailability(
        widget.courtId,
        _selectedDate,
        available,
      );

      if (success && mounted) {
        setState(() {
          _isAvailable = available;
          if (_court != null) {
            _court = _court!.copyWith(isAvailable: available);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              available
                  ? 'Berhasil menandai tersedia'
                  : 'Berhasil menandai tidak tersedia',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui ketersediaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookViaWhatsApp() async {
    try {
      final courtService = context.read<CourtService>();
      final dateStr = CourtHelpers.formatDateForApi(_selectedDate);
      final link = await courtService.getWhatsAppLink(
        widget.courtId,
        date: dateStr,
      );

      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
  }

  Future<void> _navigateToEditCourt() async {
    if (_court == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCourtScreen(court: _court!, courtService: context.read<CourtService>(),),
      ),
    );
    if (updated == true && mounted) {
      _loadCourtDetail();
    }
  }

  Future<void> _deleteCourt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Hapus Lapangan?'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan. Data lapangan akan hilang secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, hapus sekarang'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        final courtService = context.read<CourtService>();
        final success = await courtService.deleteCourt(widget.courtId);

        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lapangan berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus lapangan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Detail Lapangan'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCBED98)),
          ),
        ),
      );
    }

    if (_court == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Detail Lapangan'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
        ),
        body: const Center(child: Text('Court not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildImage(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          if (_canManage) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
                onPressed: _navigateToEditCourt,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteCourt,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _court!.imageUrl != null
            ? Image.network(
                _court!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.sports_tennis,
          size: 80,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 80,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadges(),
          const SizedBox(height: 16),
          Text(
            _court!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_court!.sportDisplayName} • ${_court!.location}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.8,
              color: Color(0xFF64748B),
            ),
          ),
          if (_court!.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection('DESCRIPTION', _court!.description),
          ],
          const SizedBox(height: 24),
          _buildSection('ADDRESS', _court!.address),
          const SizedBox(height: 24),
          _buildFacilities(),
          const SizedBox(height: 32),
          _buildPriceCard(),
          const SizedBox(height: 24),
          _buildBookingSection(),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _court!.isAvailable
                ? const Color(0xFFCBED98).withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _court!.isAvailable
                  ? const Color(0xFFCBED98)
                  : Colors.red,
            ),
          ),
          child: Text(
            _court!.isAvailable ? 'TERSEDIA' : 'PENUH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: _court!.isAvailable
                  ? const Color(0xFF10B981)
                  : Colors.red[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildRatingBadge(),
      ],
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 16,
              color: index < _court!.rating.floor()
                  ? Colors.amber
                  : const Color(0xFFE2E8F0),
            );
          }),
          const SizedBox(width: 8),
          Text(
            '${CourtHelpers.formatRating(_court!.rating)}/5.0',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FACILITIES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _court!.facilitiesList.map((facility) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    facility,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRICE PER HOUR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            CourtHelpers.formatPrice(_court!.price),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TANGGAL RESERVASI',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: CourtHelpers.getMinDate(),
              lastDate: CourtHelpers.getMaxDate(),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              _checkAvailability();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    CourtHelpers.formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isCheckingAvailability)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? const Color(0xFFCBED98).withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isAvailable
                    ? const Color(0xFFCBED98)
                    : Colors.red,
              ),
            ),
            child: Text(
              _isAvailable
                  ? 'Lapangan tersedia pada ${CourtHelpers.formatDate(_selectedDate)}.'
                  : 'Lapangan tidak tersedia pada ${CourtHelpers.formatDate(_selectedDate)}.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isAvailable
                    ? const Color(0xFF10B981)
                    : Colors.red[700],
              ),
            ),
          ),
        if (_canManage) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAvailable ? null : () => _setAvailability(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    foregroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: const Text('Tandai Tersedia'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      !_isAvailable ? null : () => _setAvailability(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: const Text('Tidak Tersedia'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAvailable ? _bookViaWhatsApp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message),
                SizedBox(width: 8),
                Text(
                  'BOOK VIA WHATSAPP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
