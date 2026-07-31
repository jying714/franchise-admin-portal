import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Global error boundary widget for P2.3 production resilience.
/// Wraps children and catches build/render errors, logging via shared.ErrorLogger.
/// Falls back to a friendly error UI instead of red screen.
/// Use in MaterialApp.builder or as a root wrapper for critical flows.
class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? screenName;

  const GlobalErrorBoundary({
    super.key,
    required this.child,
    this.screenName,
  });

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Reset on rebuilds if parent recovers
    _hasError = false;
  }

  void _logError(Object error, StackTrace? stack) {
    final msg =
        '[GlobalErrorBoundary${widget.screenName != null ? ' (${widget.screenName})' : ''}] ${error.toString()}';
    shared.ErrorLogger.log(
      message: msg,
      source: 'GlobalErrorBoundary',
      severity: 'fatal',
      stack: stack?.toString(),
      contextData: {
        'screen': widget.screenName ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: shared.UiConfig.fontWeightBold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app encountered an unexpected error. Our team has been notified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shared.DesignTokens.bodyFontSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: shared.DesignTokens.fontFamily,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Use a builder to catch errors in the child subtree during build
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (e, stack) {
          if (!_hasError) {
            _hasError = true;
            _errorMessage = e.toString();
            _logError(e, stack);
          }
          // Return the error UI on next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          return const SizedBox.shrink();
        }
      },
    );
  }
}
