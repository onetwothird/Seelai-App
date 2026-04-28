// File: lib/roles/mswd/home/sections/profile_content/export_system_report.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed to load assets for the PDF
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:seelai_app/firebase/firebase_services.dart';

class ExportSystemReportScreen extends StatefulWidget {
  final dynamic theme;
  final bool isDarkMode;
  final Map<String, dynamic> userData;

  const ExportSystemReportScreen({
    super.key,
    required this.theme,
    required this.isDarkMode,
    required this.userData,
  });

  @override
  State<ExportSystemReportScreen> createState() => _ExportSystemReportScreenState();
}

class _ExportSystemReportScreenState extends State<ExportSystemReportScreen> {
  final Color _primaryColor = const Color(0xFF8B5CF6);
  
  bool _includeUserStats = true;
  bool _includeRecentLogs = true;
  bool _includePendingApprovals = true;
  String _selectedDateRange = 'Last 30 Days';
  bool _isGenerating = false;

  final List<String> _dateRanges = ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'All Time'];

  Future<void> _generateAndDownloadReport() async {
    if (!_includeUserStats && !_includeRecentLogs && !_includePendingApprovals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one section to include in the report.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final doc = pw.Document();
      final adminName = widget.userData['name'] ?? 'MSWD Administrator';
      final department = widget.userData['department'] ?? 'MSWD General';
      
      // 1. Load the SEELAI Logo from assets
      pw.MemoryImage? logoImage;
      try {
        final ByteData bytes = await rootBundle.load('assets/seelai_app_logo/seelai_app_logo.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('Could not load logo image for PDF: $e');
      }

      // 2. Fetch Data based on selections
      Map<String, int>? userStats;
      List<Map<String, dynamic>>? logs;
      List<Map<String, dynamic>>? pendingCaretakers;

      if (_includeUserStats) {
        userStats = await adminService.getUserStatistics();
      }

      if (_includeRecentLogs) {
        final allLogs = await activityLogsService.getAllActivityLogs(limit: 1000);
        
        if (_selectedDateRange != 'All Time') {
          final days = _selectedDateRange.contains('7') ? 7 : (_selectedDateRange.contains('30') ? 30 : 90);
          final cutoff = DateTime.now().subtract(Duration(days: days));
          logs = allLogs.where((log) {
            if (log['timestamp'] == null) return false;
            return DateTime.fromMillisecondsSinceEpoch(log['timestamp'] as int).isAfter(cutoff);
          }).toList();
        } else {
          logs = allLogs;
        }
      }

      if (_includePendingApprovals) {
        pendingCaretakers = await adminService.getPendingCaretakers();
      }

      // 3. Build the PDF
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(adminName, department, logoImage),
          footer: (context) => _buildPdfFooter(context),
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            content.add(pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#8B5CF6'))));
            content.add(pw.SizedBox(height: 8));
            content.add(pw.Text('This document serves as an official system export for the SEELAI platform under the jurisdiction of the Municipal Social Welfare and Development office. It contains confidential demographic and system usage data.'));
            content.add(pw.SizedBox(height: 24));

            if (_includeUserStats && userStats != null) {
              content.add(_buildSectionTitle('System Demographics & User Statistics'));
              content.add(
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Total Users', userStats['total'].toString()),
                      _buildStatBox('Partially Sighted', userStats['partially_sighted'].toString()),
                      _buildStatBox('Caretakers', userStats['caretaker'].toString()),
                      _buildStatBox('Active Accounts', userStats['active'].toString()),
                    ],
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 24));
            }

            if (_includePendingApprovals && pendingCaretakers != null) {
              content.add(_buildSectionTitle('Pending Caretaker Registrations (${pendingCaretakers.length})'));
              if (pendingCaretakers.isEmpty) {
                content.add(pw.Text('No pending caretakers at this time.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
              } else {
                final tableData = pendingCaretakers.map((ct) => [
                  ct['name'] ?? 'Unknown',
                  ct['email'] ?? 'N/A',
                  ct['relationship'] ?? 'N/A',
                  DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(ct['createdAt'] ?? 0)),
                ]).toList();
                
                content.add(pw.TableHelper.fromTextArray(
                  headers: ['Name', 'Email', 'Relationship', 'Date Registered'],
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey600),
                  cellStyle: pw.TextStyle(fontSize: 10),
                ));
              }
              content.add(pw.SizedBox(height: 24));
            }

            if (_includeRecentLogs && logs != null) {
              content.add(_buildSectionTitle('System Activity Logs ($_selectedDateRange)'));
              if (logs.isEmpty) {
                content.add(pw.Text('No logs found for this period.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
              } else {
                final tableData = logs.map((log) => [
                  DateFormat('MMM dd, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(log['timestamp'] ?? 0)),
                  log['action']?.toString().toUpperCase() ?? 'N/A',
                  log['details'] ?? 'No details',
                ]).toList();

                content.add(pw.TableHelper.fromTextArray(
                  headers: ['Date & Time', 'Action', 'Details'],
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#8B5CF6')),
                  cellStyle: pw.TextStyle(fontSize: 9),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(4),
                  },
                ));
              }
            }

            return content;
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'SEELAI_Master_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- PDF Helper Widgets ---
  pw.Widget _buildPdfHeader(String adminName, String department, pw.MemoryImage? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Left Side: Logo and Title
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null) ...[
                  pw.ClipOval( // Makes the logo circular
                    child: pw.Image(logoImage, width: 38, height: 38, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SEELAI', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#8B5CF6'))),
                    pw.Text('System Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            // Right Side: Metadata
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Generated By: $adminName', style: pw.TextStyle(fontSize: 10)),
                pw.Text('Department: $department', style: pw.TextStyle(fontSize: 10)),
                pw.Text('Date: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#8B5CF6')),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: pw.EdgeInsets.only(top: 10),
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#8B5CF6'))),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
      ]
    );
  }

  // --- Flutter UI ---
  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final Color headerColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF111827);
    final Color subTextColor = widget.isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

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
          'Export System Report',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      body: _isGenerating 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _primaryColor),
                const SizedBox(height: 20),
                Text('Compiling system data...', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('This may take a moment depending on the data size.', style: TextStyle(color: subTextColor, fontSize: 13)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure Report Options',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the specific modules and timeframes you want to include in your official exported document.',
                  style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
                ),
                const SizedBox(height: 32),

                // Checkboxes
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: widget.isDarkMode ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildCheckboxTile(
                        title: 'User Demographics & Statistics',
                        subtitle: 'Total counts of patients, caretakers, and active statuses.',
                        icon: Icons.pie_chart_rounded,
                        value: _includeUserStats,
                        onChanged: (val) => setState(() => _includeUserStats = val ?? false),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, indent: 56, color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      _buildCheckboxTile(
                        title: 'Pending Caretaker Approvals',
                        subtitle: 'List of caretakers currently awaiting MSWD verification.',
                        icon: Icons.how_to_reg_rounded,
                        value: _includePendingApprovals,
                        onChanged: (val) => setState(() => _includePendingApprovals = val ?? false),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, indent: 56, color: widget.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      _buildCheckboxTile(
                        title: 'System Activity Logs',
                        subtitle: 'Detailed chronological record of system events and alerts.',
                        icon: Icons.history_rounded,
                        value: _includeRecentLogs,
                        onChanged: (val) => setState(() => _includeRecentLogs = val ?? false),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Date Range Dropdown
                AnimatedOpacity(
                  opacity: _includeRecentLogs ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_includeRecentLogs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Timeframe (For Logs)',
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
                              value: _selectedDateRange,
                              dropdownColor: cardColor,
                              icon: Icon(Icons.calendar_today_rounded, color: _primaryColor, size: 18),
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                              items: _dateRanges.map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value));
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) setState(() => _selectedDateRange = newValue);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _generateAndDownloadReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: widget.isDarkMode ? 0 : 4,
                      shadowColor: _primaryColor.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Generate & Export Document', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color textColor,
    required Color subTextColor,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: _primaryColor,
      checkColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Icon(icon, size: 20, color: value ? _primaryColor : subTextColor.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 32, top: 4),
        child: Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 13)),
      ),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}