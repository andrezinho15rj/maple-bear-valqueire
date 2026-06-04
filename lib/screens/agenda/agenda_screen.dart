import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../models/agenda.dart';
import '../../services/sponte_api_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focado = DateTime.now();
  DateTime _selecionado = DateTime.now();
  Map<DateTime, List<Evento>> _eventos = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final api = context.read<SponteApiService>();
      final inicio = DateTime(_focado.year, _focado.month, 1);
      final fim = DateTime(_focado.year, _focado.month + 1, 0);
      final lista = await api.getEventos(de: inicio, ate: fim);

      final mapa = <DateTime, List<Evento>>{};
      for (final e in lista) {
        final key = _normalize(e.inicio);
        mapa.putIfAbsent(key, () => []).add(e);
      }
      setState(() => _eventos = mapa);
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  List<Evento> _eventosNoDia(DateTime dia) =>
      _eventos[_normalize(dia)] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() {
              _focado = DateTime.now();
              _selecionado = DateTime.now();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/agenda/novo-evento');
          _carregar();
        },
        backgroundColor: MapleBearTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Evento',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          TableCalendar<Evento>(
            locale: 'pt_BR',
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focado,
            selectedDayPredicate: (d) => isSameDay(d, _selecionado),
            eventLoader: _eventosNoDia,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: MapleBearTheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: MapleBearTheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: MapleBearTheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: MapleBearTheme.textPrimary,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left,
                  color: MapleBearTheme.primary),
              rightChevronIcon: const Icon(Icons.chevron_right,
                  color: MapleBearTheme.primary),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selecionado = selected;
                _focado = focused;
              });
            },
            onPageChanged: (focused) {
              _focado = focused;
              _carregar();
            },
          ),
          const Divider(height: 1),
          Expanded(child: _buildEventosDia()),
        ],
      ),
    );
  }

  Widget _buildEventosDia() {
    final eventos = _eventosNoDia(_selecionado);
    final dateFmt = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            dateFmt.format(_selecionado),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MapleBearTheme.primary),
          ),
        ),
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else if (eventos.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Nenhum evento neste dia',
                      style: TextStyle(color: MapleBearTheme.textSecondary)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: eventos.length,
              itemBuilder: (_, i) => _EventoCard(evento: eventos[i]),
            ),
          ),
      ],
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Evento evento;
  const _EventoCard({required this.evento});

  Color get _tipoCor {
    switch (evento.tipo) {
      case 'reuniao': return MapleBearTheme.info;
      case 'feriado': return MapleBearTheme.statusVencido;
      case 'tarefa': return MapleBearTheme.warning;
      default: return MapleBearTheme.primary;
    }
  }

  IconData get _tipoIcon {
    switch (evento.tipo) {
      case 'reuniao': return Icons.groups;
      case 'feriado': return Icons.celebration;
      case 'tarefa': return Icons.task_alt;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'pt_BR');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _tipoCor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _tipoCor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_tipoIcon, color: _tipoCor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.titulo,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  if (evento.descricao != null)
                    Text(evento.descricao!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: MapleBearTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: MapleBearTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        evento.diaInteiro
                            ? 'Dia inteiro'
                            : '${timeFmt.format(evento.inicio)}${evento.fim != null ? ' - ${timeFmt.format(evento.fim!)}' : ''}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: MapleBearTheme.textSecondary),
                      ),
                      if (evento.local != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            size: 12, color: MapleBearTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(evento.local!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: MapleBearTheme.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
