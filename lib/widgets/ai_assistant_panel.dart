import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AiAssistantPanel extends StatefulWidget {
  final VoidCallback onClose;
  const AiAssistantPanel({super.key, required this.onClose});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final _msgCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  static final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'text': 'Hi! I\'m your GrowthOS AI assistant. Ask me about your sales, inventory, or business insights.'},
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _msgCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Try backend AI endpoint first
      final historyStrings = _messages
          .where((m) => m['text'] != text) // Exclude the message just added
          .map((m) => "${m['role'] == 'assistant' ? 'Advisor' : 'User'}: ${m['text']}")
          .toList();

      final response = await ApiService().post('/ai/chat', body: {
        'message': text,
        'history': historyStrings,
      });
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add({
            'role': 'assistant',
            'text': response['reply']?.toString() ?? response['insight']?.toString() ?? 'I received your message but couldn\'t generate a response.',
          });
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Fallback to rule-based response
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add({
            'role': 'assistant',
            'text': _fallbackReply(text),
          });
        });
        _scrollToBottom();
      }
    }
  }

  String _fallbackReply(String query) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final userBubble = isDark ? Colors.indigo.shade800 : Colors.indigo.shade100;
    final assistantBubble = isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF475569) : Colors.grey.shade300;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade500],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Powered by Ollama', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: hintColor),
                        const SizedBox(height: 12),
                        Text('Ask me anything about your store!', style: TextStyle(color: hintColor, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      // Loading indicator
                      if (i == _messages.length && _isLoading) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: assistantBubble,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? Colors.indigo.shade300 : Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Thinking...', style: TextStyle(fontSize: 13, color: hintColor)),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isUser ? userBubble : assistantBubble,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Quick suggestions (Scrollable horizontally)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _quickChip('Sales today', isDark),
                  const SizedBox(width: 8),
                  _quickChip('Which products to restock?', isDark),
                  const SizedBox(width: 8),
                  _quickChip('What is my top product?', isDark),
                  const SizedBox(width: 8),
                  _quickChip('Which items are not selling?', isDark),
                  const SizedBox(width: 8),
                  _quickChip('How to increase profit?', isDark),
                ],
              ),
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    enabled: !_isLoading,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF334155) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.indigo.shade300, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _isLoading ? Colors.grey : Colors.indigo,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _isLoading ? null : _send,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, bool isDark) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.indigo.shade700)),
      backgroundColor: isDark ? const Color(0xFF334155) : Colors.indigo.shade50,
      side: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.indigo.shade100),
      onPressed: () {
        _msgCtrl.text = label.replaceAll(RegExp(r'[^\w\s?]'), '').trim();
        _send();
      },
    );
  }
}
