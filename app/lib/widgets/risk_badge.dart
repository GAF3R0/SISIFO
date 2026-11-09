import 'package:flutter/material.dart';
import '../utils/phq9_helper.dart';

/// Badge visual que muestra el nivel de riesgo de depresión
class RiskBadge extends StatelessWidget {
  final String riskLevel; // none | mild | moderate | moderately_severe | severe
  final double fontSize;
  final EdgeInsets padding;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  String get _label {
    switch (riskLevel) {
      case 'none':
        return 'Sin riesgo';
      case 'mild':
        return 'Leve';
      case 'moderate':
        return 'Moderado';
      case 'moderately_severe':
        return 'Moderadamente severo';
      case 'severe':
        return 'Severo';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getRiskColor(riskLevel);
    final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
