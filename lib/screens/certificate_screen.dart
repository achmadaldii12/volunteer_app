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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedCertIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk membuat dan mengunduh PDF lengkap dengan tanda tangan digital
  Future<void> _downloadPdf(BuildContext context, String eventTitle, String participantName, String dateStr, int hours) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.amber800, width: 6),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Header Sertifikat
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('VOLUNTEER APP OFFICIAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('SERTIFIKAT RESMI', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    ),
                  ],
                ),

                // Konten Utama Sertifikat
                pw.Column(
                  children: [
                    pw.Text('SERTIFIKAT PENGHARGAAN RELAWAN',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900, letterSpacing: 1.2)),
                    pw.SizedBox(height: 4),
                    pw.Text('Diberikan dengan bangga kepada:',
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    pw.SizedBox(height: 10),
                    
                    // Nama Peserta
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo, width: 2)),
                      ),
                      child: pw.Text(
                        participantName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    
                    pw.Text('Atas partisipasi aktif, dedikasi, dan kontribusinya sebagai relawan dalam kegiatan:',
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 6),
                    
                    // Judul Event
                    pw.Text(
                      eventTitle,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 6),
                    
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        'Tanggal Pelaksanaan: $dateStr  •  Total Kontribusi: $hours Jam',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ),
                  ],
                ),

                // Bagian Tanda Tangan & Stempel Resmi di Bawah
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Tanda Tangan Panitia
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Mengetahui,', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.SizedBox(
                          height: 35,
                          width: 120,
                          child: pw.CustomPaint(
                            size: const PdfPoint(120, 35),
                            painter: (PdfGraphics canvas, PdfPoint size) {
                              canvas.setColor(PdfColors.blue900);
                              canvas.setLineWidth(1.5);
                              canvas.moveTo(10, 25);
                              canvas.curveTo(30, 5, 40, 35, 60, 15);
                              canvas.curveTo(70, 5, 90, 30, 110, 10);
                              canvas.strokePath();
                            },
                          ),
                        ),
                        pw.Container(width: 140, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('Panitia Pelaksana Kegiatan', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),

                    // Stempel / Badge Pengesahan Tengah
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.amber800, width: 2),
                      ),
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('VERIFIED', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                          pw.Text('LEGAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                        ],
                      ),
                    ),

                    // Tanda Tangan Direktur Program
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Surabaya, ${DateTime.now().year}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.SizedBox(
                          height: 35,
                          width: 120,
                          child: pw.CustomPaint(
                            size: const PdfPoint(120, 35),
                            painter: (PdfGraphics canvas, PdfPoint size) {
                              canvas.setColor(PdfColors.indigo900);
                              canvas.setLineWidth(1.5);
                              canvas.moveTo(15, 10);
                              canvas.curveTo(35, 30, 50, 5, 75, 25);
                              canvas.curveTo(85, 35, 100, 10, 115, 20);
                              canvas.strokePath();
                            },
                          ),
                        ),
                        pw.Container(width: 140, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('Direktur Program Relawan', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
    final String currentUserName = s.user?.name ?? 'Achmad Aldi Saputra';

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

                      // Slider Preview Sertifikat Aktif (Terhubung dengan PageController)
                      SizedBox(
                        height: 240,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: certs.length,
                          onPageChanged: (i) {
                            setState(() {
                              selectedCertIndex = i;
                            });
                          },
                          itemBuilder: (_, i) {
                            final reg = certs[i];
                            final ev = s.eventById(reg.eventId);
                            return _CertificateCard(
                              registration: reg,
                              userName: currentUserName,
                              onSave: () => _downloadPdf(
                                context,
                                ev?.title ?? 'Sertifikat',
                                currentUserName,
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
                      
                      // Daftar Item Folder (Ketika diklik, preview atas akan otomatis berpindah)
                      for (var i = 0; i < certs.length; i++)
                        _FolderItemTile(
                          registration: certs[i],
                          isSelected: i == selectedCertIndex,
                          onTap: () {
                            setState(() {
                              selectedCertIndex = i;
                            });
                            // Menggeser PageView ke halaman index yang diklik secara halus
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          onSave: () {
                            final ev = s.eventById(certs[i].eventId);
                            _downloadPdf(
                              context,
                              ev?.title ?? 'Sertifikat',
                              currentUserName,
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
  final String userName;
  final VoidCallback onSave;

  const _CertificateCard({required this.registration, required this.userName, required this.onSave});

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
            userName,
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