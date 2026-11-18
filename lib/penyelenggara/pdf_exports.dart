import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

String _safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9 _\-]'), '').trim().replaceAll(' ', '_');

/// Sertifikat digital (PDF). Memakai font bawaan PDF, jadi teks dibuat ASCII-aman.
Future<void> shareCertificatePdf({
  required String volunteer,
  required String eventTitle,
  required String orgName,
  required String number,
  required String dateText,
  required int hours,
}) async {
  final doc = pw.Document();
  const red = PdfColors.red800;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: red, width: 6)),
        padding: const pw.EdgeInsets.all(30),
        child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Text('VOLUNTEER', style: pw.TextStyle(fontSize: 16, color: red, fontWeight: pw.FontWeight.bold, letterSpacing: 6)),
          pw.SizedBox(height: 14),
          pw.Text('SERTIFIKAT PENGHARGAAN', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: red)),
          pw.SizedBox(height: 6),
          pw.Text('No. $number', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 24),
          pw.Text('Diberikan kepada', style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Text(volunteer, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          pw.Text('atas partisipasinya sebagai relawan pada kegiatan', style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 6),
          pw.Text(eventTitle, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: red)),
          pw.SizedBox(height: 6),
          pw.Text('Durasi kontribusi $hours jam', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 30),
          pw.Text(dateText, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text('Penyelenggara: $orgName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    ),
  );
  await Printing.sharePdf(bytes: await doc.save(), filename: 'Sertifikat_${_safe(volunteer)}_${_safe(eventTitle)}.pdf');
}

/// Laporan penyelenggara (PDF): ringkasan + tabel event.
Future<void> shareReportPdf({
  required String orgName,
  required String generatedAt,
  required List<List<String>> summary,
  required List<String> eventHeader,
  required List<List<String>> eventRows,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Text('Laporan Kegiatan Penyelenggara', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
        pw.Text('$orgName  |  Dibuat $generatedAt', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          data: summary,
          cellStyle: const pw.TextStyle(fontSize: 11),
          cellAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder.all(color: PdfColors.grey400),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Daftar Event', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: eventHeader,
          data: eventRows,
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
          cellStyle: const pw.TextStyle(fontSize: 9.5),
          cellAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder.all(color: PdfColors.grey400),
        ),
      ],
    ),
  );
  await Printing.sharePdf(bytes: await doc.save(), filename: 'Laporan_Penyelenggara_${_safe(generatedAt)}.pdf');
}
