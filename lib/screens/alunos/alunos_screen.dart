import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/aluno.dart';
import '../../providers/aluno_provider.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  final _buscaCtrl = TextEditingController();
  String? _filtroStatus;
  String? _filtroSerie;

  static const _series = [
    'Berçário', 'Maternal I', 'Maternal II', 'Jardim I',
    'Jardim II', '1º Ano', '2º Ano', '3º Ano', '4º Ano', '5º Ano',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlunoProvider>().carregar(reset: true);
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alunos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/alunos/novo'),
        backgroundColor: MapleBearTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Novo Aluno',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _buildBusca(),
          if (_filtroStatus != null || _filtroSerie != null) _buildFiltrosAtivos(),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  Widget _buildBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _buscaCtrl,
        decoration: InputDecoration(
          hintText: 'Buscar por nome, RA ou CPF...',
          prefixIcon: const Icon(Icons.search, color: MapleBearTheme.primary),
          suffixIcon: _buscaCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscaCtrl.clear();
                    context.read<AlunoProvider>().buscar('');
                  },
                )
              : null,
        ),
        onChanged: (v) {
          if (v.length >= 3 || v.isEmpty) {
            context.read<AlunoProvider>().buscar(v);
          }
        },
      ),
    );
  }

  Widget _buildFiltrosAtivos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Text('Filtros: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MapleBearTheme.textSecondary)),
          if (_filtroStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Chip(
                label: Text(_filtroStatus!),
                onDeleted: () {
                  setState(() => _filtroStatus = null);
                  context.read<AlunoProvider>().filtrar(
                      status: null, serie: _filtroSerie);
                },
                deleteIconColor: MapleBearTheme.primary,
                backgroundColor: MapleBearTheme.primary.withOpacity(0.1),
                labelStyle: const TextStyle(
                    color: MapleBearTheme.primary, fontSize: 12),
              ),
            ),
          if (_filtroSerie != null)
            Chip(
              label: Text(_filtroSerie!),
              onDeleted: () {
                setState(() => _filtroSerie = null);
                context.read<AlunoProvider>().filtrar(
                    status: _filtroStatus, serie: null);
              },
              deleteIconColor: MapleBearTheme.primary,
              backgroundColor: MapleBearTheme.primary.withOpacity(0.1),
              labelStyle: const TextStyle(
                  color: MapleBearTheme.primary, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return Consumer<AlunoProvider>(
      builder: (context, provider, _) {
        if (provider.carregando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.erro != null) {
          return _buildErro(provider.erro!);
        }
        if (provider.alunos.isEmpty) {
          return _buildVazio();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount:
              provider.alunos.length + (provider.carregandoMais ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (context, i) {
            if (i == provider.alunos.length) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            }
            if (i == provider.alunos.length - 3) {
              provider.carregarMais();
            }
            return _AlunoCard(aluno: provider.alunos[i]);
          },
        );
      },
    );
  }

  Widget _buildErro(String erro) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: MapleBearTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(erro),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<AlunoProvider>().carregar(reset: true),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Nenhum aluno encontrado',
              style: TextStyle(
                  color: MapleBearTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FiltroSheet(
        statusAtual: _filtroStatus,
        serieAtual: _filtroSerie,
        series: _series,
        onAplicar: (status, serie) {
          setState(() {
            _filtroStatus = status;
            _filtroSerie = serie;
          });
          context.read<AlunoProvider>().filtrar(status: status, serie: serie);
        },
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  final Aluno aluno;
  const _AlunoCard({required this.aluno});

  Color get _statusCor {
    switch (aluno.status) {
      case 'ativo': return MapleBearTheme.statusAtivo;
      case 'inativo': return MapleBearTheme.statusInativo;
      case 'trancado': return MapleBearTheme.statusVencido;
      default: return MapleBearTheme.statusInativo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: () => context.go('/alunos/${aluno.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno.nomeExibicao,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (aluno.serie != null) ...[
                          const Icon(Icons.class_,
                              size: 13, color: MapleBearTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(aluno.serie!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: MapleBearTheme.textSecondary)),
                          const SizedBox(width: 10),
                        ],
                        if (aluno.periodo != null) ...[
                          const Icon(Icons.access_time,
                              size: 13, color: MapleBearTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(aluno.periodo!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: MapleBearTheme.textSecondary)),
                        ],
                      ],
                    ),
                    if (aluno.ra != null)
                      Text('RA: ${aluno.ra}',
                          style: const TextStyle(
                              fontSize: 11, color: MapleBearTheme.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusCor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      aluno.status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusCor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: MapleBearTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MapleBearTheme.primary.withOpacity(0.1),
      ),
      child: aluno.foto != null
          ? ClipOval(
              child: Image.network(aluno.foto!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _iniciais()))
          : _iniciais(),
    );
  }

  Widget _iniciais() {
    final partes = aluno.nomeExibicao.split(' ');
    final iniciais = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'
        : partes[0].substring(0, 2);
    return Center(
      child: Text(
        iniciais.toUpperCase(),
        style: const TextStyle(
            color: MapleBearTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FiltroSheet extends StatefulWidget {
  final String? statusAtual;
  final String? serieAtual;
  final List<String> series;
  final Function(String? status, String? serie) onAplicar;

  const _FiltroSheet({
    required this.statusAtual,
    required this.serieAtual,
    required this.series,
    required this.onAplicar,
  });

  @override
  State<_FiltroSheet> createState() => _FiltroSheetState();
}

class _FiltroSheetState extends State<_FiltroSheet> {
  String? _status;
  String? _serie;

  @override
  void initState() {
    super.initState();
    _status = widget.statusAtual;
    _serie = widget.serieAtual;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtrar Alunos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () {
                  setState(() { _status = null; _serie = null; });
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['ativo', 'inativo', 'trancado'].map((s) {
              return ChoiceChip(
                label: Text(s),
                selected: _status == s,
                onSelected: (v) => setState(() => _status = v ? s : null),
                selectedColor: MapleBearTheme.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Série:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.series.map((s) {
              return ChoiceChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                selected: _serie == s,
                onSelected: (v) => setState(() => _serie = v ? s : null),
                selectedColor: MapleBearTheme.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onAplicar(_status, _serie);
            },
            child: const Text('Aplicar Filtros'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
