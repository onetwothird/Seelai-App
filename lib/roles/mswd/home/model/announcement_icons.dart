// File: lib/roles/mswd/home/model/announcement_icons.dart

import 'package:flutter/material.dart';

class AnnouncementIcon {
  final IconData icon;
  final String label;
  final String iconCodePoint;

  AnnouncementIcon({
    required this.icon,
    required this.label,
    required this.iconCodePoint,
  });
}

/// Available announcement icons with their labels
/// Icons are specifically chosen for MSWD announcements to caretakers and visually impaired individuals
final List<AnnouncementIcon> announcementIcons = [
  // General Announcements
  AnnouncementIcon(
    icon: Icons.campaign_rounded,
    label: 'General Announcement',
    iconCodePoint: '0xe047',
  ),
  AnnouncementIcon(
    icon: Icons.info_rounded,
    label: 'Information',
    iconCodePoint: '0xe2fc',
  ),
  AnnouncementIcon(
    icon: Icons.notification_important_rounded,
    label: 'Important Notice',
    iconCodePoint: '0xe362',
  ),
  
  // Emergency & Alerts
  AnnouncementIcon(
    icon: Icons.warning_rounded,
    label: 'Warning',
    iconCodePoint: '0xe88e',
  ),
  AnnouncementIcon(
    icon: Icons.emergency_rounded,
    label: 'Emergency',
    iconCodePoint: '0xe1eb',
  ),
  AnnouncementIcon(
    icon: Icons.notifications_active_rounded,
    label: 'Alert',
    iconCodePoint: '0xe361',
  ),
  
  // Health & Medical
  AnnouncementIcon(
    icon: Icons.medical_services_rounded,
    label: 'Health Service',
    iconCodePoint: '0xe3f3',
  ),
  AnnouncementIcon(
    icon: Icons.healing_rounded,
    label: 'Medical Assistance',
    iconCodePoint: '0xe2e9',
  ),
  AnnouncementIcon(
    icon: Icons.medication_rounded,
    label: 'Medicine Distribution',
    iconCodePoint: '0xf06a',
  ),
  AnnouncementIcon(
    icon: Icons.vaccines_rounded,
    label: 'Vaccination',
    iconCodePoint: '0xe774',
  ),
  AnnouncementIcon(
    icon: Icons.health_and_safety_rounded,
    label: 'Health & Safety',
    iconCodePoint: '0xe2e2',
  ),
  
  // Financial Assistance
  AnnouncementIcon(
    icon: Icons.account_balance_wallet_rounded,
    label: 'Financial Assistance',
    iconCodePoint: '0xe048',
  ),
  AnnouncementIcon(
    icon: Icons.payments_rounded,
    label: 'Cash Assistance',
    iconCodePoint: '0xe85c',
  ),
  AnnouncementIcon(
    icon: Icons.monetization_on_rounded,
    label: 'Subsidy Program',
    iconCodePoint: '0xe3fc',
  ),
  
  // Food & Nutrition
  AnnouncementIcon(
    icon: Icons.restaurant_rounded,
    label: 'Food Distribution',
    iconCodePoint: '0xe561',
  ),
  AnnouncementIcon(
    icon: Icons.lunch_dining_rounded,
    label: 'Meal Program',
    iconCodePoint: '0xea61',
  ),
  AnnouncementIcon(
    icon: Icons.local_grocery_store_rounded,
    label: 'Grocery Assistance',
    iconCodePoint: '0xe3e4',
  ),
  
  // Training & Education
  AnnouncementIcon(
    icon: Icons.school_rounded,
    label: 'Training Program',
    iconCodePoint: '0xe55c',
  ),
  AnnouncementIcon(
    icon: Icons.menu_book_rounded,
    label: 'Workshop',
    iconCodePoint: '0xe3f7',
  ),
  AnnouncementIcon(
    icon: Icons.psychology_rounded,
    label: 'Skills Training',
    iconCodePoint: '0xe8f9',
  ),
  AnnouncementIcon(
    icon: Icons.cast_for_education_rounded,
    label: 'Educational Seminar',
    iconCodePoint: '0xefec',
  ),
  
  // Events & Activities
  AnnouncementIcon(
    icon: Icons.event_rounded,
    label: 'Event',
    iconCodePoint: '0xe24e',
  ),
  AnnouncementIcon(
    icon: Icons.celebration_rounded,
    label: 'Celebration',
    iconCodePoint: '0xe0d0',
  ),
  AnnouncementIcon(
    icon: Icons.local_activity_rounded,
    label: 'Activity',
    iconCodePoint: '0xe3e9',
  ),
  AnnouncementIcon(
    icon: Icons.festival_rounded,
    label: 'Festival',
    iconCodePoint: '0xea68',
  ),
  
  // Community & Social
  AnnouncementIcon(
    icon: Icons.groups_rounded,
    label: 'Community Gathering',
    iconCodePoint: '0xe2d4',
  ),
  AnnouncementIcon(
    icon: Icons.volunteer_activism_rounded,
    label: 'Volunteer Program',
    iconCodePoint: '0xe73f',
  ),
  AnnouncementIcon(
    icon: Icons.diversity_3_rounded,
    label: 'Social Program',
    iconCodePoint: '0xf02d',
  ),
  AnnouncementIcon(
    icon: Icons.handshake_rounded,
    label: 'Partnership',
    iconCodePoint: '0xe8cb',
  ),
  
  // Livelihood & Employment
  AnnouncementIcon(
    icon: Icons.work_rounded,
    label: 'Employment Opportunity',
    iconCodePoint: '0xe8f9',
  ),
  AnnouncementIcon(
    icon: Icons.business_center_rounded,
    label: 'Livelihood Program',
    iconCodePoint: '0xe0c3',
  ),
  AnnouncementIcon(
    icon: Icons.store_rounded,
    label: 'Business Assistance',
    iconCodePoint: '0xe609',
  ),
  
  // Housing & Shelter
  AnnouncementIcon(
    icon: Icons.home_rounded,
    label: 'Housing Program',
    iconCodePoint: '0xe2dc',
  ),
  AnnouncementIcon(
    icon: Icons.roofing_rounded,
    label: 'Shelter Assistance',
    iconCodePoint: '0xf04c',
  ),
  AnnouncementIcon(
    icon: Icons.foundation_rounded,
    label: 'Home Repair',
    iconCodePoint: '0xf03a',
  ),
  
  // Documents & Registration
  AnnouncementIcon(
    icon: Icons.description_rounded,
    label: 'Document Requirements',
    iconCodePoint: '0xe1ff',
  ),
  AnnouncementIcon(
    icon: Icons.assignment_rounded,
    label: 'Registration',
    iconCodePoint: '0xe0b9',
  ),
  AnnouncementIcon(
    icon: Icons.badge_rounded,
    label: 'ID Distribution',
    iconCodePoint: '0xea67',
  ),
  
  // Schedule & Deadlines
  AnnouncementIcon(
    icon: Icons.calendar_today_rounded,
    label: 'Schedule',
    iconCodePoint: '0xe0c6',
  ),
  AnnouncementIcon(
    icon: Icons.schedule_rounded,
    label: 'Appointment',
    iconCodePoint: '0xe55b',
  ),
  AnnouncementIcon(
    icon: Icons.timer_rounded,
    label: 'Deadline',
    iconCodePoint: '0xe622',
  ),
  
  // Support Services
  AnnouncementIcon(
    icon: Icons.support_agent_rounded,
    label: 'Support Service',
    iconCodePoint: '0xf037',
  ),
  AnnouncementIcon(
    icon: Icons.chat_bubble_rounded,
    label: 'Counseling',
    iconCodePoint: '0xe0cb',
  ),
  AnnouncementIcon(
    icon: Icons.phone_in_talk_rounded,
    label: 'Hotline',
    iconCodePoint: '0xe3c1',
  ),
  
  // Transportation
  AnnouncementIcon(
    icon: Icons.directions_bus_rounded,
    label: 'Transport Service',
    iconCodePoint: '0xe1f5',
  ),
  AnnouncementIcon(
    icon: Icons.accessible_rounded,
    label: 'Mobility Assistance',
    iconCodePoint: '0xe037',
  ),
  
  // Disaster & Relief
  AnnouncementIcon(
    icon: Icons.umbrella_rounded,
    label: 'Relief Operation',
    iconCodePoint: '0xf046',
  ),
  AnnouncementIcon(
    icon: Icons.water_drop_rounded,
    label: 'Water Distribution',
    iconCodePoint: '0xf06e',
  ),
  AnnouncementIcon(
    icon: Icons.safety_check_rounded,
    label: 'Safety Drill',
    iconCodePoint: '0xe8f1',
  ),
  
  // Legal & Rights
  AnnouncementIcon(
    icon: Icons.gavel_rounded,
    label: 'Legal Assistance',
    iconCodePoint: '0xe2c1',
  ),
  AnnouncementIcon(
    icon: Icons.policy_rounded,
    label: 'Policy Update',
    iconCodePoint: '0xea17',
  ),
  
  // Recreation & Wellness
  AnnouncementIcon(
    icon: Icons.sports_rounded,
    label: 'Sports Activity',
    iconCodePoint: '0xe5e9',
  ),
  AnnouncementIcon(
    icon: Icons.self_improvement_rounded,
    label: 'Wellness Program',
    iconCodePoint: '0xea78',
  ),
  AnnouncementIcon(
    icon: Icons.spa_rounded,
    label: 'Therapy Session',
    iconCodePoint: '0xe5e8',
  ),
  
  // Technology & Updates
  AnnouncementIcon(
    icon: Icons.update_rounded,
    label: 'System Update',
    iconCodePoint: '0xe923',
  ),
  AnnouncementIcon(
    icon: Icons.phonelink_setup_rounded,
    label: 'App Training',
    iconCodePoint: '0xe3c6',
  ),
  
  // Recognition & Awards
  AnnouncementIcon(
    icon: Icons.star_rounded,
    label: 'Recognition',
    iconCodePoint: '0xe5f8',
  ),
  AnnouncementIcon(
    icon: Icons.emoji_events_rounded,
    label: 'Award',
    iconCodePoint: '0xea23',
  ),
  AnnouncementIcon(
    icon: Icons.card_giftcard_rounded,
    label: 'Incentive',
    iconCodePoint: '0xe0d4',
  ),
  
  // Tips & Guidelines
  AnnouncementIcon(
    icon: Icons.lightbulb_rounded,
    label: 'Tip',
    iconCodePoint: '0xe3ce',
  ),
  AnnouncementIcon(
    icon: Icons.tips_and_updates_rounded,
    label: 'Guidelines',
    iconCodePoint: '0xe79a',
  ),
  
  // Maintenance & Closure
  AnnouncementIcon(
    icon: Icons.build_rounded,
    label: 'Maintenance',
    iconCodePoint: '0xe0c2',
  ),
  AnnouncementIcon(
    icon: Icons.cancel_rounded,
    label: 'Cancellation',
    iconCodePoint: '0xe0c9',
  ),
  AnnouncementIcon(
    icon: Icons.do_not_disturb_rounded,
    label: 'Office Closed',
    iconCodePoint: '0xe1f7',
  ),
];