import 'package:flutter/material.dart';
import 'api_config.dart';
import 'sync_service.dart';

/// Dialog "Pengaturan Server": isi alamat PC Laragon (mis. 192.168.1.5) agar HP asli
/// dapat terhubung. Dibuka dengan menekan LAMA logo di layar Login.
Future<void> showServerDialog(BuildContext context) async {
  final c = TextEditingController(text: ApiConfig.baseUrl);
  String status = '';
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Pengaturan Server'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Emulator Android: 10.0.2.2\nChrome/Web: localhost\nHP asli: IP komputer Laragon, mis. 192.168.1.5',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              decoration: const InputDecoration(labelText: 'Alamat server', border: OutlineInputBorder()),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(status, style: const TextStyle(fontSize: 12.5)),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiConfig.setCustom(null);
              c.text = ApiConfig.baseUrl;
              setS(() => status = 'Dikembalikan ke alamat bawaan.');
            },
            child: const Text('Bawaan'),
          ),
          TextButton(
            onPressed: () async {
              await ApiConfig.setCustom(c.text);
              c.text = ApiConfig.baseUrl;
              setS(() => status = 'Menguji koneksi...');
              final r = await ApiSync.instance.testConnection();
              setS(() => status = r);
            },
            child: const Text('Simpan & Tes'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    ),
  );
  c.dispose();
}
