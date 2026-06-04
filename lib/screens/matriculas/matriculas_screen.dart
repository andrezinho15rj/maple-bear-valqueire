import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/matricula.dart';
import '../../services/sponte_api_service.dart';

class MatriculasScreen extends StatefulWidget {
  const MatriculasScreen({super.key});

  @override
  State<MatriculasScreen> createState() => _MatriculasScreenState();
}

class _MatriculasScreenState extends State<MatriculasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Matricula> _matriculas = [];
  bool _carregando = true;
  String? _filtroStatus;
  final _buscaCtrl = TextEditingController();

  static const _tabs = ['Todas', 'Ativas', 'Renovação Pendente', 'Canceladas'];
  static const _statusMap = {
    'Todas': null,
    'Ativas': 'ativa',
    'Renovação Pendente': 'pendente',
    'Canceladas': 'cancelada',
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        _filtroStatus = _statusMap[_tabs[_tab.index]];
        _carregar();
      }
    });
    _carregar();
  }

  @override
  void dispose() {
    _tab.dispose();
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final api = context.read<SponteApiService>();
      _matriculas = await api.getMatriculas(status: _filtroStatus);
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrículas'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: MapleBearTheme.secondaryLight,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/matriculas/nova'),
        backgroundColor: MapleBearTheme.primary,
        icon: const Icon(Icons.assignment_ind, color: Colors.white),
        label: const Text('Nova Matrícula',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscaCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar matrícula...',
                prefixIcon: Icon(Icons.search, color: MapleBearTheme.primary),
              ),
              onChanged: (v) {
                if (v.length >= 3 || v.isEmpty) _carregar();
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: _tabs.map((_) {
                if (_carregando) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_matriculas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma matrícula encontrada',
                        style: TextStyle(color: MapleBearTheme.textSecondary)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _matriculas.length,
                    itemBuilder: (_, i) =>
                        _MatriculaCard(matricula: _matriculas[i]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatriculaCard extends StatelessWidget {
  final Matricula matricula;
  const _MatriculaCard({required this.matricula});

  Color get _statusCor {
    switch (matricula.status) {
      case 'ativa': return MapleBearTheme.statusAtivo;
      case 'cancelada': return MapleBearTheme.statusVencido;
      case 'trancada': return MapleBearTheme.warning;
      default: return MapleBearTheme.statusPendente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () => context.go('/matriculas/${matricula.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      matricula.alunoNome,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusCor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      matricula.status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusCor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(Icons.class_, matricula.serie ?? '—'),
                  const SizedBox(width: 8),
                  _InfoChip(Icons.access_time, matricula.periodo),
                  const SizedBox(width: 8),
                  _InfoChip(Icons.calendar_today, matricula.anoLetivo),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matrícula: ${dateFmt.format(matricula.dataMatricula)}',
                    style: const TextStyle(
                        fontSize: 12, color: MapleBearTheme.textSecondary),
                  ),
                  if (matricula.valorFinal > 0)
                    Text(
                      currencyFmt.format(matricula.valorFinal),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MapleBearTheme.primary),
                    ),
                ],
              ),
              if (!matricula.documentacaoCompleta) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 14, color: MapleBearTheme.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${matricula.documentosPendentes.length} documento(s) pendente(s)',
                      style: const TextStyle(
                          fontSize: 12, color: MapleBearTheme.warning),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: MapleBearTheme.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: MapleBearTheme.textSecondary)),
      ],
    );
  }
}
