import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/agenda.dart';
import '../../services/sponte_api_service.dart';

class ComunicadosScreen extends StatefulWidget {
  const ComunicadosScreen({super.key});

  @override
  State<ComunicadosScreen> createState() => _ComunicadosScreenState();
}

class _ComunicadosScreenState extends State<ComunicadosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Comunicado> _comunicados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _carregar();
    });
    _carregar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final api = context.read<SponteApiService>();
      _comunicados = await api.getComunicados(
        publicado: _tab.index == 0 ? true : false,
      );
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicados'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: MapleBearTheme.secondaryLight,
          tabs: const [Tab(text: 'Publicados'), Tab(text: 'Rascunhos')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/comunicados/novo');
          _carregar();
        },
        backgroundColor: MapleBearTheme.primary,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Novo Comunicado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildLista(),
          _buildLista(),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_comunicados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum comunicado',
                style: TextStyle(color: MapleBearTheme.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _comunicados.length,
        itemBuilder: (_, i) => _ComunicadoCard(
          comunicado: _comunicados[i],
          onPublicar: () => _publicar(_comunicados[i].id),
          onExcluir: () => _excluir(_comunicados[i].id),
        ),
      ),
    );
  }

  Future<void> _publicar(String id) async {
    final api = context.read<SponteApiService>();
    await api.publicarComunicado(id);
    _carregar();
  }

  Future<void> _excluir(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Comunicado'),
        content: const Text('Deseja excluir este comunicado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MapleBearTheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<SponteApiService>().excluirComunicado(id);
      _carregar();
    }
  }
}

class _ComunicadoCard extends StatelessWidget {
  final Comunicado comunicado;
  final VoidCallback onPublicar;
  final VoidCallback onExcluir;

  const _ComunicadoCard({
    required this.comunicado,
    required this.onPublicar,
    required this.onExcluir,
  });

  Color get _tipoCor {
    switch (comunicado.tipo) {
      case 'urgente': return MapleBearTheme.statusVencido;
      case 'circular': return MapleBearTheme.info;
      default: return MapleBearTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tipoCor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    comunicado.tipo.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _tipoCor),
                  ),
                ),
                const Spacer(),
                if (!comunicado.publicado)
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onPublicar,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Publicar'),
                        style: TextButton.styleFrom(
                            foregroundColor: MapleBearTheme.success),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: MapleBearTheme.error, size: 20),
                        onPressed: onExcluir,
                      ),
                    ],
                  )
                else if (comunicado.totalVisualizacoes != null)
                  Row(
                    children: [
                      const Icon(Icons.visibility,
                          size: 14, color: MapleBearTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${comunicado.totalVisualizacoes}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: MapleBearTheme.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comunicado.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              comunicado.corpo,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: MapleBearTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.group_outlined,
                    size: 13, color: MapleBearTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  comunicado.destinatarios.join(', '),
                  style: const TextStyle(
                      fontSize: 12, color: MapleBearTheme.textSecondary),
                ),
                const Spacer(),
                Text(
                  dateFmt.format(comunicado.criadoEm),
                  style: const TextStyle(
                      fontSize: 11, color: MapleBearTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
