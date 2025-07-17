import 'package:flutter/material.dart';
import 'dart:html' as html;

class InviteAcceptScreen extends StatefulWidget {
  final String? inviteToken;
  const InviteAcceptScreen({super.key, this.inviteToken});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  String? _effectiveToken;
  bool _didLoadToken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadToken) return;
    _didLoadToken = true;

    print('[InviteAcceptScreen] didChangeDependencies:');
    print('  widget.inviteToken: ${widget.inviteToken}');

    // 1. From constructor
    _effectiveToken = widget.inviteToken;

    // 2. From route arguments
    if (_effectiveToken == null) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _effectiveToken = args['token'] as String?;
      print('  Route arguments: $args');
    }

    // 3. From URL hash (for direct browser navigation)
    if (_effectiveToken == null || _effectiveToken!.isEmpty) {
      final hash = html.window.location.hash;
      print('  window.location.hash: $hash');
      if (hash.isNotEmpty) {
        final hashPart = hash.substring(1); // Remove leading #
        final questionMarkIndex = hashPart.indexOf('?');
        if (questionMarkIndex != -1 &&
            questionMarkIndex < hashPart.length - 1) {
          final queryString = hashPart.substring(questionMarkIndex + 1);
          final params = Uri.splitQueryString(queryString);
          _effectiveToken = params['token'];
          print('  Parsed token from hash: $_effectiveToken');
        }
      }
    }

    print('  Final _effectiveToken: $_effectiveToken');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('[InviteAcceptScreen] build: _effectiveToken=$_effectiveToken');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Invitation'),
      ),
      body: Center(
        child: _effectiveToken == null || _effectiveToken!.isEmpty
            ? const Text(
                'No invitation token found in the URL.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.vpn_key, size: 38, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Invitation Token Found:',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _effectiveToken ?? '',
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      print('[InviteAcceptScreen] Token: $_effectiveToken');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Token: $_effectiveToken')),
                      );
                    },
                    child: const Text('Print Token to Console'),
                  ),
                ],
              ),
      ),
    );
  }
}
