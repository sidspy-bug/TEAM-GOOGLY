import 'package:flutter/material.dart';
import '../screens/ocr_screen.dart';
import 'ai_assistant_panel.dart';

/// Floating AI Assistant button + bottom sheet modal.
/// Shows a FAB at bottom-right that opens a chat modal.
class FloatingAiAssistant extends StatelessWidget {
  final VoidCallback? onSaveSuccess;
  const FloatingAiAssistant({super.key, this.onSaveSuccess});

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                  ),
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Purchase'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OcrScreen(mode: 'purchase', onSaveSuccess: onSaveSuccess)));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                  ),
                  icon: const Icon(Icons.sell),
                  label: const Text('Sale'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OcrScreen(mode: 'sale', onSaveSuccess: onSaveSuccess)));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // AI Assistant Panel fills remaining space
                Expanded(
                  child: AiAssistantPanel(
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab_ai',
            backgroundColor: Colors.indigo,
            onPressed: () => _showAssistantSheet(context),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              heroTag: 'fab_add',
              backgroundColor: Colors.orange.shade400,
              onPressed: () => _showAddMenu(context),
              child: const Icon(Icons.add, size: 36, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
