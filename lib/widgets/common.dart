import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../models/farmer.dart';
import '../utils/formatters.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BrandMarkPainter(),
      ),
    );
  }
}

class BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..color = AppColors.brandBlue;
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandGreen;

    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * 0.8 * math.cos(angle),
        center.dy + radius * 0.8 * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, outer);

    final innerPath = Path()
      ..moveTo(size.width * 0.28, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.50)
      ..lineTo(size.width * 0.56, size.height * 0.38)
      ..lineTo(size.width * 0.72, size.height * 0.38);
    canvas.drawPath(innerPath, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FfBioworksLogo extends StatelessWidget {
  const FfBioworksLogo({super.key, this.width = 144});

  final double width;

  @override
  Widget build(BuildContext context) {
    final markSize = width * 0.42;
    return SizedBox(
      width: width,
      height: width * 0.56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: markSize,
            height: markSize * 0.72,
            child: CustomPaint(painter: _FfLeafPainter()),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'FF ',
                  style: TextStyle(color: AppColors.brandBlue),
                ),
                TextSpan(
                  text: 'Bioworks',
                  style: TextStyle(color: AppColors.brandGreenDark),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: width * 0.15,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FfLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.brandBlue;
    final green = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.brandGreen;

    final left = Path()
      ..moveTo(size.width * 0.10, size.height * 0.54)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.08,
        size.width * 0.50,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.86,
        size.width * 0.10,
        size.height * 0.54,
      );
    final right = Path()
      ..moveTo(size.width * 0.50, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.08,
        size.width * 0.90,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.86,
        size.width * 0.50,
        size.height * 0.34,
      );
    final stem = Path()
      ..moveTo(size.width * 0.26, size.height * 0.58)
      ..lineTo(size.width * 0.44, size.height * 0.58)
      ..lineTo(size.width * 0.60, size.height * 0.42)
      ..lineTo(size.width * 0.76, size.height * 0.42);

    canvas.drawPath(left, blue);
    canvas.drawPath(right, blue);
    canvas.drawPath(stem, green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      backgroundColor: AppColors.surfaceMuted,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.heroMist,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.inbox_outlined,
                color: AppColors.heroForest,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.highlighted = false,
    this.useInnerPadding = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final bool highlighted;
  final bool useInnerPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.brandGreen : AppColors.cardBorder,
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D111827),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: useInnerPadding ? const EdgeInsets.all(16) : EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class InfoPair extends StatelessWidget {
  const InfoPair({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon:
            const Icon(Icons.search, size: 20, color: AppColors.heroForest),
        fillColor: const Color(0xFFF4F5F8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
    this.description,
    this.subtitle,
    this.footer,
    this.onBack,
  });

  final String title;
  final Widget child;
  final bool showBack;
  final String? description;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (showBack)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: onBack ?? () => context.pop(),
                              icon: const Icon(Icons.arrow_back),
                            ),
                          ),
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                child: child,
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class FarmerDetailSummary extends StatelessWidget {
  const FarmerDetailSummary({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final farmerCode = farmer.id.hashCode.abs().toString().padLeft(6, '0');
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  farmer.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(
                label: farmer.status.label,
                background: farmer.status.backgroundColor,
                foreground: farmer.status.foregroundColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          InfoPair(label: 'Farmer ID'.tr, value: farmerCode.substring(0, 6)),
          const SizedBox(height: 8),
          InfoPair(label: 'Phone'.tr, value: farmer.phone),
          const SizedBox(height: 8),
          InfoPair(label: 'Address'.tr, value: farmer.location),
          const SizedBox(height: 12),
          FarmerPlotLocationSection(farmer: farmer),
          const SizedBox(height: 8),
          InfoPair(
            label: 'Land Area'.tr,
            value: '${farmer.totalLandAcres.toStringAsFixed(1)} Acre',
          ),
          const SizedBox(height: 8),
          InfoPair(label: 'Crop'.tr, value: farmer.crop),
        ],
      ),
    );
  }
}

class FarmerPlotLocationSection extends StatelessWidget {
  const FarmerPlotLocationSection({super.key, required this.farmer});

  final FarmerProfile farmer;

  @override
  Widget build(BuildContext context) {
    final plotLocation = farmer.plotLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plot Location',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          plotLocation?.displayAddress ?? 'Not captured',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        if (plotLocation != null) ...[
          const SizedBox(height: 8),
          Text(
            'Coordinates: ${plotLocation.coordinatesLabel}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Captured: ${formatDateTime(plotLocation.capturedAt)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final success = await context
                    .read<AppState>()
                    .openFarmerPlotLocation(farmer.id);
                if (context.mounted) {
                  showMockSnackBar(
                    context,
                    success ? 'Map opened.' : 'Unable to open the map.',
                  );
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: Text('Open in Map'.tr),
            ),
          ),
        ],
      ],
    );
  }
}

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateSelected,
  });

  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2025),
          lastDate: DateTime(2027),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatDate(initialDate)),
      ),
    );
  }
}

class TimePickerField extends StatelessWidget {
  const TimePickerField({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onTimeSelected,
  });

  final String label;
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(initialTime.format(context)),
      ),
    );
  }
}

ButtonStyle filledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.brandGreen,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.35),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

void showMockSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
