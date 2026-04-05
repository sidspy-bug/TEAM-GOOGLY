import 'package:flutter/material.dart';
import '../screens/ocr_screen.dart';

/// Floating AI Assistant button + bottom sheet modal.
/// Shows a FAB at bottom-right that opens a chat modal.
class FloatingAiAssistant extends StatelessWidget {
  const FloatingAiAssistant({super.key});

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
            Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrScreen(mode: 'purchase')));
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
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrScreen(mode: 'sale')));
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
      builder: (context) => Container(),
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
