import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/financeiro_provider.dart';

class NovaCobrancaScreen extends StatefulWidget {
  const NovaCobrancaScreen({super.key});

  @override
  State<NovaCobrancaScreen> createState() => _NovaCobrancaScreenState();
}

class _NovaCobrancaScreenState extends State<NovaCobrancaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alunoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  String _tipo = 'mensalidade';
  DateTime _vencimento = DateTime.now().add(const Duration(days: 5));
  double _desconto = 0;
  bool _salvando = false;

  @override
  void dispose() {
    _alunoCtrl.dispose();
    _descricaoCtrl.dispose();
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

    final ok = await context.read<FinanceiroProvider>().criarCobranca({
      'aluno_nome': _alunoCtrl.text.trim(),
      'descricao': _descricaoCtrl.text.trim(),
      'valor': valor,
      'desconto': _desconto,
      'vencimento': _vencimento.toIso8601String(),
      'tipo': _tipo,
      'observacoes': _observacoesCtrl.text.trim(),
    });

    setState(() => _salvando = false);
    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cobrança criada com sucesso!'),
            backgroundColor: MapleBearTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Cobrança')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _alunoCtrl,
              decoration: const InputDecoration(
                labelText: 'Aluno *',
                prefixIcon: Icon(Icons.person_outlined),
                hintText: 'Nome do aluno',
              ),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe o aluno' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'mensalidade', child: Text('Mensalidade')),
                DropdownMenuItem(value: 'material', child: Text('Material')),
                DropdownMenuItem(value: 'uniforme', child: Text('Uniforme')),
                DropdownMenuItem(value: 'excursao', child: Text('Excursão')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor *',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v?.isEmpty == true) return 'Informe o valor';
                final num = double.tryParse(
                    v!.replaceAll('.', '').replaceAll(',', '.'));
                if (num == null || num <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: _vencimento,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (dt != null) setState(() => _vencimento = dt);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Vencimento',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFmt.format(_vencimento)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: '0',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Desconto (%)',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                    onChanged: (v) =>
                        _desconto = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.notes),
              ),
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
                  : const Text('Criar Cobrança'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
