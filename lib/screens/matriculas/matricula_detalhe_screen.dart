import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/matricula.dart';
import '../../services/sponte_api_service.dart';

class MatriculaDetalheScreen extends StatefulWidget {
  final String id;
  const MatriculaDetalheScreen({super.key, required this.id});

  @override
  State<MatriculaDetalheScreen> createState() => _MatriculaDetalheScreenState();
}

class _MatriculaDetalheScreenState extends State<MatriculaDetalheScreen> {
  Matricula? _matricula;
  bool _carregando = true;
  final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      _matricula = await context.read<SponteApiService>().getMatricula(widget.id);
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da Matrícula'),
        actions: [
          if (_matricula != null && _matricula!.status == 'ativa')
            PopupMenuButton<String>(
              onSelected: _executarAcao,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'renovar', child: Text('Renovar Matrícula')),
                PopupMenuItem(value: 'cancelar', child: Text('Cancelar Matrícula')),
              ],
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _matricula == null
              ? const Center(child: Text('Matrícula não encontrada'))
              : _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    final m = _matricula!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusBanner(m),
        const SizedBox(height: 16),
        _buildCard('Dados da Matrícula', [
          _InfoRow('Aluno', m.alunoNome),
          _InfoRow('Série', m.serie ?? '—'),
          _InfoRow('Período', m.periodo),
          _InfoRow('Turma', m.turma ?? '—'),
          _InfoRow('Ano Letivo', m.anoLetivo),
          _InfoRow('Data da Matrícula', _dateFmt.format(m.dataMatricula)),
          if (m.dataCancelamento != null)
            _InfoRow('Cancelamento', _dateFmt.format(m.dataCancelamento!)),
          if (m.motivoCancelamento != null)
            _InfoRow('Motivo', m.motivoCancelamento!),
        ]),
        const SizedBox(height: 12),
        _buildCard('Financeiro', [
          _InfoRow('Mensalidade',
              _currencyFmt.format(m.valorMensalidade ?? 0)),
          if (m.desconto != null && m.desconto! > 0)
            _InfoRow('Desconto', '${m.desconto!.toStringAsFixed(0)}%'),
          _InfoRow('Valor Final', _currencyFmt.format(m.valorFinal),
              negrito: true),
          if (m.planoPagamento != null)
            _InfoRow('Plano', m.planoPagamento!),
        ]),
        const SizedBox(height: 12),
        _buildDocumentacao(m),
        if (m.observacoes != null) ...[
          const SizedBox(height: 12),
          _buildCard('Observações', [_InfoRow('', m.observacoes!)]),
        ],
        if (m.status == 'ativa') ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _executarAcao('renovar'),
            icon: const Icon(Icons.autorenew),
            label: const Text('Renovar para Próximo Ano'),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatusBanner(Matricula m) {
    final Map<String, Color> cores = {
      'ativa': MapleBearTheme.statusAtivo,
      'cancelada': MapleBearTheme.statusVencido,
      'trancada': MapleBearTheme.warning,
      'transferida': MapleBearTheme.info,
    };
    final cor = cores[m.status] ?? MapleBearTheme.statusInativo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: cor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: cor)),
              Text(m.alunoNome,
                  style: const TextStyle(
                      fontSize: 13, color: MapleBearTheme.textSecondary)),
            ],
          ),
          if (m.renovacao) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MapleBearTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('RENOVAÇÃO',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MapleBearTheme.secondary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(String titulo, List<Widget> filhos) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MapleBearTheme.primary)),
            const SizedBox(height: 12),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentacao(Matricula m) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Documentação',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MapleBearTheme.primary)),
                const Spacer(),
                Text(
                  m.documentacaoCompleta ? 'Completa' : 'Incompleta',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: m.documentacaoCompleta
                          ? MapleBearTheme.success
                          : MapleBearTheme.warning),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (m.documentosEntregues.isNotEmpty) ...[
              const Text('Entregues:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ...m.documentosEntregues.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: MapleBearTheme.success),
                        const SizedBox(width: 6),
                        Text(d, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
            ],
            if (m.documentosPendentes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Pendentes:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ...m.documentosPendentes.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            size: 14, color: MapleBearTheme.warning),
                        const SizedBox(width: 6),
                        Text(d, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _executarAcao(String acao) {
    if (acao == 'cancelar') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cancelar Matrícula'),
          content: const Text('Confirma o cancelamento da matrícula?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Não')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await context
                    .read<SponteApiService>()
                    .cancelarMatricula(widget.id, 'Cancelado pela secretaria');
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: MapleBearTheme.error),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool negrito;

  const _InfoRow(this.label, this.valor, {this.negrito = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: MapleBearTheme.textSecondary)),
            ),
          Expanded(
            child: Text(valor,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        negrito ? FontWeight.w700 : FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
