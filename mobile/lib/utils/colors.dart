import 'package:flutter/material.dart';

// GigFlow professional color palette — white/light base with emerald green accents
const kBg = Color(0xFFF7F8FA);
const kCard = Color(0xFFFFFFFF);
const kCardAlt = Color(0xFFF0F4F8);
const kBorder = Color(0xFFE5E7EB);
const kBorderLight = Color(0xFFF3F4F6);
const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);
const kTextMuted = Color(0xFF9CA3AF);
const kGreen = Color(0xFF059669);
const kGreenDark = Color(0xFF047857);
const kGreenLight = Color(0xFF10B981);
const kGreenBg = Color(0xFFECFDF5);
const kGreenBorder = Color(0xFFD1FAE5);
const kRed = Color(0xFFEF4444);
const kRedBg = Color(0xFFFEF2F2);
const kAmber = Color(0xFFF59E0B);
const kAmberBg = Color(0xFFFFFBEB);
const kBlue = Color(0xFF3B82F6);
const kBlueBg = Color(0xFFEFF6FF);
const kTeal = Color(0xFF0D9488);

BoxDecoration kCardDecoration({Color? borderColor, List<BoxShadow>? shadows}) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: borderColor ?? kBorder),
  boxShadow: shadows ?? [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
);
