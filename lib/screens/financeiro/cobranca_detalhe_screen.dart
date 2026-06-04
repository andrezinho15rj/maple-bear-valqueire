import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/financeiro.dart';
import '../../providers/financeiro_provider.dart';
import '../../services/sponte_api_service.dart';

class CobrancaDetalheScreen extends StatefulWidget {
  final String id;
  const CobrancaDetalheScreen({super.key, required this.id});

  @override
  State<CobrancaDetalheScreen> createState() => _CobrancaDetalheScreenState();
}

class _CobrancaDetalheScreenState extends State<CobrancaDetalheScreen> {
  Cobranca? _cobranca;
  bool _carregando = true;
  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final api = context.read<SponteApiService>();
      _cobranca = await api.getCobranca(widget.id);
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da Cobrança'),
        actions: [
          if (_cobranca != null && !_cobranca!.isPago)
            PopupMenuButton<String>(
              onSelected: _executarAcao,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'baixa', child: Text('Baixa Manual')),
                PopupMenuItem(value: 'boleto', child: Text('Gerar Boleto')),
                PopupMenuItem(value: 'cancelar', child: Text('Cancelar')),
              ],
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _cobranca == null
              ? const Center(child: Text('Cobrança não encontrada'))
              : _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    final c = _cobranca!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatus(c),
        const SizedBox(height: 16),
        _buildInfoCard(c),
        const SizedBox(height: 16),
        _buildValoresCard(c),
        if (c.boletoLinhaDigitavel != null) ...[
          const SizedBox(height: 16),
          _buildBoletoCard(c),
        ],
        if (!c.isPago) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _executarAcao('baixa'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Registrar Pagamento'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _executarAcao('boleto'),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Gerar / Ver Boleto'),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatus(Cobranca c) {
    Color cor;
    String label;
    IconData icon;

    if (c.isPago) {
      cor = MapleBearTheme.statusPago;
      label = 'PAGO em ${c.pagamento != null ? _dateFmt.format(c.pagamento!) : ''}';
      icon = Icons.check_circle;
    } else if (c.isVencida) {
      cor = MapleBearTheme.statusVencido;
      label = '${c.diasAtraso} dias em atraso';
      icon = Icons.warning;
    } else {
      cor = MapleBearTheme.statusPendente;
      label = 'PENDENTE';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: cor)),
              if (c.formaPagamento != null)
                Text('Via ${c.formaPagamento}',
                    style: const TextStyle(
                        fontSize: 12, color: MapleBearTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Cobranca c) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: MapleBearTheme.primary)),
            const SizedBox(height: 12),
            _InfoRow('Aluno', c.alunoNome),
            _InfoRow('Descrição', c.descricao),
            _InfoRow('Tipo', c.tipo),
            _InfoRow('Vencimento', _dateFmt.format(c.vencimento)),
            if (c.competencia != null)
              _InfoRow('Competência', c.competencia!),
            if (c.nossoNumero != null)
              _InfoRow('Nosso Número', c.nossoNumero!),
            if (c.observacoes != null)
              _InfoRow('Obs.', c.observacoes!),
          ],
        ),
      ),
    );
  }

  Widget _buildValoresCard(Cobranca c) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Valores',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: MapleBearTheme.primary)),
            const SizedBox(height: 12),
            _InfoRow('Valor Original', _currencyFmt.format(c.valor)),
            if (c.desconto != null && c.desconto! > 0)
              _InfoRow('Desconto',
                  '- ${_currencyFmt.format(c.desconto)}',
                  cor: MapleBearTheme.success),
            if (c.multa != null && c.multa! > 0)
              _InfoRow('Multa',
                  '+ ${_currencyFmt.format(c.multa)}',
                  cor: MapleBearTheme.statusVencido),
            if (c.juros != null && c.juros! > 0)
              _InfoRow('Juros',
                  '+ ${_currencyFmt.format(c.juros)}',
                  cor: MapleBearTheme.statusVencido),
            const Divider(),
            _InfoRow('Valor Final', _currencyFmt.format(c.valorFinal),
                negrito: true, cor: MapleBearTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBoletoCard(Cobranca c) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt, color: MapleBearTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('Boleto',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MapleBearTheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MapleBearTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c.boletoLinhaDigitavel!,
                style: const TextStyle(
                    fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: c.boletoLinhaDigitavel!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Código copiado!'),
                            backgroundColor: MapleBearTheme.success),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar Código'),
                  ),
                ),
                if (c.boletoUrl != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(c.boletoUrl!)),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Abrir PDF'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executarAcao(String acao) async {
    if (acao == 'baixa') {
      _mostrarBaixaManual();
    } else if (acao == 'boleto') {
      final ok =
          await context.read<FinanceiroProvider>().gerarBoleto(widget.id);
      if (ok) await _carregar();
    } else if (acao == 'cancelar') {
      _confirmarCancelamento();
    }
  }

  void _mostrarBaixaManual() {
    final valorCtrl = TextEditingController(
        text: _cobranca?.valorFinal.toStringAsFixed(2));
    String formaPagamento = 'Dinheiro';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration:
                  const InputDecoration(labelText: 'Forma de Pagamento'),
              items: ['Dinheiro', 'PIX', 'Boleto', 'Cartão Débito', 'Cartão Crédito', 'Transferência']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => formaPagamento = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Valor Pago', prefixText: 'R\$ '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<FinanceiroProvider>().darBaixa(
                BaixaManual(
                  cobrancaId: widget.id,
                  dataPagamento: DateTime.now(),
                  valorPago:
                      double.tryParse(valorCtrl.text.replaceAll(',', '.')) ??
                          0,
                  formaPagamento: formaPagamento,
                ),
              );
              if (ok) await _carregar();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmarCancelamento() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar Cobrança'),
        content: const Text('Confirma o cancelamento desta cobrança?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Não')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<FinanceiroProvider>()
                  .cancelarCobranca(widget.id, 'Cancelado pela secretaria');
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: MapleBearTheme.error),
            child: const Text('Cancelar Cobrança'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool negrito;
  final Color? cor;

  const _InfoRow(this.label, this.valor, {this.negrito = false, this.cor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
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
                        negrito ? FontWeight.w700 : FontWeight.w500,
                    color: cor ?? MapleBearTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
