import 'package:flutter/material.dart';

/// Reports Dashboard - View reports and analytics (Admin read-only)
/// This is a placeholder screen - full implementation pending
class ReportsDashboard extends StatelessWidget {
  const ReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64),
            SizedBox(height: 16),
            Text('Reports & Analytics'),
            SizedBox(height: 8),
            Text('Full implementation pending'),
          ],
        ),
      ),
    );
  }
}
