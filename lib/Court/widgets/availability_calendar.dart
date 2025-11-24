// lib/court/widgets/availability_calendar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/court_helpers.dart';

class AvailabilityCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Map<DateTime, bool> availabilityMap;
  final Function(DateTime) onDateSelected;
  final bool canManage;

  const AvailabilityCalendar({
    super.key,
    this.selectedDate,
    this.minDate,
    this.maxDate,
    required this.availabilityMap,
    required this.onDateSelected,
    this.canManage = false,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _focusedMonth = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy', 'id_ID').format(_focusedMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _canGoToPreviousMonth() ? _goToPreviousMonth : null,
              color: const Color(0xFF64748B),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _canGoToNextMonth() ? _goToNextMonth : null,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInMonth();
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Column(
      children: List.generate(6, (weekIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (dayIndex) {
            final dayNumber = weekIndex * 7 + dayIndex - startingWeekday + 1;
            
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNumber,
            );

            return Expanded(
              child: _buildDayCell(date),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isSelected = _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;

    final isToday = CourtHelpers.isToday(date);
    final isPast = date.isBefore(DateTime.now()) && !isToday;
    final isOutOfRange = _isOutOfRange(date);
    final isAvailable = widget.availabilityMap[_normalizeDate(date)] ?? true;

    Color backgroundColor = Colors.transparent;
    Color textColor = const Color(0xFF0F172A);
    Color? borderColor;
    bool showDot = false;

    if (isPast || isOutOfRange) {
      textColor = const Color(0xFFCBD5E1);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFCBED98);
      textColor = const Color(0xFF1F2B15);
    } else if (isToday) {
      borderColor = const Color(0xFFCBED98);
    }

    if (!isPast && !isOutOfRange) {
      showDot = !isAvailable;
    }

    return GestureDetector(
      onTap: (!isPast && !isOutOfRange)
          ? () {
              setState(() => _selectedDate = date);
              widget.onDateSelected(date);
            }
          : null,
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (showDot)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keterangan:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                color: const Color(0xFFCBED98),
                label: 'Tanggal dipilih',
              ),
              _buildLegendItem(
                color: Colors.transparent,
                label: 'Tersedia',
                borderColor: const Color(0xFFE2E8F0),
              ),
              _buildLegendItem(
                color: Colors.transparent,
                label: 'Tidak tersedia',
                showDot: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    Color? borderColor,
    bool showDot = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: borderColor != null
                ? Border.all(color: borderColor)
                : null,
          ),
          child: showDot
              ? const Center(
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.red,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  int _getDaysInMonth() {
    return DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
  }

  bool _canGoToPreviousMonth() {
    if (widget.minDate == null) return true;
    final previousMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month - 1,
    );
    return previousMonth.isAfter(widget.minDate!) ||
        previousMonth.year == widget.minDate!.year &&
            previousMonth.month == widget.minDate!.month;
  }

  bool _canGoToNextMonth() {
    if (widget.maxDate == null) return true;
    final nextMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
    );
    return nextMonth.isBefore(widget.maxDate!) ||
        nextMonth.year == widget.maxDate!.year &&
            nextMonth.month == widget.maxDate!.month;
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
      );
    });
  }

  bool _isOutOfRange(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      return true;
    }
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      return true;
    }
    return false;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

/// Compact version untuk list view
class AvailabilityCalendarCompact extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, bool> availabilityMap;
  final int daysToShow;

  const AvailabilityCalendarCompact({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availabilityMap,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(
      daysToShow,
      (index) => DateTime(
        today.year,
        today.month,
        today.day + index,
      ),
    );

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isAvailable = availabilityMap[_normalizeDate(date)] ?? true;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCBED98)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFCBED98)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'id_ID').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1F2B15)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF1F2B15)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isAvailable ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isAvailable
                        ? const Color(0xFF10B981)
                        : Colors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
