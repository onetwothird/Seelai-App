// File: lib/roles/caretaker/home/widgets/patients_list_section.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class PatientsListSection extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final bool isLoading;
  final bool isDarkMode;
  final dynamic theme;
  final Function(Map<String, dynamic>) onPatientTap;

  const PatientsListSection({
    super.key,
    required this.patients,
    required this.isLoading,
    required this.isDarkMode,
    required this.theme,
    required this.onPatientTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned Patients',
              style: h2.copyWith(
                fontSize: 24,
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isLoading)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
                child: Text(
                  '${patients.length}',
                  style: bodyBold.copyWith(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        
        SizedBox(height: spacingMedium),
        
        Text(
          'Monitor and manage your patients',
          style: body.copyWith(
            color: theme.subtextColor,
            fontSize: 14,
          ),
        ),
        
        SizedBox(height: spacingLarge),
        
        if (isLoading)
          _buildLoadingState()
        else if (patients.isEmpty)
          _buildEmptyState()
        else
          ...patients.map((patient) => Padding(
            padding: EdgeInsets.only(bottom: spacingMedium),
            child: _buildPatientCard(patient),
          )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge * 2),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? primaryLight : primary,
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'Loading patients...',
              style: body.copyWith(
                color: theme.subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge * 2),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : cardShadow,
        border: isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(spacingLarge),
              decoration: BoxDecoration(
                color: isDarkMode 
                  ? primary.withOpacity(0.2)
                  : primaryLight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: isDarkMode ? primaryLight : primary,
              ),
            ),
            SizedBox(height: spacingLarge),
            Text(
              'No Assigned Patients',
              style: h3.copyWith(
                color: theme.textColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'You will see patients assigned to you here',
              style: body.copyWith(
                color: theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] ?? 'Unknown';
    final age = patient['age'] ?? 0;
    final email = patient['email'] ?? '';
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: isDarkMode 
          ? [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : softShadow,
        border: isDarkMode 
          ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
          : Border.all(color: greyLighter.withOpacity(0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPatientTap(patient),
          borderRadius: BorderRadius.circular(radiusLarge),
          child: Padding(
            padding: EdgeInsets.all(spacingLarge),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: h2.copyWith(
                        color: white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: spacingLarge),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: bodyBold.copyWith(
                          fontSize: 17,
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: spacingXSmall),
                      Text(
                        '$age years old',
                        style: caption.copyWith(
                          fontSize: 14,
                          color: theme.subtextColor,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          email,
                          style: caption.copyWith(
                            fontSize: 12,
                            color: theme.subtextColor.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(radiusSmall),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: success,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: spacingSmall),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.subtextColor,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}