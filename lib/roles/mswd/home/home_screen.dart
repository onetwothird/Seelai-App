// File: lib/roles/mswd/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';

class MSWDHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MSWDHomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MSWDHomeScreen> createState() => _MSWDHomeScreenState();
}

class _MSWDHomeScreenState extends State<MSWDHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final userName = widget.userData['name'] ?? 'Staff';
    final userEmail = widget.userData['email'] ?? '';
    final userAge = widget.userData['age'] ?? 0;
    final employeeId = widget.userData['employeeId'] ?? 'Not assigned';
    final department = widget.userData['department'] ?? 'Not specified';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAF5FF),
              Color(0xFFFFF1F2),
              Color(0xFFF0FDFA),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.04),

                // Header with logout button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back! 👋',
                            style: body.copyWith(
                              fontSize: screenWidth * 0.04,
                              color: grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (bounds) => primaryGradient.createShader(bounds),
                            child: Text(
                              userName,
                              style: h1.copyWith(
                                fontSize: screenWidth * 0.08,
                                color: white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await authService.value.signOut();
                      },
                      icon: Icon(Icons.logout_rounded),
                      color: primary,
                      iconSize: 28,
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.04),

                // Role Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'MSWD Staff Account',
                        style: bodyBold.copyWith(
                          color: white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Info Cards
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Info Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(radiusLarge),
                            boxShadow: softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.person_rounded, color: white, size: 24),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Profile Information',
                                    style: bodyBold.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildInfoRow('Name', userName),
                              _buildInfoRow('Email', userEmail),
                              _buildInfoRow('Age', '$userAge years old'),
                              _buildInfoRow('Employee ID', employeeId),
                              _buildInfoRow('Department', department),
                              _buildInfoRow('Role', 'MSWD Staff'),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Quick Actions
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(radiusLarge),
                            boxShadow: softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: bodyBold.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Your MSWD staff dashboard is being prepared. More features coming soon!',
                                style: body.copyWith(
                                  color: grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: body.copyWith(
                color: grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: body.copyWith(
                color: black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}