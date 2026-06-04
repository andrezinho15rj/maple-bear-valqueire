import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/aluno.dart';
import '../models/financeiro.dart';
import '../models/matricula.dart';
import '../models/agenda.dart';
import '../models/dashboard.dart';
import '../models/usuario.dart';

class SponteApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SponteApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.sponteBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.sponteTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token =
                await _storage.read(key: AppConstants.sponteTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        return handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await _dio.post(
      SpontePaths.login,
      data: {'email': email, 'senha': senha, 'tipo': 'secretaria'},
    );
    await _storage.write(
        key: AppConstants.sponteTokenKey,
        value: response.data['access_token']);
    await _storage.write(
        key: AppConstants.sponteRefreshTokenKey,
        value: response.data['refresh_token']);
    return response.data;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConstants.sponteRefreshTokenKey);
      if (refreshToken == null) return false;
      final response = await _dio.post(
        SpontePaths.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      await _storage.write(
          key: AppConstants.sponteTokenKey,
          value: response.data['access_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(SpontePaths.logout);
    } finally {
      await _storage.delete(key: AppConstants.sponteTokenKey);
      await _storage.delete(key: AppConstants.sponteRefreshTokenKey);
    }
  }

  Future<Usuario> getPerfil() async {
    final response = await _dio.get(SpontePaths.perfil);
    return Usuario.fromJson(response.data);
  }

  // ─── DASHBOARD ─────────────────────────────────────────────────────────────

  Future<DashboardResumo> getDashboard() async {
    final response = await _dio.get(SpontePaths.dashboard);
    return DashboardResumo.fromJson(response.data);
  }

  // ─── ALUNOS ────────────────────────────────────────────────────────────────

  Future<List<Aluno>> getAlunos({
    String? busca,
    String? status,
    String? turmaId,
    String? serie,
    int page = 1,
    int pageSize = AppConstants.pageSize,
  }) async {
    final response = await _dio.get(
      SpontePaths.alunos,
      queryParameters: {
        if (busca != null && busca.isNotEmpty) 'busca': busca,
        if (status != null) 'status': status,
        if (turmaId != null) 'turma_id': turmaId,
        if (serie != null) 'serie': serie,
        'page': page,
        'page_size': pageSize,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Aluno.fromJson(j)).toList();
  }

  Future<Aluno> getAluno(String id) async {
    final response = await _dio.get(SpontePaths.alunoById(id));
    return Aluno.fromJson(response.data);
  }

  Future<Aluno> criarAluno(Map<String, dynamic> dados) async {
    final response = await _dio.post(SpontePaths.alunos, data: dados);
    return Aluno.fromJson(response.data);
  }

  Future<Aluno> atualizarAluno(String id, Map<String, dynamic> dados) async {
    final response =
        await _dio.put(SpontePaths.alunoById(id), data: dados);
    return Aluno.fromJson(response.data);
  }

  Future<void> inativarAluno(String id, String motivo) async {
    await _dio.patch(
      '${SpontePaths.alunoById(id)}/inativar',
      data: {'motivo': motivo},
    );
  }

  Future<String> uploadFotoAluno(String id, String caminhoFoto) async {
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(caminhoFoto, filename: 'foto.jpg'),
    });
    final response = await _dio.post(
      SpontePaths.alunoFoto(id),
      data: formData,
    );
    return response.data['url'];
  }

  // ─── RESPONSÁVEIS ──────────────────────────────────────────────────────────

  Future<List<Responsavel>> getResponsaveis(String alunoId) async {
    final response = await _dio.get(
      SpontePaths.responsaveis,
      queryParameters: {'aluno_id': alunoId},
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Responsavel.fromJson(j)).toList();
  }

  Future<Responsavel> criarResponsavel(
      String alunoId, Map<String, dynamic> dados) async {
    final response = await _dio.post(
      SpontePaths.responsaveis,
      data: {...dados, 'aluno_id': alunoId},
    );
    return Responsavel.fromJson(response.data);
  }

  // ─── TURMAS ────────────────────────────────────────────────────────────────

  Future<List<Turma>> getTurmas({String? anoLetivo, bool? ativa}) async {
    final response = await _dio.get(
      SpontePaths.turmas,
      queryParameters: {
        if (anoLetivo != null) 'ano_letivo': anoLetivo,
        if (ativa != null) 'ativa': ativa,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Turma.fromJson(j)).toList();
  }

  Future<List<Aluno>> getAlunosDaTurma(String turmaId) async {
    final response = await _dio.get(SpontePaths.turmaAlunos(turmaId));
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Aluno.fromJson(j)).toList();
  }

  // ─── MATRÍCULAS ────────────────────────────────────────────────────────────

  Future<List<Matricula>> getMatriculas({
    String? status,
    String? anoLetivo,
    String? busca,
    int page = 1,
  }) async {
    final response = await _dio.get(
      SpontePaths.matriculas,
      queryParameters: {
        if (status != null) 'status': status,
        if (anoLetivo != null) 'ano_letivo': anoLetivo,
        if (busca != null && busca.isNotEmpty) 'busca': busca,
        'page': page,
        'page_size': AppConstants.pageSize,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Matricula.fromJson(j)).toList();
  }

  Future<Matricula> getMatricula(String id) async {
    final response = await _dio.get(SpontePaths.matriculaById(id));
    return Matricula.fromJson(response.data);
  }

  Future<Matricula> criarMatricula(Map<String, dynamic> dados) async {
    final response = await _dio.post(SpontePaths.matriculas, data: dados);
    return Matricula.fromJson(response.data);
  }

  Future<Matricula> atualizarMatricula(
      String id, Map<String, dynamic> dados) async {
    final response =
        await _dio.put(SpontePaths.matriculaById(id), data: dados);
    return Matricula.fromJson(response.data);
  }

  Future<void> cancelarMatricula(String id, String motivo) async {
    await _dio.patch(
      '${SpontePaths.matriculaById(id)}/cancelar',
      data: {'motivo': motivo},
    );
  }

  Future<void> renovarMatricula(String id, Map<String, dynamic> dados) async {
    await _dio.post('${SpontePaths.matriculaById(id)}/renovar', data: dados);
  }

  // ─── FINANCEIRO ────────────────────────────────────────────────────────────

  Future<List<Cobranca>> getCobrancas({
    String? status,
    String? alunoId,
    String? tipo,
    DateTime? vencimentoDe,
    DateTime? vencimentoAte,
    String? competencia,
    int page = 1,
  }) async {
    final response = await _dio.get(
      SpontePaths.cobrancas,
      queryParameters: {
        if (status != null) 'status': status,
        if (alunoId != null) 'aluno_id': alunoId,
        if (tipo != null) 'tipo': tipo,
        if (vencimentoDe != null)
          'vencimento_de': vencimentoDe.toIso8601String().substring(0, 10),
        if (vencimentoAte != null)
          'vencimento_ate': vencimentoAte.toIso8601String().substring(0, 10),
        if (competencia != null) 'competencia': competencia,
        'page': page,
        'page_size': AppConstants.pageSize,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Cobranca.fromJson(j)).toList();
  }

  Future<Cobranca> getCobranca(String id) async {
    final response = await _dio.get(SpontePaths.cobrancaById(id));
    return Cobranca.fromJson(response.data);
  }

  Future<Cobranca> criarCobranca(Map<String, dynamic> dados) async {
    final response = await _dio.post(SpontePaths.cobrancas, data: dados);
    return Cobranca.fromJson(response.data);
  }

  Future<ResumoFinanceiro> getResumoFinanceiro({String? competencia}) async {
    final response = await _dio.get(
      '${SpontePaths.financeiro}/resumo',
      queryParameters: {if (competencia != null) 'competencia': competencia},
    );
    return ResumoFinanceiro.fromJson(response.data);
  }

  Future<Cobranca> gerarBoleto(String cobrancaId) async {
    final response =
        await _dio.post(SpontePaths.gerarBoleto(cobrancaId));
    return Cobranca.fromJson(response.data);
  }

  Future<void> baixaManual(BaixaManual baixa) async {
    await _dio.post(
      SpontePaths.baixaManual(baixa.cobrancaId),
      data: baixa.toJson(),
    );
  }

  Future<void> cancelarCobranca(String id, String motivo) async {
    await _dio.patch(
      '${SpontePaths.cobrancaById(id)}/cancelar',
      data: {'motivo': motivo},
    );
  }

  Future<List<Cobranca>> getInadimplentes({String? competencia}) async {
    final response = await _dio.get(
      SpontePaths.relatorioInadimplencia,
      queryParameters: {if (competencia != null) 'competencia': competencia},
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Cobranca.fromJson(j)).toList();
  }

  // ─── AGENDA ────────────────────────────────────────────────────────────────

  Future<List<Evento>> getEventos({
    DateTime? de,
    DateTime? ate,
    String? tipo,
  }) async {
    final response = await _dio.get(
      SpontePaths.eventos,
      queryParameters: {
        if (de != null) 'de': de.toIso8601String().substring(0, 10),
        if (ate != null) 'ate': ate.toIso8601String().substring(0, 10),
        if (tipo != null) 'tipo': tipo,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Evento.fromJson(j)).toList();
  }

  Future<Evento> criarEvento(Map<String, dynamic> dados) async {
    final response = await _dio.post(SpontePaths.eventos, data: dados);
    return Evento.fromJson(response.data);
  }

  Future<Evento> atualizarEvento(String id, Map<String, dynamic> dados) async {
    final response = await _dio.put(SpontePaths.eventoById(id), data: dados);
    return Evento.fromJson(response.data);
  }

  Future<void> excluirEvento(String id) async {
    await _dio.delete(SpontePaths.eventoById(id));
  }

  // ─── COMUNICADOS ───────────────────────────────────────────────────────────

  Future<List<Comunicado>> getComunicados({
    bool? publicado,
    String? tipo,
    int page = 1,
  }) async {
    final response = await _dio.get(
      SpontePaths.comunicados,
      queryParameters: {
        if (publicado != null) 'publicado': publicado,
        if (tipo != null) 'tipo': tipo,
        'page': page,
        'page_size': AppConstants.pageSize,
      },
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((j) => Comunicado.fromJson(j)).toList();
  }

  Future<Comunicado> criarComunicado(Map<String, dynamic> dados) async {
    final response = await _dio.post(SpontePaths.comunicados, data: dados);
    return Comunicado.fromJson(response.data);
  }

  Future<void> publicarComunicado(String id) async {
    await _dio.patch('${SpontePaths.comunicadoById(id)}/publicar');
  }

  Future<void> excluirComunicado(String id) async {
    await _dio.delete(SpontePaths.comunicadoById(id));
  }
}
