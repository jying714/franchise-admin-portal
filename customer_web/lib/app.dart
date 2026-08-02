// customer_web/lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'widgets/branding_shell.dart';
import 'core/router.dart';

class CustomerWebApp extends StatefulWidget {
  const CustomerWebApp({super.key});

  @override
  State<CustomerWebApp> createState() => _CustomerWebAppState();
}

class _CustomerWebAppState extends State<CustomerWebApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    _router = createCustomerRouter(franchiseProvider: fp);
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<shared.FranchiseProvider>();
    // Depend on config version so theme rebuilds after setBrandingFromFranchiseDoc.
    final _ = fp.currentConfigVersion;

    return MaterialApp.router(
      title: fp.hasValidFranchise ? fp.currentAppName : 'Customer Storefront',
      debugShowCheckedModeBanner: false,
      theme: themeFromFranchise(fp),
      routerConfig: _router,
    );
  }
}
