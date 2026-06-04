import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/sponte_api_service.dart';

class ComunicadoFormScreen extends StatefulWidget {
  const ComunicadoFormScreen({super.key});

  @override
  State<ComunicadoFormScreen> createState() => _ComunicadoFormScreenState();
}

class _ComunicadoFormScreenState extends State<ComunicadoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _corpoCtrl = TextEditingController();
  String _tipo = 'aviso';
  List<String> _destinatarios = ['todos'];
  bool _publicarImediatamente = false;
  bool _salvando = false;

  static const _tiposDestinatarios = [
    'todos', 'Berçário', 'Maternal I', 'Maternal II',
    'Jardim I', 'Jardim II', '1º Ano', '2º Ano',
    '3º Ano', '4º Ano', '5º Ano',
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _corpoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final comunicado = await context.read<SponteApiService>().criarComunicado({
        'titulo': _tituloCtrl.text.trim(),
        'corpo': _corpoCtrl.text.trim(),
        'tipo': _tipo,
        'destinatarios': _destinatarios,
        'publicado': _publicarImediatamente,
        'criado_por': 'secretaria',
        'criado_em': DateTime.now().toIso8601String(),
      });

      if (_publicarImediatamente && comunicado.id.isNotEmpty) {
        await context
            .read<SponteApiService>()
            .publicarComunicado(comunicado.id);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_publicarImediatamente
                ? 'Comunicado publicado!'
                : 'Comunicado salvo como rascunho!'),
            backgroundColor: MapleBearTheme.success,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao salvar comunicado.'),
            backgroundColor: MapleBearTheme.error),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Comunicado')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                  labelText: 'Tipo de Comunicado',
                  prefixIcon: Icon(Icons.campaign_outlined)),
              items: const [
                DropdownMenuItem(value: 'aviso', child: Text('Aviso')),
                DropdownMenuItem(value: 'circular', child: Text('Circular')),
                DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: Icon(Icons.title)),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe o título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _corpoCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Mensagem *',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Icon(Icons.message_outlined),
                ),
              ),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe a mensagem' : null,
            ),
            const SizedBox(height: 16),
            const Text('Destinatários:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: MapleBearTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tiposDestinatarios.map((d) {
                final selected = _destinatarios.contains(d);
                return FilterChip(
                  label: Text(d, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (d == 'todos') {
                        _destinatarios = v ? ['todos'] : [];
                      } else {
                        _destinatarios.remove('todos');
                        if (v) {
                          _destinatarios.add(d);
                        } else {
                          _destinatarios.remove(d);
                        }
                        if (_destinatarios.isEmpty) {
                          _destinatarios = ['todos'];
                        }
                      }
                    });
                  },
                  selectedColor: MapleBearTheme.primary.withOpacity(0.2),
                  checkmarkColor: MapleBearTheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publicar imediatamente'),
              subtitle: const Text('Enviar agora para os destinatários'),
              value: _publicarImediatamente,
              activeColor: MapleBearTheme.primary,
              onChanged: (v) => setState(() => _publicarImediatamente = v),
              contentPadding: EdgeInsets.zero,
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
                  : Text(_publicarImediatamente
                      ? 'Publicar Comunicado'
                      : 'Salvar como Rascunho'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
