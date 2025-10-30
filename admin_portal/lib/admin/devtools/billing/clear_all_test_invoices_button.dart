import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

class ClearAllTestInvoicesButton extends StatefulWidget {
  final VoidCallback? onCleared; // Optional callback to refresh parent UI

  const ClearAllTestInvoicesButton({super.key, this.onCleared});

  @override
  State<ClearAllTestInvoicesButton> createState() =>
      _ClearAllTestInvoicesButtonState();
}

class _ClearAllTestInvoicesButtonState
    extends State<ClearAllTestInvoicesButton> {
  bool _isClearing = false;

  Future<void> _clearAllTestInvoices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to permanently delete all test invoices? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClearing = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('platform_invoices')
          .where('isTest', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Deleted ${snapshot.docs.length} test invoices.')),
      );

      widget.onCleared?.call();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to clear test invoices: $e',
        stack: stack.toString(),
        source: 'ClearAllTestInvoicesButton',
        screen: 'dev_tools',
        severity: 'fatal',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred while deleting.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.delete_sweep_outlined),
      label: Text(_isClearing ? 'Clearing...' : 'Clear All Test Invoices'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      onPressed: _isClearing ? null : _clearAllTestInvoices,
    );
  }
}
