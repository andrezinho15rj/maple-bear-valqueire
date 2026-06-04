import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../services/sponte_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardResumo? _resumo;
  bool _carregando = true;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final api = context.read<SponteApiService>();
      _resumo = await api.getDashboard();
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final hora = DateTime.now().hour;
    final saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Maple Bear Valqueire'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        color: MapleBearTheme.primary,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(usuario?.nome ?? 'Usuário', saudacao),
      ),
    );
  }

  Widget _buildContent(String nome, String saudacao) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(nome, saudacao),
        const SizedBox(height: 20),
        _buildKPIGrid(),
        const SizedBox(height: 20),
        _buildFinanceiroResumo(),
        const SizedBox(height: 20),
        _buildAcessoRapido(),
        const SizedBox(height: 20),
        _buildAlunosPorSerie(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGreeting(String nome, String saudacao) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MapleBearTheme.primary, MapleBearTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$saudacao, ${nome.split(' ').first}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR')
                      .format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.wb_sunny_outlined, color: Colors.white54, size: 48),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    if (_resumo == null) return const SizedBox.shrink();
    final items = [
      _KPIItem(
        'Total de Alunos',
        '${_resumo!.totalAlunos}',
        Icons.people,
        MapleBearTheme.primary,
        '/alunos',
      ),
      _KPIItem(
        'Cobranças Vencidas',
        '${_resumo!.cobrancasVencidas}',
        Icons.warning_amber,
        MapleBearTheme.statusVencido,
        '/financeiro',
      ),
      _KPIItem(
        'Novas Matrículas',
        '${_resumo!.novasMatriculas}',
        Icons.assignment_turned_in,
        MapleBearTheme.success,
        '/matriculas',
      ),
      _KPIItem(
        'Eventos Hoje',
        '${_resumo!.eventosHoje}',
        Icons.event,
        MapleBearTheme.info,
        '/agenda',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) => _KPICard(item: item)).toList(),
    );
  }

  Widget _buildFinanceiroResumo() {
    if (_resumo == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Financeiro do Mês',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.go('/financeiro'),
                  child: const Text('Ver tudo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FinanceiroTile(
                    label: 'Receita',
                    valor: _currencyFormat.format(_resumo!.receitaMes),
                    cor: MapleBearTheme.success,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FinanceiroTile(
                    label: 'Inadimplência',
                    valor: '${_resumo!.inadimplencia.toStringAsFixed(1)}%',
                    cor: _resumo!.inadimplencia > 10
                        ? MapleBearTheme.statusVencido
                        : MapleBearTheme.warning,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcessoRapido() {
    final acoes = [
      _AcaoRapida('Nova Matrícula', Icons.person_add, '/matriculas/nova'),
      _AcaoRapida('Novo Comunicado', Icons.campaign, '/comunicados/novo'),
      _AcaoRapida('Novo Evento', Icons.event_note, '/agenda/novo-evento'),
      _AcaoRapida('Nova Cobrança', Icons.receipt_long, '/financeiro/nova-cobranca'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acesso Rápido', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: acoes
              .map((a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => context.go(a.rota),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MapleBearTheme.divider),
                          ),
                          child: Column(
                            children: [
                              Icon(a.icon, color: MapleBearTheme.primary, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                a.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: MapleBearTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAlunosPorSerie() {
    if (_resumo == null || _resumo!.alunosPorSerie.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alunos por Série', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._resumo!.alunosPorSerie.map((s) {
              final maxQtd = _resumo!.alunosPorSerie
                  .map((e) => e.quantidade)
                  .reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.serie,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${s.quantidade}',
                            style: const TextStyle(
                                fontSize: 13, color: MapleBearTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.quantidade / maxQtd,
                        backgroundColor: MapleBearTheme.divider,
                        valueColor: const AlwaysStoppedAnimation(MapleBearTheme.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _KPIItem {
  final String label;
  final String valor;
  final IconData icon;
  final Color cor;
  final String rota;
  const _KPIItem(this.label, this.valor, this.icon, this.cor, this.rota);
}

class _KPICard extends StatelessWidget {
  final _KPIItem item;
  const _KPICard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.rota),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.cor, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.valor,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: item.cor,
                  ),
                ),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MapleBearTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceiroTile extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final IconData icon;
  const _FinanceiroTile(
      {required this.label,
      required this.valor,
      required this.cor,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cor, size: 18),
          const SizedBox(height: 6),
          Text(valor,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: cor)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: MapleBearTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _AcaoRapida {
  final String label;
  final IconData icon;
  final String rota;
  const _AcaoRapida(this.label, this.icon, this.rota);
}
