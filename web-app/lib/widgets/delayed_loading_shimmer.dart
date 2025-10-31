import 'package:flutter/material.dart';
import 'loading_shimmer_widget.dart';

class DelayedLoadingShimmer extends StatefulWidget {
  final bool loading;
  final Widget child;
  final Duration delay;

  const DelayedLoadingShimmer({
    Key? key,
    required this.loading,
    required this.child,
    this.delay = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<DelayedLoadingShimmer> createState() => _DelayedLoadingShimmerState();
}

class _DelayedLoadingShimmerState extends State<DelayedLoadingShimmer> {
  bool _showShimmer = false;
  Future<void>? _timerFuture;

  @override
  void initState() {
    super.initState();
    _handleLoading();
  }

  @override
  void didUpdateWidget(covariant DelayedLoadingShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading != oldWidget.loading) {
      _handleLoading();
    }
  }

  void _handleLoading() {
    if (widget.loading) {
      _showShimmer = false;
      _timerFuture = Future.delayed(widget.delay, () {
        if (mounted && widget.loading) {
          setState(() {
            _showShimmer = true;
          });
        }
      });
    } else {
      setState(() {
        _showShimmer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && _showShimmer) {
      return const LoadingShimmerWidget();
    }
    return widget.child;
  }
}


