import 'package:flutter/material.dart';
import '../models/financeiro.dart';
import '../services/sponte_api_service.dart';

class FinanceiroProvider extends ChangeNotifier {
  final SponteApiService _api;

  List<Cobranca> _cobrancas = [];
  ResumoFinanceiro? _resumo;
  bool _carregando = false;
  String? _erro;
  String? _filtroStatus;
  String? _filtroTipo;
  String? _competencia;
  int _pagina = 1;
  bool _temMais = true;

  FinanceiroProvider(this._api);

  List<Cobranca> get cobrancas => _cobrancas;
  ResumoFinanceiro? get resumo => _resumo;
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> carregar({bool reset = false}) async {
    if (reset) {
      _pagina = 1;
      _cobrancas = [];
      _temMais = true;
    }

    _carregando = _pagina == 1;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await _api.getCobrancas(
        status: _filtroStatus,
        tipo: _filtroTipo,
        competencia: _competencia,
        page: _pagina,
      );
      if (_pagina == 1) {
        _cobrancas = resultado;
      } else {
        _cobrancas.addAll(resultado);
      }
      _temMais = resultado.length >= 20;
      _pagina++;

      if (_resumo == null) await _carregarResumo();
    } catch (_) {
      _erro = 'Erro ao carregar cobranças.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> _carregarResumo() async {
    try {
      _resumo = await _api.getResumoFinanceiro(competencia: _competencia);
      notifyListeners();
    } catch (_) {}
  }

  void filtrar({String? status, String? tipo, String? competencia}) {
    _filtroStatus = status;
    _filtroTipo = tipo;
    _competencia = competencia;
    carregar(reset: true);
  }

  Future<bool> criarCobranca(Map<String, dynamic> dados) async {
    try {
      final cobranca = await _api.criarCobranca(dados);
      _cobrancas.insert(0, cobranca);
      await _carregarResumo();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> gerarBoleto(String id) async {
    try {
      final atualizada = await _api.gerarBoleto(id);
      final idx = _cobrancas.indexWhere((c) => c.id == id);
      if (idx != -1) _cobrancas[idx] = atualizada;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> darBaixa(BaixaManual baixa) async {
    try {
      await _api.baixaManual(baixa);
      await carregar(reset: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelarCobranca(String id, String motivo) async {
    try {
      await _api.cancelarCobranca(id, motivo);
      _cobrancas.removeWhere((c) => c.id == id);
      await _carregarResumo();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
