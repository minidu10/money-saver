import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences.dart';
import '../../data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final currencyCode = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currency = currencyFor(currencyCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user.displayName?.isNotEmpty == true
                  ? user.displayName!
                  : 'You'),
              subtitle: Text(user.email ?? ''),
            ),
          const Divider(height: 1),
          const _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text('${currency.code} · ${currency.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, ref, currencyCode),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),
          const Divider(height: 1),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('0.2.1'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source on GitHub'),
            subtitle: const Text('github.com/minidu10/money-saver'),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text('Sign out',
                style: TextStyle(color: Colors.red.shade700)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text(
                      'Your data will stay safe in the cloud — sign back in to see it.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton.tonal(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign out')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'Follow system',
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

void _showCurrencyPicker(
    BuildContext context, WidgetRef ref, String currentCode) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: RadioGroup<String>(
        groupValue: currentCode,
        onChanged: (v) async {
          if (v != null) {
            await ref.read(currencyProvider.notifier).set(v);
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Choose currency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            for (final c in supportedCurrencies)
              RadioListTile<String>(
                title: Text('${c.code} · ${c.name}'),
                secondary: Text(c.symbol,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                value: c.code,
              ),
          ],
        ),
      ),
    ),
  );
}

void _showThemePicker(
    BuildContext context, WidgetRef ref, ThemeMode current) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: RadioGroup<ThemeMode>(
        groupValue: current,
        onChanged: (v) async {
          if (v != null) {
            await ref.read(themeModeProvider.notifier).set(v);
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                title: Text(switch (mode) {
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                  ThemeMode.system => 'Follow system',
                }),
                value: mode,
              ),
          ],
        ),
      ),
    ),
  );
}
