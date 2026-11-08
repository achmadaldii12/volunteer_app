import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  int stars = 5;
  int page = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final certs = s.attendedRegs;
    if (page >= certs.length) page = 0;
    final primary = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sertifikat'),
          bottom: const TabBar(tabs: [Tab(text: 'Sertifikat Saya'), Tab(text: 'Feedback')]),
        ),
        body: TabBarView(children: [
          certs.isEmpty
              ? const EmptyState(Icons.workspace_premium_outlined, 'Belum ada sertifikat',
                  'Sertifikat tersedia setelah kehadiranmu pada sebuah kegiatan tercatat.')
              : ListView(padding: const EdgeInsets.all(20), children: [
                  SizedBox(
                    height: 230,
                    child: PageView.builder(
                      itemCount: certs.length,
                      onPageChanged: (i) => setState(() => page = i),
                      itemBuilder: (_, i) => _Certificate(certs[i]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < certs.length; i++)
                      Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: i == page ? primary : Colors.grey.shade400)),
                  ]),
                  const SizedBox(height: 22),
                  const Text('Berikan Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(s.eventById(certs[page].eventId)?.title ?? '',
                      style: TextStyle(color: muted(context), fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        iconSize: 38,
                        icon: Icon(Icons.star_rounded, color: i <= stars ? Colors.amber : Colors.grey.shade300),
                        onPressed: () => setState(() => stars = i),
                      ),
                  ]),
                  TextField(
                    controller: _ctrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                        hintText: 'Tulis ulasan Anda...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton('Kirim', onTap: () {
                    final e = s.eventById(certs[page].eventId);
                    s.submitFeedback(e?.title ?? 'Kegiatan', stars, _ctrl.text);
                    _ctrl.clear();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Terima kasih, feedback terkirim!')));
                  }),
                ]),
          s.myFeedbacks.isEmpty
              ? const EmptyState(Icons.rate_review_outlined, 'Belum ada feedback', 'Feedback yang kamu kirim akan tampil di sini.')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final f in s.myFeedbacks)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(Icons.star_rounded, size: 18, color: i <= f.rating ? Colors.amber : Colors.grey.shade300),
                          const Spacer(),
                          Text(timeAgo(f.createdAt), style: TextStyle(fontSize: 11, color: muted(context))),
                        ]),
                        if (f.text.isNotEmpty) ...[const SizedBox(height: 6), Text(f.text)],
                      ]),
                    ),
                ]),
        ]),
      ),
    );
  }
}

class _Certificate extends StatelessWidget {
  final Registration r;
  const _Certificate(this.r);

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final e = s.eventById(r.eventId);
    if (e == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          border: Border.all(color: const Color(0xFFD9C27A), width: 2),
          borderRadius: BorderRadius.circular(8)),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black87),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFD9A441), size: 30),
          const Text('Sertifikat Volunteer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('diberikan kepada', style: TextStyle(fontSize: 10)),
          Text(s.user?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(e.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('${fmtLongDate(e.date)} - ${e.hours} jam', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Sertifikat CERT-${r.code} diunduh (simulasi)'))),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Download'),
            ),
          ),
        ]),
      ),
    );
  }
}
