import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/aluno_provider.dart';

class AlunoFormScreen extends StatefulWidget {
  final String? id;
  const AlunoFormScreen({super.key, this.id});

  @override
  State<AlunoFormScreen> createState() => _AlunoFormScreenState();
}

class _AlunoFormScreenState extends State<AlunoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _nomeSocialCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _raCtrl = TextEditingController();

  final _cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');
  final _telefoneMask = MaskTextInputFormatter(mask: '(##) #####-####');

  String _sexo = 'M';
  String _periodo = 'manha';
  String? _serie;
  DateTime? _dataNascimento;
  bool _salvando = false;

  bool get isEdicao => widget.id != null;

  static const _series = [
    'Berçário', 'Maternal I', 'Maternal II', 'Jardim I', 'Jardim II',
    '1º Ano', '2º Ano', '3º Ano', '4º Ano', '5º Ano',
  ];

  @override
  void initState() {
    super.initState();
    if (isEdicao) _carregarDados();
    context.read<AlunoProvider>().carregarTurmas();
  }

  Future<void> _carregarDados() async {
    final provider = context.read<AlunoProvider>();
    final aluno = provider.alunoSelecionado;
    if (aluno != null) {
      _nomeCtrl.text = aluno.nome;
      _nomeSocialCtrl.text = aluno.nomeSocial ?? '';
      _cpfCtrl.text = aluno.cpf ?? '';
      _rgCtrl.text = aluno.rg ?? '';
      _emailCtrl.text = aluno.email ?? '';
      _telefoneCtrl.text = aluno.telefone ?? '';
      _observacoesCtrl.text = aluno.observacoes ?? '';
      _raCtrl.text = aluno.ra ?? '';
      _sexo = aluno.sexo ?? 'M';
      _periodo = aluno.periodo ?? 'manha';
      _serie = aluno.serie;
      _dataNascimento = aluno.dataNascimento;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _nomeSocialCtrl.dispose();
    _cpfCtrl.dispose();
    _rgCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _observacoesCtrl.dispose();
    _raCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final dados = {
      'nome': _nomeCtrl.text.trim(),
      'nome_social': _nomeSocialCtrl.text.trim().isEmpty
          ? null
          : _nomeSocialCtrl.text.trim(),
      'cpf': _cpfCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
      'rg': _rgCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telefone': _telefoneCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
      'observacoes': _observacoesCtrl.text.trim(),
      'ra': _raCtrl.text.trim(),
      'sexo': _sexo,
      'periodo': _periodo,
      'serie': _serie,
      'data_nascimento': _dataNascimento?.toIso8601String(),
    };

    final provider = context.read<AlunoProvider>();
    bool ok;
    if (isEdicao) {
      ok = await provider.atualizarAluno(widget.id!, dados);
    } else {
      ok = await provider.criarAluno(dados);
    }

    setState(() => _salvando = false);
    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdicao ? 'Aluno atualizado!' : 'Aluno cadastrado!'),
          backgroundColor: MapleBearTheme.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar aluno.'),
          backgroundColor: MapleBearTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Aluno' : 'Novo Aluno'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSecao('Dados Pessoais'),
            _buildCampo('Nome Completo *', _nomeCtrl,
                validator: (v) =>
                    v?.isEmpty == true ? 'Informe o nome' : null),
            _buildCampo('Nome Social', _nomeSocialCtrl),
            _buildCampo('RA', _raCtrl),
            Row(
              children: [
                Expanded(
                    child: _buildCampo('CPF', _cpfCtrl,
                        formatter: [_cpfMask],
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildCampo('RG', _rgCtrl)),
              ],
            ),
            _buildSexo(),
            _buildDataNascimento(),
            const SizedBox(height: 20),
            _buildSecao('Dados Escolares'),
            _buildSerie(),
            _buildPeriodo(),
            const SizedBox(height: 20),
            _buildSecao('Contato'),
            _buildCampo('E-mail', _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            _buildCampo('Telefone', _telefoneCtrl,
                formatter: [_telefoneMask],
                keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildSecao('Observações'),
            TextFormField(
              controller: _observacoesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Observações gerais...'),
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
                  : Text(isEdicao ? 'Atualizar Aluno' : 'Cadastrar Aluno'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: MapleBearTheme.primary),
      ),
    );
  }

  Widget _buildCampo(
    String label,
    TextEditingController ctrl, {
    String? Function(String?)? validator,
    List<dynamic> formatter = const [],
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: formatter.cast(),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildSexo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sexo',
              style: TextStyle(color: MapleBearTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _SexoOpcao(label: 'Masculino', value: 'M', groupValue: _sexo,
                  onChanged: (v) => setState(() => _sexo = v!)),
              const SizedBox(width: 12),
              _SexoOpcao(label: 'Feminino', value: 'F', groupValue: _sexo,
                  onChanged: (v) => setState(() => _sexo = v!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _periodo,
        decoration: const InputDecoration(labelText: 'Período'),
        items: const [
          DropdownMenuItem(value: 'manha', child: Text('Manhã')),
          DropdownMenuItem(value: 'tarde', child: Text('Tarde')),
          DropdownMenuItem(value: 'integral', child: Text('Integral')),
        ],
        onChanged: (v) => setState(() => _periodo = v!),
      ),
    );
  }

  Widget _buildSerie() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _serie,
        decoration: const InputDecoration(labelText: 'Série'),
        items: _series
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _serie = v),
      ),
    );
  }

  Widget _buildDataNascimento() {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final dt = await showDatePicker(
            context: context,
            initialDate: _dataNascimento ?? DateTime(2015),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            locale: const Locale('pt', 'BR'),
          );
          if (dt != null) setState(() => _dataNascimento = dt);
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Data de Nascimento',
            suffixIcon: Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            _dataNascimento != null ? fmt.format(_dataNascimento!) : '',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _SexoOpcao extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _SexoOpcao({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: MapleBearTheme.primary,
        ),
        Text(label),
      ],
    );
  }
}
