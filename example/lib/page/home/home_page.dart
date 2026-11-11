import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../l10n/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: AppLanguage.toggle,
            icon: const Icon(Icons.translate, size: 18),
            label: Text(S.current.language),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            ElevatedButton(
              onPressed: () => Get.toNamed('/setting'),
              child: Text(S.current.homeSamples),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.toNamed('/live'),
              child: Text(S.current.homeLive),
            ),
          ],
        ),
      ),
    );
  }
}
