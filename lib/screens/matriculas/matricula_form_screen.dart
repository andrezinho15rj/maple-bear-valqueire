import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/matricula.dart';
import '../../services/sponte_api_service.dart';

class MatriculaFormScreen extends StatefulWidget {
  const MatriculaFormScreen({super.key});

  @override
  State<MatriculaFormScreen> createState() => _MatriculaFormScreenState();
}

class _MatriculaFormScreenState extends State<MatriculaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alunoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  String? _serie;
  String _periodo = 'manha';
  String _planoPagamento = 'mensal';
  String _anoLetivo = DateTime.now().year.toString();
  DateTime _dataMatricula = DateTime.now();
  double _desconto = 0;
  Turma? _turmaSelecionada;
  List<Turma> _turmas = [];
  bool _salvando = false;
  List<String> _documentosSelecionados = [];

  static const _documentosNecessarios = [
    'Certidão de Nascimento',
    'RG dos Responsáveis',
    'CPF dos Responsáveis',
    'Comprovante de Endereço',
    'Foto 3x4',
    'Cartão de Vacinação',
    'Histórico Escolar',
    'Declaração de Transferência',
  ];

  static const _series = [
    'Berçário', 'Maternal I', 'Maternal II', 'Jardim I', 'Jardim II',
    '1º Ano', '2º Ano', '3º Ano', '4º Ano', '5º Ano',
  ];

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  Future<void> _carregarTurmas() async {
    try {
      final turmas = await context.read<SponteApiService>().getTurmas(ativa: true);
      setState(() => _turmas = turmas);
    } catch (_) {}
  }

  @override
  void dispose() {
    _alunoCtrl.dispose();
    _valorCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final valor = double.tryParse(
            _valorCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0;

    try {
      await context.read<SponteApiService>().criarMatricula({
        'aluno_nome': _alunoCtrl.text.trim(),
        'turma_id': _turmaSelecionada?.id,
        'serie': _serie,
        'periodo': _periodo,
        'ano_letivo': _anoLetivo,
        'data_matricula': _dataMatricula.toIso8601String(),
        'valor_mensalidade': valor,
        'desconto': _desconto,
        'plano_pagamento': _planoPagamento,
        'documentos_entregues': _documentosSelecionados,
        'documentos_pendentes': _documentosNecessarios
            .where((d) => !_documentosSelecionados.contains(d))
            .toList(),
        'observacoes': _observacoesCtrl.text.trim(),
      });

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Matrícula realizada com sucesso!'),
              backgroundColor: MapleBearTheme.success),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao realizar matrícula.'),
            backgroundColor: MapleBearTheme.error),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Matrícula')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _secao('Dados do Aluno'),
            TextFormField(
              controller: _alunoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome do Aluno *',
                  prefixIcon: Icon(Icons.person_outlined)),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe o aluno' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final dt = await showDatePicker(
                  context: context,
                  initialDate: _dataMatricula,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('pt', 'BR'),
                );
                if (dt != null) setState(() => _dataMatricula = dt);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data da Matrícula',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateFmt.format(_dataMatricula)),
              ),
            ),
            const SizedBox(height: 20),
            _secao('Dados Escolares'),
            DropdownButtonFormField<String>(
              value: _serie,
              decoration: const InputDecoration(labelText: 'Série *'),
              items: _series
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              validator: (v) =>
                  v == null ? 'Selecione a série' : null,
              onChanged: (v) => setState(() => _serie = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _periodo,
              decoration: const InputDecoration(labelText: 'Período'),
              items: const [
                DropdownMenuItem(value: 'manha', child: Text('Manhã')),
                DropdownMenuItem(value: 'tarde', child: Text('Tarde')),
                DropdownMenuItem(value: 'integral', child: Text('Integral')),
              ],
              onChanged: (v) => setState(() => _periodo = v!),
            ),
            const SizedBox(height: 12),
            if (_turmas.isNotEmpty)
              DropdownButtonFormField<Turma>(
                value: _turmaSelecionada,
                decoration: const InputDecoration(labelText: 'Turma'),
                items: _turmas
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                              '${t.nome} (${t.vagasDisponiveis} vagas)'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _turmaSelecionada = v),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _anoLetivo,
              decoration: const InputDecoration(labelText: 'Ano Letivo'),
              items: [
                DateTime.now().year.toString(),
                (DateTime.now().year + 1).toString(),
              ]
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _anoLetivo = v!),
            ),
            const SizedBox(height: 20),
            _secao('Financeiro'),
            TextFormField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da Mensalidade *',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '0',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Desconto (%)',
                      suffixText: '%',
                    ),
                    onChanged: (v) =>
                        _desconto = double.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _planoPagamento,
                    decoration: const InputDecoration(labelText: 'Plano'),
                    items: const [
                      DropdownMenuItem(
                          value: 'mensal', child: Text('Mensal')),
                      DropdownMenuItem(
                          value: 'anual', child: Text('Anual')),
                      DropdownMenuItem(
                          value: 'semestral', child: Text('Semestral')),
                    ],
                    onChanged: (v) =>
                        setState(() => _planoPagamento = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _secao('Documentação'),
            const Text(
              'Marque os documentos já entregues:',
              style: TextStyle(
                  fontSize: 13, color: MapleBearTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ..._documentosNecessarios.map((doc) => CheckboxListTile(
                  title: Text(doc, style: const TextStyle(fontSize: 13)),
                  value: _documentosSelecionados.contains(doc),
                  activeColor: MapleBearTheme.primary,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _documentosSelecionados.add(doc);
                      } else {
                        _documentosSelecionados.remove(doc);
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 20),
            _secao('Observações'),
            TextFormField(
              controller: _observacoesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Informações adicionais...'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Realizar Matrícula'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(titulo,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MapleBearTheme.primary)),
    );
  }
}
