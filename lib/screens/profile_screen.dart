import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../lw12/bloc/auth/auth_cubit.dart';
import '../lw12/screens/login_screen.dart';
import '../lw12/screens/shop_catalog_screen.dart';
import '../lw13/screens/photo_diary_screen.dart';
import '../models/budget.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/stat_card.dart';
import 'vault_screen.dart';

/// Tab "Профиль": user info, stats and simple settings toggles.
class ProfileScreen extends StatefulWidget {
  final Budget budget;
  final int expensesCount;
  final int favoritesCount;

  const ProfileScreen({
    super.key,
    required this.budget,
    required this.expensesCount,
    required this.favoritesCount,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _dailyReminder = true;
  bool _overspendAlert = true;
  bool _hideAmounts = false;

  /// «Заметки» (LW11): notes, username and dark mode saved on disk.
  void _openVault() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VaultScreen()),
    );
  }

  /// LW13 geotagged photo diary: camera, gallery and GPS.
  void _openPhotoDiary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhotoDiaryScreen()),
    );
  }

  /// LW12 BLoC shop. Already logged in → straight to the catalog.
  void _openShop() {
    final loggedIn = context.read<AuthCubit>().state is AuthSuccess;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const ShopCatalogScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Saved in LW11 under 'user_display_name', 'Guest User' by default.
    final name = context.select<SettingsProvider, String>((s) => s.displayName);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: context.palette.accentSoft,
              child: Text(
                name.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: context.palette.accentText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Студент · стипендия раз в месяц',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: _hideAmounts
                      ? '•••'
                      : Format.money(widget.budget.balanceAtDayStart),
                  caption: 'баланс',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${widget.expensesCount}',
                  caption: 'трат',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${widget.favoritesCount}',
                  caption: 'в избранном',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Group(
            children: [
              SwitchListTile(
                value: _dailyReminder,
                onChanged: (v) => setState(() => _dailyReminder = v),
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Напоминать вечером'),
                subtitle: const Text('Записать траты за день'),
              ),
              SwitchListTile(
                value: _overspendAlert,
                onChanged: (v) => setState(() => _overspendAlert = v),
                secondary: const Icon(Icons.warning_amber_rounded),
                title: const Text('Предупреждать о перерасходе'),
              ),
              SwitchListTile(
                value: _hideAmounts,
                onChanged: (v) => setState(() => _hideAmounts = v),
                secondary: const Icon(Icons.visibility_off_outlined),
                title: const Text('Скрывать баланс'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.event_repeat),
                title: const Text('Следующая стипендия'),
                trailing: Text(
                  Format.dayMonth(widget.budget.nextStipendDate),
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ),
              ListTile(
                onTap: _openVault,
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: const Text('Заметки и настройки'),
                subtitle: const Text('Имя, тема, заметки офлайн'),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                onTap: _openShop,
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Магазин с входом'),
                subtitle: const Text('Вход и корзина на BLoC'),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                onTap: _openPhotoDiary,
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Фотодневник'),
                subtitle: const Text('Фото, GPS и подписи офлайн'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('О приложении'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
