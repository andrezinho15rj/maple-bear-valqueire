import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/alunos/alunos_screen.dart';
import '../screens/alunos/aluno_detalhe_screen.dart';
import '../screens/alunos/aluno_form_screen.dart';
import '../screens/financeiro/financeiro_screen.dart';
import '../screens/financeiro/cobranca_detalhe_screen.dart';
import '../screens/financeiro/nova_cobranca_screen.dart';
import '../screens/matriculas/matriculas_screen.dart';
import '../screens/matriculas/matricula_form_screen.dart';
import '../screens/matriculas/matricula_detalhe_screen.dart';
import '../screens/agenda/agenda_screen.dart';
import '../screens/agenda/evento_form_screen.dart';
import '../screens/comunicados/comunicados_screen.dart';
import '../screens/comunicados/comunicado_form_screen.dart';
import '../screens/relatorios/relatorios_screen.dart';
import '../widgets/common/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/alunos',
            builder: (context, state) => const AlunosScreen(),
            routes: [
              GoRoute(
                path: 'novo',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AlunoFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    AlunoDetalheScreen(id: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'editar',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        AlunoFormScreen(id: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/financeiro',
            builder: (context, state) => const FinanceiroScreen(),
            routes: [
              GoRoute(
                path: 'nova-cobranca',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const NovaCobrancaScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    CobrancaDetalheScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/matriculas',
            builder: (context, state) => const MatriculasScreen(),
            routes: [
              GoRoute(
                path: 'nova',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const MatriculaFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    MatriculaDetalheScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaScreen(),
            routes: [
              GoRoute(
                path: 'novo-evento',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const EventoFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/comunicados',
            builder: (context, state) => const ComunicadosScreen(),
            routes: [
              GoRoute(
                path: 'novo',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ComunicadoFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/relatorios',
            builder: (context, state) => const RelatoriosScreen(),
          ),
        ],
      ),
    ],
  );
}
