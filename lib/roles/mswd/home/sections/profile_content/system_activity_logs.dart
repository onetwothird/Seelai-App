// File: lib/roles/mswd/home/sections/profile_content/system_activity_logs.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class SystemActivityLogsScreen extends StatefulWidget {
  final dynamic theme;
  final bool isDarkMode;

  const SystemActivityLogsScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<SystemActivityLogsScreen> createState() => _SystemActivityLogsScreenState();
}

class _SystemActivityLogsScreenState extends State<SystemActivityLogsScreen> {
  final Color _primaryColor = const Color(0xFF8B5CF6);
  
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  bool _isLoading = true;
  String _selectedFilter = 'Last 7 Days';

  final List<String> _filterOptions = ['Last 7 Days', 'Last 30 Days', 'All Time'];

  // Pagination Variables
  int _currentPage = 1;
  final int _itemsPerPage = 10; // Change this to show more/less logs per page

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await activityLogsService.getAllActivityLogs(limit: 500);
      setState(() {
        _allLogs = logs;
        _applyFilter(_selectedFilter);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1; // Reset to first page whenever filter changes
      
      if (filter == 'All Time') {
        _filteredLogs = List.from(_allLogs);
        return;
      }

      final now = DateTime.now();
      final daysToSubtract = filter == 'Last 7 Days' ? 7 : 30;
      final cutoffDate = now.subtract(Duration(days: daysToSubtract));

      _filteredLogs = _allLogs.where((log) {
        final timestamp = log['timestamp'];
        if (timestamp == null) return false;
        
        final logDate = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
        return logDate.isAfter(cutoffDate);
      }).toList();
    });
  }

  // Get only the logs for the current page
  List<Map<String, dynamic>> get _paginatedLogs {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    return _filteredLogs.skip(startIndex).take(_itemsPerPage).toList();
  }

  // Formats system strings (e.g., "ACCOUNT_CREATED" -> "Account Created")
  String _formatActionText(String action) {
    if (action.isEmpty) return 'System Event';
    final words = action.replaceAll('_', ' ').split(' ');
    final capitalized = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return capitalized;
  }

  // Assigns specific icons and colors to actions to match the Export UI vibe
  _LogStyle _getLogStyle(String action, Color subTextColor) {
    final upperAction = action.toUpperCase();
    
    if (upperAction.contains('LOGIN') || upperAction.contains('SUCCESS')) {
      return _LogStyle(icon: Icons.login_rounded, color: Colors.teal.shade500);
    } else if (upperAction.contains('ERROR') || upperAction.contains('DELETE') || upperAction.contains('EMERGENCY')) {
      return _LogStyle(icon: Icons.warning_amber_rounded, color: Colors.redAccent.shade400);
    } else if (upperAction.contains('UPDATE') || upperAction.contains('EDIT') || upperAction.contains('ADDED')) {
      return _LogStyle(icon: Icons.edit_note_rounded, color: Colors.orange.shade500);
    } else if (upperAction.contains('CREATE') || upperAction.contains('REGISTER')) {
      return _LogStyle(icon: Icons.person_add_alt_1_rounded, color: Colors.blue.shade500);
    } else if (upperAction.contains('SCAN') || upperAction.contains('DETECT')) {
      return _LogStyle(icon: Icons.document_scanner_rounded, color: _primaryColor);
    } else {
      return _LogStyle(icon: Icons.history_rounded, color: subTextColor.withValues(alpha: 0.8));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Exact color matching from export_system_report.dart
    final Color bgColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final Color headerColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF111827);
    final Color subTextColor = widget.isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final currentLogs = _paginatedLogs;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        surfaceTintColor: headerColor,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        title: Text(
          'System Activity Logs',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _primaryColor),
                const SizedBox(height: 20),
                Text('Retrieving activity records...', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Text exactly like Export Report
                Text(
                  'Live Audit Trail',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review a chronological record of system events, logins, and emergency alerts across the SEELAI platform.',
                  style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
                ),
                const SizedBox(height: 32),

                // Date Range Dropdown
                Text(
                  'Data Timeframe',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedFilter,
                      dropdownColor: cardColor,
                      icon: Icon(Icons.calendar_today_rounded, color: _primaryColor, size: 18),
                      style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                      items: _filterOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) _applyFilter(newValue);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Unified Card Layout
                if (_filteredLogs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 48, color: subTextColor.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No activity records found.', style: TextStyle(color: subTextColor, fontSize: 15)),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          boxShadow: widget.isDarkMode 
                              ? [] 
                              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentLogs.length,
                          itemBuilder: (context, index) {
                            final isLast = index == currentLogs.length - 1;
                            return _buildLogItemTile(currentLogs[index], isLast, textColor, subTextColor);
                          },
                        ),
                      ),
                      
                      // Pagination Controls
                      _buildPaginationControls(textColor, cardColor),
                    ],
                  ),
              ],
            ),
          ),
    );
  }

  // Pagination UI Builder
  Widget _buildPaginationControls(Color textColor, Color cardColor) {
    int totalPages = (_filteredLogs.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    // Previous Button
    pageButtons.add(
      IconButton(
        icon: Icon(Icons.chevron_left_rounded, color: _currentPage > 1 ? textColor : textColor.withValues(alpha: 0.3)),
        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
      ),
    );

    // Calculate Dynamic Page Range (Show up to 5 page numbers at a time)
    int startPage = _currentPage > 2 ? _currentPage - 2 : 1;
    int endPage = startPage + 4 > totalPages ? totalPages : startPage + 4;
    
    if (endPage - startPage < 4 && totalPages > 4) {
      startPage = endPage - 4;
    }

    // Page Numbers
    for (int i = startPage; i <= endPage; i++) {
      bool isSelected = _currentPage == i;
      pageButtons.add(
        GestureDetector(
          onTap: () => setState(() => _currentPage = i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _primaryColor : (widget.isDarkMode ? Colors.white10 : Colors.grey.shade300)
              )
            ),
            child: Text(
              i.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    // Next Button
    pageButtons.add(
      IconButton(
        icon: Icon(Icons.chevron_right_rounded, color: _currentPage < totalPages ? textColor : textColor.withValues(alpha: 0.3)),
        onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageButtons,
      ),
    );
  }

  // Individual Log Tile styled perfectly to match the CheckboxListTile layout
  Widget _buildLogItemTile(Map<String, dynamic> log, bool isLast, Color textColor, Color subTextColor) {
    final actionStr = log['action']?.toString() ?? 'Unknown';
    final style = _getLogStyle(actionStr, subTextColor);
    
    final timestamp = log['timestamp'] as int?;
    final dateStr = timestamp != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp))
        : '--';
    final timeStr = timestamp != null
        ? DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp))
        : '--';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: 20, color: style.color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatActionText(actionStr),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log['details'] ?? 'No details provided.',
                      style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr, 
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    dateStr, 
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Subtle divider separating the list items, matches exactly
        if (!isLast)
          Divider(
            height: 1, 
            indent: 52, 
            color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
          ),
      ],
    );
  }
}

class _LogStyle {
  final IconData icon;
  final Color color;

  _LogStyle({required this.icon, required this.color});
}