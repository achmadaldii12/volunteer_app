import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';

export '../core/utils.dart' show fmtDate, fmtDateTime, fmtNum, fmtLongDate;

const kOrgBg = Color(0xFFFAF6F6);
const kOrgLine = Color(0xFFF1E4E4);


void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

Color statusColor(String s) {
  switch (s) {
    case 'published':
    case 'accepted':
      return const Color(0xFF16A34A);
    case 'ongoing':
      return const Color(0xFF2563EB);
    case 'completed':
      return const Color(0xFF6B7280);
    case 'pending':
    case 'draft':
      return const Color(0xFFF59E0B);
    case 'archived':
      return const Color(0xFF64748B);
    default:
      return AppColors.danger; // cancelled / rejected
  }
}

ImageProvider? dataImage(String s) {
  if (s.startsWith('http://') || s.startsWith('https://')) return NetworkImage(s); // gambar dari backend
  if (!s.startsWith('data:')) return null;
  try {
    return MemoryImage(base64Decode(s.substring(s.indexOf(',') + 1)));
  } catch (_) {
    return null;
  }
}

class OrgCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  const OrgCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kOrgLine),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class OrgSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const OrgSection({super.key, required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return OrgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87))),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const StatusPill(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class Avatar extends StatelessWidget {
  final String text;
  final double size;
  final String pic;
  const Avatar(this.text, {super.key, this.size = 38, this.pic = ''});
  @override
  Widget build(BuildContext context) {
    final img = dataImage(pic);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.soft,
      backgroundImage: img,
      child: img != null
          ? null
          : Text(text, style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: size * .34)),
    );
  }
}

String initialsOf(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  if (p.isEmpty || p.first.isEmpty) return '?';
  return p.length == 1 ? p.first[0].toUpperCase() : (p.first[0] + p.last[0]).toUpperCase();
}

class EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyBox(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 40, color: Colors.black26),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45, fontSize: 13)),
          ]),
        ),
      );
}

/// Judul halaman + aksi di kanan.
class PageHead extends StatelessWidget {
  final String title, sub;
  final List<Widget> actions;
  const PageHead(this.title, this.sub, {super.key, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
            Text(sub, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ]),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
        ]),
      );
}

ButtonStyle redBtn({bool small = false}) => ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18, vertical: small ? 8 : 13),
      textStyle: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

ButtonStyle softBtn({bool small = false}) => ElevatedButton.styleFrom(
      backgroundColor: AppColors.soft,
      foregroundColor: AppColors.primaryDark,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18, vertical: small ? 8 : 13),
      textStyle: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

InputDecoration fieldDeco(String? label, {IconData? icon, String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 19),
      filled: true,
      fillColor: const Color(0xFFFFF7F7),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kOrgLine)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kOrgLine)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );

/// Kolom responsif: membagi lebar menjadi [cols] kolom sama besar.
class Grid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth, gap;
  const Grid(this.children, {super.key, this.minWidth = 220, this.gap = 14});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final cols = math.max(1, ((c.maxWidth + gap) / (minWidth + gap)).floor());
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
      });
}

// ================================================================== CHARTS
class LineChart extends StatelessWidget {
  final List<double> a, b;
  final List<String> labels;
  final double height;
  const LineChart({super.key, required this.a, this.b = const [], required this.labels, this.height = 210});
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _LinePainter(a, b, labels)));
}

class _LinePainter extends CustomPainter {
  final List<double> a, b;
  final List<String> labels;
  _LinePainter(this.a, this.b, this.labels);

  void _text(Canvas c, String t, Offset o, {bool right = false, bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: t, style: const TextStyle(fontSize: 10.5, color: Colors.black54)), textDirection: TextDirection.ltr)..layout();
    final dx = right ? o.dx - tp.width : (center ? o.dx - tp.width / 2 : o.dx);
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, bottom = 24.0, top = 8.0;
    final w = size.width - left - 8, h = size.height - bottom - top;
    var mx = 1.0;
    for (final v in [...a, ...b]) {
      mx = math.max(mx, v);
    }
    final step = _niceStep(mx / 4);
    mx = step * 4;
    final grid = Paint()..color = kOrgLine..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      _text(canvas, fmtNum((step * i).round()), Offset(left - 6, y), right: true);
    }
    final n = labels.length;
    if (n == 0) return;
    double x(int i) => n == 1 ? left + w / 2 : left + w * i / (n - 1);
    double y(double v) => top + h - h * (v / mx);
    for (var i = 0; i < n; i++) {
      _text(canvas, labels[i], Offset(x(i), top + h + 14), center: true);
    }
    void series(List<double> v, Color col, {bool fill = false}) {
      if (v.isEmpty) return;
      final p = Path()..moveTo(x(0), y(v[0]));
      for (var i = 1; i < v.length; i++) {
        final cx = (x(i - 1) + x(i)) / 2;
        p.cubicTo(cx, y(v[i - 1]), cx, y(v[i]), x(i), y(v[i]));
      }
      if (fill) {
        final f = Path.from(p)..lineTo(x(v.length - 1), top + h)..lineTo(x(0), top + h)..close();
        canvas.drawPath(f, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withOpacity(.22), col.withOpacity(0)]).createShader(Rect.fromLTWH(0, top, size.width, h)));
      }
      canvas.drawPath(p, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round);
      for (var i = 0; i < v.length; i++) {
        canvas.drawCircle(Offset(x(i), y(v[i])), 4, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x(i), y(v[i])), 3, Paint()..color = col);
      }
    }

    series(b, const Color(0xFFF9A8A8), fill: true);
    series(a, AppColors.primary, fill: b.isEmpty);
  }

  double _niceStep(double raw) {
    if (raw <= 1) return 1;
    final p = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 2.5, 5, 10]) {
      if (raw <= m * p) return m * p;
    }
    return 10 * p;
  }

  @override
  bool shouldRepaint(covariant _LinePainter o) => true;
}

class Donut extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final String center, sub;
  final double size;
  const Donut({super.key, required this.values, required this.colors, required this.center, this.sub = 'Event', this.size = 150});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(values, colors)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ]),
      );
}

class _DonutPainter extends CustomPainter {
  final List<double> v;
  final List<Color> c;
  _DonutPainter(this.v, this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final total = v.fold<double>(0, (a, b) => a + b);
    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 24..color = kOrgLine;
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, base);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < v.length; i++) {
      if (v[i] <= 0) continue;
      final sweep = math.pi * 2 * v[i] / total;
      canvas.drawArc(rect, start, math.max(0.0, sweep - 0.04), false, Paint()..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.butt..color = c[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => true;
}

class HBar extends StatelessWidget {
  final String label;
  final double value, max;
  final Color color;
  final String trailing;
  const HBar(this.label, this.value, this.max, this.color, this.trailing, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(value: max <= 0 ? 0 : (value / max).clamp(0.0, 1.0).toDouble(), minHeight: 10, color: color, backgroundColor: kOrgLine),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 64, child: Text(trailing, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      );
}
