import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'widgets/prescription_viewer.dart';

class HistoryScreen extends StatefulWidget {
  final User doctor;
  const HistoryScreen({super.key, required this.doctor});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default: Show history for the last 30 days
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final results = await _apiService.getPrescriptionsRaw(
      doctorId: widget.doctor.id,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
    if (mounted) {
      setState(() {
        _history = results;
        _isLoading = false;
      });
      _applySearch();
    }
  }

  void _onSearchChanged() {
    _applySearch();
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistory = _history.where((item) {
        final name = (item['patient_name'] ?? "").toString().toLowerCase();
        final id = (item['patient_id'] ?? "").toString().toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFE6),
      appBar: AppBar(
        title: Text("PATIENT HISTORY".toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredHistory.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(context.r.hPad, 0, context.r.hPad, 20),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) => _buildHistoryCard(_filteredHistory[index]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search name or ID...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                icon: Icon(Icons.search, color: AppColors.primary, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _selectedDateRange == null 
                      ? "Select Date Range" 
                      : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    String dateStr = item['consultation_date'] ?? "N/A";
    if (dateStr != "N/A") {
      try {
        dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(color: Color(0xFFF3EFE6), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['patient_name'] ?? "Unknown Patient",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(height: 4),
                  const Text("VIEW RX", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ).onTap(() {
                if (item['image_urls'] != null && (item['image_urls'] as List).isNotEmpty) {
                  List<Map<String, String>> historyRecords = [];
                  for (var url in item['image_urls']) {
                    historyRecords.add({
                      'url': url.toString(),
                      'date': dateStr,
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionViewer(
                        records: historyRecords,
                        patientName: item['patient_name'] ?? "Patient",
                      ),
                    ),
                  );
                }
              }),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF3EFE6)),
          const SizedBox(height: 16),
          // User requested info rows
          _buildInfoRow(Icons.cake_rounded, "Age", "${item['age'] ?? 'N/A'} Years"),
          _buildInfoRow(Icons.calendar_month_rounded, "DOB", _formatDOB(item['birth_date'])),
          _buildInfoRow(Icons.bloodtype_rounded, "Blood Group", item['blood_group'] ?? "N/A"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF3EFE6), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.medical_services_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text("Doctor: ", style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
                Text(item['doctor_name'] ?? "Unknown Doctor", style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey[300]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDOB(dynamic dob) {
    if (dob == null || dob.toString().isEmpty) return "N/A";
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dob.toString()));
    } catch (_) {
      return dob.toString();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No clinical records found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Extension to allow .onTap on any widget
extension OnTapExt on Widget {
  Widget onTap(VoidCallback action) {
    return GestureDetector(
      onTap: action,
      behavior: HitTestBehavior.opaque,
      child: this,
    );
  }
}

