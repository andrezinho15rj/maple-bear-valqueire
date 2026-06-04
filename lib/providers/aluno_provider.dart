import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../models/matricula.dart';
import '../services/sponte_api_service.dart';

class AlunoProvider extends ChangeNotifier {
  final SponteApiService _api;

  List<Aluno> _alunos = [];
  Aluno? _alunoSelecionado;
  List<Turma> _turmas = [];
  bool _carregando = false;
  bool _carregandoMais = false;
  String? _erro;
  int _pagina = 1;
  bool _temMais = true;
  String _busca = '';
  String? _filtroStatus;
  String? _filtroSerie;

  AlunoProvider(this._api);

  List<Aluno> get alunos => _alunos;
  Aluno? get alunoSelecionado => _alunoSelecionado;
  List<Turma> get turmas => _turmas;
  bool get carregando => _carregando;
  bool get carregandoMais => _carregandoMais;
  String? get erro => _erro;
  bool get temMais => _temMais;

  Future<void> carregar({bool reset = false}) async {
    if (reset) {
      _pagina = 1;
      _alunos = [];
      _temMais = true;
    }
    if (!_temMais) return;

    if (_pagina == 1) {
      _carregando = true;
    } else {
      _carregandoMais = true;
    }
    _erro = null;
    notifyListeners();

    try {
      final resultado = await _api.getAlunos(
        busca: _busca,
        status: _filtroStatus,
        serie: _filtroSerie,
        page: _pagina,
      );
      if (_pagina == 1) {
        _alunos = resultado;
      } else {
        _alunos.addAll(resultado);
      }
      _temMais = resultado.length >= 20;
      _pagina++;
    } catch (e) {
      _erro = 'Erro ao carregar alunos.';
    } finally {
      _carregando = false;
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<void> carregarMais() async {
    if (!_carregandoMais && _temMais) await carregar();
  }

  Future<void> buscar(String busca) async {
    _busca = busca;
    await carregar(reset: true);
  }

  void filtrar({String? status, String? serie}) {
    _filtroStatus = status;
    _filtroSerie = serie;
    carregar(reset: true);
  }

  Future<void> selecionarAluno(String id) async {
    _carregando = true;
    notifyListeners();
    try {
      _alunoSelecionado = await _api.getAluno(id);
    } catch (_) {
      _erro = 'Erro ao carregar aluno.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> criarAluno(Map<String, dynamic> dados) async {
    try {
      final aluno = await _api.criarAluno(dados);
      _alunos.insert(0, aluno);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> atualizarAluno(String id, Map<String, dynamic> dados) async {
    try {
      final atualizado = await _api.atualizarAluno(id, dados);
      final idx = _alunos.indexWhere((a) => a.id == id);
      if (idx != -1) _alunos[idx] = atualizado;
      if (_alunoSelecionado?.id == id) _alunoSelecionado = atualizado;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> carregarTurmas() async {
    try {
      _turmas = await _api.getTurmas(ativa: true);
      notifyListeners();
    } catch (_) {}
  }
}
