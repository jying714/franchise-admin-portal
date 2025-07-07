import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/error_log.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ErrorLogDetailDrawer extends StatelessWidget {
  final ErrorLog log;
  const ErrorLogDetailDrawer({Key? key, required this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error Details',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    log.severity.toLowerCase() == 'fatal'
                        ? Icons.error
                        : Icons.warning,
                    color: log.severity.toLowerCase() == 'fatal'
                        ? colorScheme.error
                        : colorScheme.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.severity,
                    style: TextStyle(
                      color: log.severity.toLowerCase() == 'fatal'
                          ? colorScheme.error
                          : colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp),
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
              const SizedBox(height: 18),
              SelectableText(
                log.message,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Stack Trace',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: colorScheme.surfaceVariant,
                  child: SelectableText(
                    log.stackTrace!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
              if (log.contextData != null && log.contextData!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Context Data',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  width: double.infinity,
                  color: colorScheme.surfaceVariant,
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(log.contextData),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy JSON'),
                    onPressed: () {
                      final errorJson = {
                        'message': log.message,
                        'severity': log.severity,
                        'source': log.source,
                        'screen': log.screen,
                        'stackTrace': log.stackTrace,
                        'contextData': log.contextData,
                        'timestamp': log.timestamp.toIso8601String(),
                      };
                      Clipboard.setData(ClipboardData(
                          text: const JsonEncoder.withIndent('  ')
                              .convert(errorJson)));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied error JSON!')));
                    },
                  ),
                  const SizedBox(width: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer),
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
