import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../logs/presentation/pages/logs_page.dart';
import '../../../schedules/presentation/pages/schedules_page.dart';
import 'dashboard_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, required this.user});

  final User user;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(user: widget.user),
      const SchedulesPage(),
      const LogsPage(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.schedule_rounded), label: 'Schedules'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Logs'),
        ],
      ),
    );
  }
}
