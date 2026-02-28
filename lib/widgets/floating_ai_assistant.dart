import 'package:flutter/material.dart';
import '../screens/ocr_screen.dart';

/// Floating AI Assistant button + bottom sheet modal.
/// Shows a FAB at bottom-right that opens a chat modal.
class FloatingAiAssistant extends StatelessWidget {
  const FloatingAiAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main AI FAB (above camera)
          FloatingActionButton(
            heroTag: 'fab_ai',
            backgroundColor: Colors.indigo,
            onPressed: () => _showAssistantSheet(context),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Camera / OCR button (below AI)
          FloatingActionButton.small(
            heroTag: 'fab_camera',
            backgroundColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OcrScreen()),
              );
            },
            child: Icon(Icons.camera_alt, color: Colors.indigo.shade600, size: 20),
          ),
        ],
      ),
    );
  }

  void _showAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AssistantSheet(),
    );
  }
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet();

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Hi! I\'m your GrowthOS AI assistant. Ask me about your sales, inventory, or business insights.'
    },
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _msgCtrl.clear();
    });
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': _mockReply(text)});
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _mockReply(String query) {
    final q = query.toLowerCase();
    if (q.contains('sale') || q.contains('revenue')) {
      return 'Your total sales today are approximately ₹8,450. Tea and Samosa are the top sellers.';
    }
    if (q.contains('profit')) {
      return 'Estimated profit today is ₹3,820 based on current cost and selling prices.';
    }
    if (q.contains('stock') || q.contains('inventory')) {
      return 'You have 2 items below the low-stock threshold: Butter (8 units) and Shampoo (15 units). Consider reordering soon.';
    }
    if (q.contains('suggest') || q.contains('tip')) {
      return 'Tip: Bundle Tea + Samosa as a morning combo at ₹40 (vs ₹45 separate) to boost average order value.';
    }
    return 'I can help you with sales analysis, inventory checks, and business tips. Try asking about your sales, profit, or stock levels!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).size.width < 768 ? 16 : 260,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Business Assistant',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.indigo.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? '',
                        style: const TextStyle(fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Camera button
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined,
                      color: Colors.grey.shade600, size: 22),
                  onPressed: () {
                    Navigator.of(context).pop(); // close the sheet
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OcrScreen()),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Scan bill',
                ),
                const SizedBox(width: 8),
                // Text input
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                // Voice input
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.grey.shade600, size: 22),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Voice input coming soon')));
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Voice input',
                ),
                const SizedBox(width: 4),
                // Send
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo, size: 22),
                  onPressed: _send,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
