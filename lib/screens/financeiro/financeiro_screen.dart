import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/financeiro.dart';
import '../../providers/financeiro_provider.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static const _tabs = ['Todas', 'Pendentes', 'Pagas', 'Vencidas'];
  static const _statusMap = {
    'Todas': null,
    'Pendentes': 'pendente',
    'Pagas': 'pago',
    'Vencidas': 'vencido',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = _statusMap[_tabs[_tabController.index]];
        context.read<FinanceiroProvider>().filtrar(status: status);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceiroProvider>().carregar(reset: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: MapleBearTheme.secondaryLight,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _filtros),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/financeiro/nova-cobranca'),
        backgroundColor: MapleBearTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Cobrança',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Consumer<FinanceiroProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              if (provider.resumo != null) _buildResumo(provider.resumo!),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((_) {
                    if (provider.carregando) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.cobrancas.isEmpty) {
                      return _buildVazio();
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          provider.carregar(reset: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: provider.cobrancas.length,
                        itemBuilder: (_, i) =>
                            _CobrancaCard(cobranca: provider.cobrancas[i]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumo(ResumoFinanceiro resumo) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildResumoTile(
            'A Receber',
            _currencyFmt.format(resumo.totalReceber),
            MapleBearTheme.info,
          ),
          _buildDivider(),
          _buildResumoTile(
            'Recebido',
            _currencyFmt.format(resumo.totalRecebido),
            MapleBearTheme.success,
          ),
          _buildDivider(),
          _buildResumoTile(
            'Vencido',
            _currencyFmt.format(resumo.totalVencido),
            MapleBearTheme.statusVencido,
          ),
        ],
      ),
    );
  }

  Widget _buildResumoTile(String label, String valor, Color cor) {
    return Expanded(
      child: Column(
        children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cor),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: MapleBearTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 32, width: 1, color: MapleBearTheme.divider);
  }

  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Nenhuma cobrança encontrada',
              style: TextStyle(color: MapleBearTheme.textSecondary)),
        ],
      ),
    );
  }

  void _filtros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar por Tipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['mensalidade', 'material', 'uniforme', 'excursao', 'outro']
                  .map((t) => ActionChip(
                        label: Text(t),
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<FinanceiroProvider>().filtrar(tipo: t);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CobrancaCard extends StatelessWidget {
  final Cobranca cobranca;
  const _CobrancaCard({required this.cobranca});

  Color get _statusCor {
    if (cobranca.isPago) return MapleBearTheme.statusPago;
    if (cobranca.isVencida) return MapleBearTheme.statusVencido;
    return MapleBearTheme.statusPendente;
  }

  String get _statusLabel {
    if (cobranca.isPago) return 'PAGO';
    if (cobranca.isVencida) return '${cobranca.diasAtraso}d vencido';
    return 'PENDENTE';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () => context.go('/financeiro/${cobranca.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusCor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cobranca.isPago ? Icons.check_circle : Icons.receipt_long,
                  color: _statusCor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cobranca.alunoNome,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cobranca.descricao,
                      style: const TextStyle(
                          fontSize: 12, color: MapleBearTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vencimento: ${dateFmt.format(cobranca.vencimento)}',
                      style: const TextStyle(
                          fontSize: 11, color: MapleBearTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFmt.format(cobranca.valorFinal),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _statusCor),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusCor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusCor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
