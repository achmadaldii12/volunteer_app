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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Urutkan Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          for (final o in const [
            (EventSort.soonest, 'Tanggal terdekat', Icons.event),
            (EventSort.popular, 'Paling diminati', Icons.local_fire_department_outlined),
            (EventSort.points, 'Poin terbanyak', Icons.stars_outlined),
          ])
            ListTile(
              leading: Icon(o.$3),
              title: Text(o.$2),
              trailing: sort == o.$1 ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => sort = o.$1);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
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
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            return _SearchEventGridCard(list[index]);
          },
        ),
    ]);
  }
}

// Widget Kartu Event dengan Efek Hover Background Merah Lembut
class _SearchEventGridCard extends StatefulWidget {
  const _SearchEventGridCard(this.e);
  final EventModel e;

  @override
  State<_SearchEventGridCard> createState() => _SearchEventGridCardState();
}

class _SearchEventGridCardState extends State<_SearchEventGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final catInfo = categoryInfo(widget.e.category);
    final isDarkMode = isDark(context);

    // Menentukan warna background saat kursor diarahkan (Merah lembut tidak terlalu terang)
    final Color normalColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color hoverColor = isDarkMode ? const Color(0xFF321A1A) : const Color(0xFFFFEBEE); // Merah sangat lembut (soft red)

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
                // 1. Gambar Banner
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 125,
                        width: double.infinity,
                        child: EventImage(widget.e, width: double.infinity, height: 125, radius: 0),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: Colors.black.withOpacity(0.65),
                        child: const Text(
                          'Batas registrasi 3 hari lagi',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 2. Deskripsi & Detail Kartu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip Kategori Kecil
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: softOf(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.e.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: catInfo.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Judul Event
                        Text(
                          widget.e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Teks Deskripsi
                        Text(
                          widget.e.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: muted(context),
                            height: 1.25,
                          ),
                        ),
                        
                        const Spacer(),

                        // Tanggal Event
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 11, color: muted(context)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                fmtDate(widget.e.date),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Jumlah Relawan
                        Row(
                          children: [
                            Icon(Icons.group_outlined, size: 11, color: muted(context)),
                            const SizedBox(width: 5),
                            Text(
                              '${s.participants(widget.e)} Relawan',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Status Harga
                        StatusChip(
                          widget.e.priceText,
                          widget.e.isPaid ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                        ),
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
}