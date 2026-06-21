import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.person_rounded, size: 42),
          ),
          const SizedBox(height: 20),
          _ProfileTile(
            label: 'Nama lengkap',
            value: user?.fullName ?? 'Data profil dimuat melalui dashboard/API.',
          ),
          _ProfileTile(
            label: 'Username',
            value: user?.userName ?? '-',
          ),
          _ProfileTile(
            label: 'Email',
            value: user?.email ?? '-',
          ),
          _ProfileTile(
            label: 'NIM',
            value: user?.nim ?? '-',
          ),
        ],
      ),
    );
  }
}

class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeaturePage(
      title: 'Forum',
      icon: Icons.forum_rounded,
      message:
          'Rute forum sudah terhubung. Implementasi data dan tampilan forum tidak terdapat di arsip sumber.',
    );
  }
}

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeaturePage(
      title: 'Pencapaian',
      icon: Icons.emoji_events_rounded,
      message:
          'Rute pencapaian sudah terhubung. Ringkasan pencapaian tetap tersedia dan dimuat pada dashboard.',
    );
  }
}

class QuestPage extends StatelessWidget {
  const QuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeaturePage(
      title: 'Quest',
      icon: Icons.flag_rounded,
      message:
          'Rute quest sudah terhubung. Data quest tetap dimuat melalui DashboardService pada dashboard.',
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeaturePage(
      title: 'Leaderboard',
      icon: Icons.leaderboard_rounded,
      message:
          'Rute leaderboard sudah terhubung. Ringkasan peringkat tetap tersedia pada dashboard.',
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.science_outlined),
            title: Text('Mode penelitian'),
            subtitle: Text(
              'Halaman ini menjadi penghubung aman sampai modul pengaturan lengkap ditambahkan.',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
