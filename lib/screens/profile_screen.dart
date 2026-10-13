import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/stat_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                'И',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Иван',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Студент · стипендия раз в месяц',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
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
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
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
