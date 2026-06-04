import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/sponte_api_service.dart';
import '../../models/financeiro.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildGrupo(context, 'Financeiro', [
            _RelatorioItem(
              titulo: 'Inadimplência',
              descricao: 'Alunos com mensalidades vencidas',
              icon: Icons.warning_amber,
              cor: MapleBearTheme.statusVencido,
              onTap: () => _abrirInadimplencia(context),
            ),
            _RelatorioItem(
              titulo: 'Receita Mensal',
              descricao: 'Resumo de recebimentos por mês',
              icon: Icons.bar_chart,
              cor: MapleBearTheme.success,
              onTap: () {},
            ),
            _RelatorioItem(
              titulo: 'Cobranças por Tipo',
              descricao: 'Mensalidades, materiais, uniformes...',
              icon: Icons.pie_chart,
              cor: MapleBearTheme.info,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),
          _buildGrupo(context, 'Alunos', [
            _RelatorioItem(
              titulo: 'Alunos por Série',
              descricao: 'Distribuição de alunos por série/turma',
              icon: Icons.school,
              cor: MapleBearTheme.primary,
              onTap: () {},
            ),
            _RelatorioItem(
              titulo: 'Frequência',
              descricao: 'Relatório de presença e faltas',
              icon: Icons.fact_check,
              cor: MapleBearTheme.warning,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),
          _buildGrupo(context, 'Matrículas', [
            _RelatorioItem(
              titulo: 'Matrículas por Período',
              descricao: 'Novas matrículas e renovações',
              icon: Icons.assignment_turned_in,
              cor: MapleBearTheme.secondary,
              onTap: () {},
            ),
            _RelatorioItem(
              titulo: 'Documentação Pendente',
              descricao: 'Alunos com documentos faltando',
              icon: Icons.folder_open,
              cor: MapleBearTheme.statusPendente,
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MapleBearTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MapleBearTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: MapleBearTheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Central de Relatórios',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: MapleBearTheme.primary,
                        )),
                Text(
                  'Dados sincronizados com o Sponte',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupo(
      BuildContext context, String titulo, List<_RelatorioItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final item = e.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.cor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: item.cor, size: 22),
                    ),
                    title: Text(item.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.descricao,
                        style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right,
                        color: MapleBearTheme.textSecondary),
                    onTap: item.onTap,
                  ),
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirInadimplencia(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _InadimplenciaSheet(),
    );
  }
}

class _InadimplenciaSheet extends StatefulWidget {
  const _InadimplenciaSheet();

  @override
  State<_InadimplenciaSheet> createState() => _InadimplenciaSheetState();
}

class _InadimplenciaSheetState extends State<_InadimplenciaSheet> {
  List<Cobranca> _cobrancas = [];
  bool _carregando = true;
  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final api = context.read<SponteApiService>();
      _cobrancas = await api.getInadimplentes();
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  double get _totalVencido =>
      _cobrancas.fold(0, (sum, c) => sum + c.valorFinal);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Inadimplentes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                if (!_carregando)
                  Text(
                    _currencyFmt.format(_totalVencido),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MapleBearTheme.statusVencido),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (_cobrancas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum inadimplente encontrado!',
                      style: TextStyle(color: MapleBearTheme.success)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _cobrancas.length,
                  itemBuilder: (_, i) {
                    final c = _cobrancas[i];
                    return ListTile(
                      title: Text(c.alunoNome,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${c.descricao} • ${c.diasAtraso}d em atraso'),
                      trailing: Text(
                        _currencyFmt.format(c.valorFinal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: MapleBearTheme.statusVencido),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RelatorioItem {
  final String titulo;
  final String descricao;
  final IconData icon;
  final Color cor;
  final VoidCallback onTap;

  const _RelatorioItem({
    required this.titulo,
    required this.descricao,
    required this.icon,
    required this.cor,
    required this.onTap,
  });
}
