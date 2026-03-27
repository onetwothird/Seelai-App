import 'package:flutter/material.dart';

// Refined pastel color palette with accessibility in mind
const primary = Color(0xFF7C3AED); // Vibrant modern purple
const primaryLight = Color(0xFFA78BFA); // Light purple
const primaryDark = Color(0xFF6D28D9);
const modernPurpleLight = Color(0xFFEDE9FE); // Ultra-light purple for tinted card backgrounds
const secondary = Color(0xFFEC4899); // Pink accent
const accent = Color(0xFF14B8A6); // Teal
const accentLight = Color(0xFF5EEAD4);

// Soft pastel backgrounds
const backgroundPrimary = Color(0xFFFAFAFA);
const backgroundSecondary = Color(0xFFF5F3FF); // Soft purple tint
const backgroundTertiary = Color(0xFFFDF2F8); // Soft pink tint

// Neutral colors
const white = Colors.white;
const black = Color(0xFF1F2937); // Warm dark gray
const grey = Color(0xFF6B7280);
const greyLight = Color(0xFF9CA3AF);
const greyLighter = Color(0xFFE5E7EB);
const lightBlue = Color(0xFFE5E7EB); // Added missing color (same as greyLighter for consistency)

// Semantic colors
const success = Color(0xFF10B981);
const successLight = Color(0xFFD1FAE5);
const error = Color(0xFFEF4444);
const errorLight = Color(0xFFFEE2E2);
const warning = Color(0xFFF59E0B);
const info = Color(0xFF3B82F6);

// Enhanced gradients with more depth
const primaryGradient = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const accentGradient = LinearGradient(
  colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const softGradient = LinearGradient(
  colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// Typography - Chunky & Bold for the modern aesthetic
const h1 = TextStyle(
  fontSize: 34,
  fontWeight: FontWeight.w900, // Maximum boldness
  color: black,
  letterSpacing: -1.0, // Tighter tracking
  height: 1.2,
);

const h2 = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w800, // Extra bold
  color: black,
  letterSpacing: -0.8,
  height: 1.3,
);

const h3 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800, // Extra bold
  color: black,
  letterSpacing: -0.5,
  height: 1.4,
);

const body = TextStyle(
  fontSize: 16,
  color: grey,
  height: 1.6,
  fontWeight: FontWeight.w500, // Slightly heavier for better legibility
  letterSpacing: 0.1,
);

const bodyBold = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700, // Heavy weight to stand out
  color: black, // Darker color to pop against backgrounds
  height: 1.6,
  letterSpacing: 0.1,
);

const caption = TextStyle(
  fontSize: 14,
  color: greyLight,
  fontWeight: FontWeight.w600, // Bolder captions
  letterSpacing: 0.2,
);

const small = TextStyle(
  fontSize: 12,
  color: greyLight,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.3,
);

// Refined shadow system for depth
const softShadow = [
  BoxShadow(
    color: Color(0x0A7C3AED), // Very subtle purple tint
    blurRadius: 24,
    offset: Offset(0, 8),
    spreadRadius: -4,
  ),
];

const mediumShadow = [
  BoxShadow(
    color: Color(0x1A7C3AED),
    blurRadius: 30,
    offset: Offset(0, 8),
    spreadRadius: -4,
  ),
  BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 15,
    offset: Offset(0, 4),
    spreadRadius: -3,
  ),
];

const strongShadow = [
  BoxShadow(
    color: Color(0x257C3AED),
    blurRadius: 40,
    offset: Offset(0, 12),
    spreadRadius: -6,
  ),
  BoxShadow(
    color: Color(0x12000000),
    blurRadius: 20,
    offset: Offset(0, 6),
    spreadRadius: -4,
  ),
];

const glowShadow = [
  BoxShadow(
    color: Color(0x407C3AED),
    blurRadius: 50,
    offset: Offset(0, 0),
    spreadRadius: 2,
  ),
];

const cardShadow = [
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 25,
    offset: Offset(0, 6),
    spreadRadius: -5,
  ),
  BoxShadow(
    color: Color(0x05000000),
    blurRadius: 12,
    offset: Offset(0, 3),
    spreadRadius: -3,
  ),
];

// Border radius values - Bubbly / Pill-like
const radiusSmall = 16.0; // Bumped up
const radiusMedium = 24.0; // Ideal for inner cards/buttons
const radiusLarge = 32.0; // Ideal for main wrapper cards
const radiusXLarge = 40.0;
const radiusPill = 100.0; // Added for completely round buttons/badges

// Spacing values
const spacingXSmall = 4.0;
const spacingSmall = 8.0;
const spacingMedium = 16.0;
const spacingLarge = 24.0;
const spacingXLarge = 32.0;
const spacingXXLarge = 48.0;