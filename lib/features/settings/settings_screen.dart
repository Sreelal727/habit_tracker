import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Manage Habits'),
            subtitle: const Text('Reorder, edit, or archive habits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/habits'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Habit Tracker v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Habit Tracker',
                applicationVersion: '1.0.0',
                children: [
                  const Text('Track your daily habits and goals.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
