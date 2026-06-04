import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/aluno.dart';
import '../../providers/aluno_provider.dart';

class AlunoDetalheScreen extends StatefulWidget {
  final String id;
  const AlunoDetalheScreen({super.key, required this.id});

  @override
  State<AlunoDetalheScreen> createState() => _AlunoDetalheScreenState();
}

class _AlunoDetalheScreenState extends State<AlunoDetalheScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    context.read<AlunoProvider>().selecionarAluno(widget.id);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlunoProvider>(
      builder: (context, provider, _) {
        final aluno = provider.alunoSelecionado;

        if (provider.carregando) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (aluno == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Aluno')),
            body: const Center(child: Text('Aluno não encontrado')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, aluno),
              SliverToBoxAdapter(child: _buildHeader(aluno)),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tab,
                  labelColor: MapleBearTheme.primary,
                  unselectedLabelColor: MapleBearTheme.textSecondary,
                  indicatorColor: MapleBearTheme.primary,
                  tabs: const [
                    Tab(text: 'Dados'),
                    Tab(text: 'Responsáveis'),
                    Tab(text: 'Financeiro'),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildDados(aluno),
                    _buildResponsaveis(aluno),
                    _buildFinanceiro(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Aluno aluno) {
    return SliverAppBar(
      backgroundColor: MapleBearTheme.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.go('/alunos/${aluno.id}/editar'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) => _acaoAluno(context, v, aluno),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'inativar', child: Text('Inativar Aluno')),
            PopupMenuItem(value: 'imprimir', child: Text('Imprimir Ficha')),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(Aluno aluno) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Container(
      color: MapleBearTheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: aluno.foto != null
                ? ClipOval(
                    child: Image.network(aluno.foto!, fit: BoxFit.cover))
                : Center(
                    child: Text(
                      aluno.nomeExibicao.split(' ').take(2)
                          .map((p) => p[0]).join().toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nomeExibicao,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                if (aluno.ra != null)
                  Text('RA: ${aluno.ra}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (aluno.serie != null)
                  Text('${aluno.serie} • ${aluno.periodo ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (aluno.dataNascimento != null)
                  Text(
                    '${aluno.idade} anos (${dateFmt.format(aluno.dataNascimento!)})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: aluno.status == 'ativo'
                  ? Colors.green.shade400
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              aluno.status.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDados(Aluno aluno) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Secao('Informações Pessoais', [
          _CampoInfo('Nome completo', aluno.nome),
          if (aluno.nomeSocial != null)
            _CampoInfo('Nome social', aluno.nomeSocial!),
          if (aluno.cpf != null) _CampoInfo('CPF', aluno.cpf!),
          if (aluno.rg != null) _CampoInfo('RG', aluno.rg!),
          if (aluno.sexo != null) _CampoInfo('Sexo', aluno.sexo!),
          if (aluno.dataNascimento != null)
            _CampoInfo('Data de nascimento',
                dateFmt.format(aluno.dataNascimento!)),
        ]),
        const SizedBox(height: 12),
        _Secao('Dados Escolares', [
          if (aluno.turma != null) _CampoInfo('Turma', aluno.turma!),
          if (aluno.serie != null) _CampoInfo('Série', aluno.serie!),
          if (aluno.periodo != null) _CampoInfo('Período', aluno.periodo!),
          if (aluno.anoLetivo != null)
            _CampoInfo('Ano letivo', aluno.anoLetivo!),
          if (aluno.dataMatricula != null)
            _CampoInfo('Data de matrícula',
                dateFmt.format(aluno.dataMatricula!)),
        ]),
        const SizedBox(height: 12),
        _Secao('Contato', [
          if (aluno.email != null) _CampoInfo('E-mail', aluno.email!),
          if (aluno.telefone != null) _CampoInfo('Telefone', aluno.telefone!),
          if (aluno.endereco != null) _CampoInfo('Endereço', aluno.endereco!),
        ]),
        if (aluno.observacoes != null) ...[
          const SizedBox(height: 12),
          _Secao('Observações', [_CampoInfo('', aluno.observacoes!)]),
        ],
      ],
    );
  }

  Widget _buildResponsaveis(Aluno aluno) {
    if (aluno.responsaveis.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum responsável cadastrado'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: aluno.responsaveis.length,
      itemBuilder: (_, i) => _ResponsavelCard(resp: aluno.responsaveis[i]),
    );
  }

  Widget _buildFinanceiro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.attach_money, size: 48, color: MapleBearTheme.primary),
          const SizedBox(height: 12),
          const Text('Histórico financeiro do aluno'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Ver Cobranças'),
          ),
        ],
      ),
    );
  }

  void _acaoAluno(BuildContext context, String acao, Aluno aluno) {
    if (acao == 'inativar') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Inativar Aluno'),
          content: const Text('Confirma a inativação deste aluno?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AlunoProvider>().atualizarAluno(
                    aluno.id, {'status': 'inativo'});
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: MapleBearTheme.error),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    }
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> campos;
  const _Secao(this.titulo, this.campos);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MapleBearTheme.primary)),
            const SizedBox(height: 12),
            ...campos,
          ],
        ),
      ),
    );
  }
}

class _CampoInfo extends StatelessWidget {
  final String label;
  final String valor;
  const _CampoInfo(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: MapleBearTheme.textSecondary),
              ),
            ),
          ],
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ResponsavelCard extends StatelessWidget {
  final Responsavel resp;
  const _ResponsavelCard({required this.resp});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(resp.nome,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MapleBearTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(resp.parentesco,
                      style: const TextStyle(
                          fontSize: 11, color: MapleBearTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (resp.telefone.isNotEmpty)
              Row(children: [
                const Icon(Icons.phone, size: 14, color: MapleBearTheme.textSecondary),
                const SizedBox(width: 6),
                Text(resp.telefone, style: const TextStyle(fontSize: 13)),
              ]),
            if (resp.celular != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.smartphone, size: 14, color: MapleBearTheme.textSecondary),
                const SizedBox(width: 6),
                Text(resp.celular!, style: const TextStyle(fontSize: 13)),
              ]),
            ],
            if (resp.email != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.email_outlined, size: 14, color: MapleBearTheme.textSecondary),
                const SizedBox(width: 6),
                Text(resp.email!, style: const TextStyle(fontSize: 13)),
              ]),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (resp.financeiro)
                  _Tag('Financeiro', MapleBearTheme.success),
                if (resp.autorizado) ...[
                  const SizedBox(width: 6),
                  _Tag('Autorizado a buscar', MapleBearTheme.info),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color cor;
  const _Tag(this.label, this.cor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
    );
  }
}
