import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../screens/event_detail_screen.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1F1B30) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(isDark(context) ? 0 : .08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class EventImage extends StatelessWidget {
  final EventModel e;
  final double? width, height;
  final double radius;
  const EventImage(this.e, {super.key, this.width, this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final c = categoryInfo(e.category);
    final String imgPath = e.image.trim();
    const String fallbackAsset = 'assets/image/event_4.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          imgPath.isNotEmpty ? imgPath : fallbackAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            fallbackAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: c.color,
              child: Center(
                child: Icon(c.icon, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool light;
  final IconData? icon;
  const PrimaryButton(this.text, {super.key, this.onTap, this.light = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: light ? softOf(context) : AppColors.primary,
          foregroundColor: light ? primary : Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class AppTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool password;
  final bool enabled;
  final int maxLines;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  const AppTextField(this.hint, this.icon,
      {super.key,
      this.password = false,
      this.enabled = true,
      this.maxLines = 1,
      this.controller,
      this.validator,
      this.keyboard});

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        enabled: widget.enabled,
        keyboardType: widget.keyboard,
        maxLines: widget.password ? 1 : widget.maxLines,
        obscureText: widget.password && hide,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, size: 20),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => hide = !hide))
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: border(Colors.grey.shade300),
          enabledBorder: border(Colors.grey.shade300),
          disabledBorder: border(Colors.grey.shade200),
          focusedBorder: border(AppColors.primary, 1.6),
          errorBorder: border(AppColors.danger),
          focusedErrorBorder: border(AppColors.danger, 1.6),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAll;
  const SectionHeader(this.title, {super.key, this.onAll});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (onAll != null)
            GestureDetector(
              onTap: onAll,
              child: Text('Lihat Semua >',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      );
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final double size;
  const InfoRow(this.icon, this.text, {super.key, this.size = 12});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(children: [
          Icon(icon, size: size + 1, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: size), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  const EmptyState(this.icon, this.title, this.subtitle, {super.key, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 36,
                backgroundColor: softOf(context),
                child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: muted(context))),
            if (actionText != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: 200, child: PrimaryButton(actionText!, onTap: onAction)),
            ],
          ]),
        ),
      );
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const StatTile(this.icon, this.value, this.label, {super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: softOf(context), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      );
}

class EventCard extends StatelessWidget {
  final EventModel e;
  final bool compact;
  const EventCard(this.e, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final n = s.participants(e);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
      child: Row(children: [
        EventImage(e, width: 78, height: 78),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            InfoRow(Icons.calendar_today_outlined, fmtDate(e.date)),
            InfoRow(Icons.group_outlined, compact ? '+$n peserta' : '$n peserta'),
            const SizedBox(height: 6),
            StatusChip(
              e.priceText,
              e.isPaid ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
            ),
          ]),
        ),
        if (!compact)
          IconButton(
            icon: Icon(s.isBookmarked(e.id) ? Icons.bookmark : Icons.bookmark_border,
                color: Theme.of(context).colorScheme.primary),
            onPressed: () => s.toggleBookmark(e.id),
          ),
      ]),
    );
  }
}

/// KARTU GRID KHUSUS HALAMAN PENCARIAN (Agar harga muncul di tampilan Grid Cari Event)
class EventGridCard extends StatelessWidget {
  final EventModel e;
  const EventGridCard(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EventImage(e, width: double.infinity, height: 95),
        const SizedBox(height: 6),
        Text(e.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        InfoRow(Icons.calendar_today_outlined, fmtDate(e.date), size: 10),
        const SizedBox(height: 6),
        StatusChip(
          e.priceText,
          e.isPaid ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
        ),
      ]),
    );
  }
}