import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  int selectedCertIndex = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Fungsi nyata untuk mendownload PDF ke komputer
  Future<void> _downloadPdf(BuildContext context, String eventTitle, String userName, String dateStr, int hours) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber, width: 6),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('SERTIFIKAT PENGHARGAAN RELAWAN',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.brown)),
                pw.SizedBox(height: 10),
                pw.Text('Diberikan dengan bangga kepada:', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text(userName,
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                pw.SizedBox(height: 15),
                pw.Text('Atas partisipasi aktif dan dedikasinya sebagai relawan dalam kegiatan:',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Text(eventTitle,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 8),
                pw.Text('Tanggal Pelaksanaan: $dateStr • Kontribusi: $hours Jam',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('Panitia Pelaksana', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('Direktur Program', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Sertifikat_$eventTitle.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final certs = s.attendedRegs;
    if (selectedCertIndex >= certs.length && certs.isNotEmpty) {
      selectedCertIndex = 0;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Arsip Sertifikat & Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.redAccent,
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.folder_shared_outlined), text: 'Folder Sertifikat'),
              Tab(icon: Icon(Icons.rate_review_outlined), text: 'Riwayat Feedback'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ================= TAB 1: FOLDER SERTIFIKAT =================
            certs.isEmpty
                ? const EmptyState(
                    Icons.workspace_premium_outlined,
                    'Belum Ada Sertifikat',
                    'Sertifikat akan otomatis masuk ke folder ini setelah kehadiranmu pada kegiatan terverifikasi.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_special, color: Colors.amber, size: 40),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Folder Arsip Digital',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total ${certs.length} sertifikat PDF siap disimpan ke komputer.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Preview Sertifikat Aktif',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 240,
                        child: PageView.builder(
                          itemCount: certs.length,
                          onPageChanged: (i) => setState(() => selectedCertIndex = i),
                          itemBuilder: (_, i) {
                            final reg = certs[i];
                            final ev = s.eventById(reg.eventId);
                            return _CertificateCard(
                              registration: reg,
                              onSave: () => _downloadPdf(
                                context,
                                ev?.title ?? 'Sertifikat',
                                s.user?.name ?? 'Achmad Aldi Saputra',
                                ev != null ? fmtLongDate(ev.date) : '2027',
                                ev?.hours ?? 5,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < certs.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: i == selectedCertIndex ? 20 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i == selectedCertIndex ? Colors.redAccent : Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Daftar Folder Sertifikat Kegiatan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < certs.length; i++)
                        _FolderItemTile(
                          registration: certs[i],
                          isSelected: i == selectedCertIndex,
                          onTap: () => setState(() => selectedCertIndex = i),
                          onSave: () {
                            final ev = s.eventById(certs[i].eventId);
                            _downloadPdf(
                              context,
                              ev?.title ?? 'Sertifikat',
                              s.user?.name ?? 'Achmad Aldi Saputra',
                              ev != null ? fmtLongDate(ev.date) : '2027',
                              ev?.hours ?? 5,
                            );
                          },
                        ),
                    ],
                  ),

            // ================= TAB 2: FEEDBACK =================
            s.myFeedbacks.isEmpty
                ? const EmptyState(
                    Icons.rate_review_outlined,
                    'Belum ada feedback',
                    'Ulasan dan penilaian yang kamu berikan untuk kegiatan akan tampil di sini.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final f in s.myFeedbacks)
                        AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  for (var i = 1; i <= 5; i++)
                                    Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: i <= f.rating ? Colors.amber : Colors.grey.shade300,
                                    ),
                                  const Spacer(),
                                  Text(timeAgo(f.createdAt), style: TextStyle(fontSize: 11, color: muted(context))),
                                ],
                              ),
                              if (f.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(f.text, style: const TextStyle(color: Colors.black87)),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Registration registration;
  final VoidCallback onSave;

  const _CertificateCard({required this.registration, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final e = s.eventById(registration.eventId);
    if (e == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEF), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD9C27A), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFD9A441), size: 36),
          const SizedBox(height: 4),
          const Text(
            'SERTIFIKAT PENGHARGAAN RELAWAN (PDF)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2, color: Color(0xFF92400E)),
          ),
          const Text('diberikan kepada', style: TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(
            s.user?.name ?? 'Achmad Aldi Saputra',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            e.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text('${fmtLongDate(e.date)} • ${e.hours} Jam Kontribusi',
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.download_rounded, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              label: const Text('Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderItemTile extends StatelessWidget {
  final Registration registration;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _FolderItemTile({
    required this.registration,
    required this.isSelected,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final e = s.eventById(registration.eventId);
    if (e == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.redAccent : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.redAccent : Colors.amber.shade100,
          child: Icon(
            Icons.picture_as_pdf,
            color: isSelected ? Colors.white : Colors.amber.shade800,
            size: 20,
          ),
        ),
        title: Text(
          e.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.red.shade900 : Colors.black87),
        ),
        subtitle: Text(
          '${fmtLongDate(e.date)} • ${e.hours} Jam (PDF)',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.grey),
          tooltip: 'Simpan PDF',
          onPressed: onSave,
        ),
      ),
    );
  }
}