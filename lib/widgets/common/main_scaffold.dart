import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/alunos')) return 1;
    if (location.startsWith('/financeiro')) return 2;
    if (location.startsWith('/matriculas')) return 3;
    if (location.startsWith('/agenda')) return 4;
    if (location.startsWith('/comunicados')) return 5;
    if (location.startsWith('/relatorios')) return 6;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final usuario = context.watch<AuthProvider>().usuario;
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context, currentIndex, usuario?.nome ?? ''),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }

  Widget _buildSidebar(BuildContext context, int currentIndex, String nomeUsuario) {
    return Container(
      width: 220,
      color: MapleBearTheme.primary,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _logo(),
          const SizedBox(height: 8),
          Text(
            'Maple Bear\nValqueire',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          ..._navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = i == currentIndex;
            return _SidebarItem(
              icon: item.icon,
              label: item.label,
              route: item.route,
              selected: selected,
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(color: Colors.white24),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nomeUsuario,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                      onPressed: () => _confirmarLogout(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.school,
            size: 44,
            color: MapleBearTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final mainItems = _navItems.take(5).toList();
    return BottomNavigationBar(
      currentIndex: currentIndex > 4 ? 0 : currentIndex,
      onTap: (i) => context.go(_navItems[i].route),
      items: mainItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: MapleBearTheme.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Início', route: '/'),
    _NavItem(icon: Icons.people_outlined, label: 'Alunos', route: '/alunos'),
    _NavItem(icon: Icons.attach_money, label: 'Financeiro', route: '/financeiro'),
    _NavItem(icon: Icons.assignment_outlined, label: 'Matrículas', route: '/matriculas'),
    _NavItem(icon: Icons.calendar_today_outlined, label: 'Agenda', route: '/agenda'),
    _NavItem(icon: Icons.campaign_outlined, label: 'Comunicados', route: '/comunicados'),
    _NavItem(icon: Icons.bar_chart_outlined, label: 'Relatórios', route: '/relatorios'),
  ];
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool selected;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
