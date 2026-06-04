import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/sponte_api_service.dart';

class EventoFormScreen extends StatefulWidget {
  const EventoFormScreen({super.key});

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  String _tipo = 'evento';
  bool _diaInteiro = false;
  bool _notificarResponsaveis = false;
  DateTime _inicio = DateTime.now();
  DateTime _fim = DateTime.now().add(const Duration(hours: 1));
  bool _salvando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _localCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      await context.read<SponteApiService>().criarEvento({
        'titulo': _tituloCtrl.text.trim(),
        'descricao': _descricaoCtrl.text.trim(),
        'local': _localCtrl.text.trim(),
        'tipo': _tipo,
        'inicio': _inicio.toIso8601String(),
        'fim': _diaInteiro ? null : _fim.toIso8601String(),
        'dia_inteiro': _diaInteiro,
        'notificar_responsaveis': _notificarResponsaveis,
        'destinatarios': ['todos'],
        'criado_por': 'secretaria',
        'criado_em': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Evento criado!'),
              backgroundColor: MapleBearTheme.success),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao criar evento.'),
            backgroundColor: MapleBearTheme.error),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final dateSoFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Evento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: Icon(Icons.title)),
              validator: (v) =>
                  v?.isEmpty == true ? 'Informe o título' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: const [
                DropdownMenuItem(value: 'evento', child: Text('Evento')),
                DropdownMenuItem(value: 'reuniao', child: Text('Reunião')),
                DropdownMenuItem(value: 'feriado', child: Text('Feriado')),
                DropdownMenuItem(value: 'tarefa', child: Text('Tarefa')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _localCtrl,
              decoration: const InputDecoration(
                  labelText: 'Local',
                  prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Dia inteiro'),
              value: _diaInteiro,
              activeColor: MapleBearTheme.primary,
              onChanged: (v) => setState(() => _diaInteiro = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final dt = await showDateTimePicker(context, _inicio);
                if (dt != null) setState(() => _inicio = dt);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _diaInteiro ? 'Data' : 'Início',
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(_diaInteiro
                    ? dateSoFmt.format(_inicio)
                    : dateFmt.format(_inicio)),
              ),
            ),
            if (!_diaInteiro) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final dt = await showDateTimePicker(context, _fim);
                  if (dt != null) setState(() => _fim = dt);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fim',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(dateFmt.format(_fim)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificar responsáveis'),
              subtitle: const Text('Enviar comunicado para os responsáveis'),
              value: _notificarResponsaveis,
              activeColor: MapleBearTheme.primary,
              onChanged: (v) => setState(() => _notificarResponsaveis = v),
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
                  : const Text('Criar Evento'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
    );
    if (date == null || !context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
