// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/themes/constants.dart';

class HeaderSection extends StatelessWidget {
  final String caretakerName;
  final bool isDarkMode;
  final int pendingRequestsCount;
  final VoidCallback onToggleDarkMode;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.caretakerName,
    required this.isDarkMode,
    required this.pendingRequestsCount,
    required this.onToggleDarkMode,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    
    return Container(
      padding: EdgeInsets.all(width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $caretakerName',
                      style: h1.copyWith(
                        fontSize: width * 0.075,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: spacingXSmall),
                    Text(
                      formattedDate,
                      style: body.copyWith(
                        fontSize: width * 0.04,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                decoration: BoxDecoration(
                  boxShadow: isDarkMode
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : softShadow,
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Material(
                  color: isDarkMode
                      ? accent.withOpacity(0.25)
                      : primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(radiusMedium),
                  child: InkWell(
                    onTap: onToggleDarkMode,
                    borderRadius: BorderRadius.circular(radiusMedium),
                    child: Container(
                      padding: EdgeInsets.all(spacingMedium),
                      child: Icon(
                        isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 28,
                        color: isDarkMode ? accent : primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacingMedium),
          
        ],
      ),
    );
  }
}