import 'package:flutter/material.dart';

enum MessageType { text, emote, eventInvite }

class CommunityMessage {
  final String id;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? eventTitle;

  CommunityMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.eventTitle,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<CommunityMessage> _messages = [
    CommunityMessage(
      id: '1',
      senderName: 'Siti',
      content: 'Halo relawan! Ada yang mau ikutan aksi tanam mangrove minggu ini?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    CommunityMessage(
      id: '2',
      senderName: 'Budi',
      content: 'Ayo ajak relawan ke event "Penanaman 1000 Mangrove"! 🎉',
      type: MessageType.eventInvite,
      eventTitle: 'Penanaman 1000 Mangrove',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  void _sendMessage({MessageType type = MessageType.text, String? content, String? eventTitle}) {
    final text = content ?? _messageController.text;
    if (text.trim().isEmpty && type == MessageType.text) return;

    setState(() {
      _messages.add(
        CommunityMessage(
          id: DateTime.now().toString(),
          senderName: 'Saya',
          content: text,
          type: type,
          eventTitle: eventTitle,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gavel, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Aturan Komunitas'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Pedoman Interaksi Komunitas Relawan:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('1. 🤝 Saling Menghormati: Dilarang menggunakan ujaran kebencian, SARA, atau bahasa kasar.'),
              SizedBox(height: 6),
              Text('2. 🚫 Dilarang Spam: Hindari pengiriman promosi komersial luar dan tautan phishing.'),
              SizedBox(height: 6),
              Text('3. 🔒 Jaga Privasi: Dilarang menyebarkan data pribadi milik anggota lain.'),
              SizedBox(height: 6),
              Text('4. 🎯 Relevansi Event: Gunakan ajakan hanya untuk kegiatan relawan yang bermanfaat.'),
              SizedBox(height: 6),
              Text('5. ⚠️ Pelaporan: Pelanggaran berulang akan dikenakan sanksi pemblokiran akun.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti & Setuju'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunitas Relawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Aturan Komunitas',
            onPressed: _showRulesDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.amber.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Jaga kesantunan berinteraksi. Klik ikon (i) untuk membaca pedoman.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderName == 'Saya';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.indigo.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        if (msg.type == MessageType.eventInvite)
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text('📢 ${msg.content}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Gabung Event Ini'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(msg.content),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                      onPressed: () => _sendMessage(type: MessageType.text, content: '👍😊🔥'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.event, size: 16),
                      label: const Text('Ajak ke Event'),
                      onPressed: () {
                        _sendMessage(
                          type: MessageType.eventInvite,
                          content: 'Yuk ikutan kegiatan relawan bersama!',
                          eventTitle: 'Event Pilihan',
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.indigo),
                      onPressed: () => _sendMessage(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
