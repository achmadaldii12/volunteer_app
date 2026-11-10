import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String q = '';
  bool onlySaved = false;
  EventSort sort = EventSort.soonest;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openSort() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 440),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFEF5350),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Urutkan Kegiatan',
                                style: TextStyle(
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 26),
                              for (final o in const [
                                (EventSort.soonest, 'Tanggal terdekat', Icons.event),
                                (EventSort.popular, 'Paling diminati', Icons.local_fire_department_outlined),
                                (EventSort.points, 'Poin terbanyak', Icons.stars_outlined),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    color: sort == o.$1 ? const Color(0xFFFFEBEE) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setState(() => sort = o.$1);
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                        child: Row(
                                          children: [
                                            Icon(o.$3, color: sort == o.$1 ? const Color(0xFFEF5350) : Colors.grey.shade700, size: 24),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                o.$2,
                                                style: TextStyle(
                                                  color: sort == o.$1 ? const Color(0xFFEF5350) : Colors.grey.shade800,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (sort == o.$1)
                                              const Icon(Icons.check_circle, color: Color(0xFFEF5350), size: 22),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cat = s.searchCategory;
    final list = s.query(category: cat, q: q, sort: sort, onlySaved: onlySaved);
    final primary = Theme.of(context).colorScheme.primary;

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: AppColors.primary,
            showCheckmark: false,
            labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
            onSelected: (_) => onTap(),
          ),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      const Text('Cari Event', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      TextField(
        controller: _ctrl,
        onChanged: (v) => setState(() => q = v),
        decoration: InputDecoration(
          hintText: 'Cari kegiatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: q.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _ctrl.clear();
                    setState(() => q = '');
                  }),
          filled: true,
          fillColor: softOf(context),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              chip('Semua', cat == 'Semua' && !onlySaved, () {
                setState(() => onlySaved = false);
                s.setSearchCategory('Semua');
              }),
              for (final c in kCategories)
                chip(c.name, cat == c.name, () => s.setSearchCategory(c.name)),
              chip('Tersimpan', onlySaved, () => setState(() => onlySaved = !onlySaved)),
            ]),
          ),
        ),
        IconButton(icon: Icon(Icons.tune, color: primary), onPressed: _openSort),
      ]),
      const SizedBox(height: 8),
      Text('${list.length} kegiatan ditemukan', style: TextStyle(color: muted(context), fontSize: 12)),
      const SizedBox(height: 14),

      if (list.isEmpty)
        const SizedBox(
            height: 300,
            child: EmptyState(Icons.search_off, 'Kegiatan tidak ditemukan', 'Coba kata kunci atau kategori lain.'))
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 285,
          ),
          itemBuilder: (context, index) {
            // Menggunakan RepaintBoundary agar render filter kategori menjadi sangat cepat dan instan tanpa jeda
            return RepaintBoundary(
              child: _SearchEventGridCard(list[index]),
            );
          },
        ),
    ]);
  }
}

class _SearchEventGridCard extends StatefulWidget {
  const _SearchEventGridCard(this.e);
  final EventModel e;

  @override
  State<_SearchEventGridCard> createState() => _SearchEventGridCardState();
}

class _SearchEventGridCardState extends State<_SearchEventGridCard> {
  bool _isHovered = false;

  String _getDynamicDeadlineText(DateTime eventDate) {
    final target = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final deadlineDate = target.subtract(const Duration(days: 3));
    return 'Batas registrasi ${fmtDate(deadlineDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final catInfo = categoryInfo(widget.e.category);
    final isDarkMode = isDark(context);

    final Color normalColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color hoverColor = isDarkMode ? const Color(0xFF321A1A) : const Color(0xFFFFEBEE);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? hoverColor : normalColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? const Color(0xFFEF9A9A) : Colors.grey.withOpacity(0.18),
            width: _isHovered ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.03),
              blurRadius: _isHovered ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailScreen(widget.e)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 115,
                        width: double.infinity,
                        child: EventImage(widget.e, width: double.infinity, height: 115, radius: 0),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                        color: Colors.black.withOpacity(0.65),
                        child: Text(
                          _getDynamicDeadlineText(widget.e.date),
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: softOf(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.e.category,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: catInfo.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 30,
                        child: Text(
                          widget.e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.e.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: muted(context),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 10, color: muted(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fmtDate(widget.e.date),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.group_outlined, size: 10, color: muted(context)),
                          const SizedBox(width: 4),
                          Text(
                            '${s.participants(widget.e)} Relawan',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      StatusChip(
                        widget.e.priceText,
                        widget.e.isPaid ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}