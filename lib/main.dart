import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/aluno_provider.dart';
import 'providers/financeiro_provider.dart';
import 'services/sponte_api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MapleBearApp());
}

class MapleBearApp extends StatelessWidget {
  const MapleBearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SponteApiService>(
          create: (_) => SponteApiService(),
        ),
        ChangeNotifierProxyProvider<SponteApiService, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<SponteApiService>()),
          update: (_, api, prev) => prev ?? AuthProvider(api),
        ),
        ChangeNotifierProxyProvider<SponteApiService, AlunoProvider>(
          create: (ctx) => AlunoProvider(ctx.read<SponteApiService>()),
          update: (_, api, prev) => prev ?? AlunoProvider(api),
        ),
        ChangeNotifierProxyProvider<SponteApiService, FinanceiroProvider>(
          create: (ctx) => FinanceiroProvider(ctx.read<SponteApiService>()),
          update: (_, api, prev) => prev ?? FinanceiroProvider(api),
        ),
      ],
      child: const AppRoot(),
    );
  }
}
