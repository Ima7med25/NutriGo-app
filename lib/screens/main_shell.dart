import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'snap_screen.dart';
import 'swaps_screen.dart';

/// Clears the stack and opens the main app on the Home tab.
void goHome(BuildContext context, {int tab = 0}) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => MainShell(initialTab: tab)),
    (_) => false,
  );
}

void openSnap(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const SnapScreen()));
}

/// Hosts the 4 tabs + the floating Snap button.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});
  final int initialTab;

  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _tab = widget.initialTab;

  void selectTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          HistoryScreen(),
          SwapsScreen(asTab: true),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        index: _tab,
        onTab: selectTab,
        onSnap: () => openSnap(context),
      ),
    );
  }
}

class AppTabBar extends StatelessWidget {
  const AppTabBar(
      {super.key, required this.index, required this.onTab, required this.onSnap});

  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onSnap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 101 + 35 + (bottom > 0 ? bottom - 20 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            top: 35,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, -4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 19, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _item(0, Icons.home_rounded, tr('Home')),
                  _item(1, Icons.history_rounded, tr('History')),
                  const Expanded(child: SizedBox()),
                  _item(2, Icons.swap_horiz_rounded, tr('Swaps')),
                  _item(3, Icons.person_rounded, tr('Profile')),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: tr('Snap a meal'),
              child: GestureDetector(
                onTap: onSnap,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 5),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x552E7D32),
                          blurRadius: 16,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.photo_camera_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final sel = i == index;
    final c = sel ? AppColors.green : AppColors.muted;
    return Expanded(
      child: Semantics(
        selected: sel,
        button: true,
        child: InkWell(
          onTap: () => onTab(i),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: AppText.body(12,
                      color: c,
                      weight: sel ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom padding so scroll content clears the tab bar.
const kTabBarClearance = 150.0;
