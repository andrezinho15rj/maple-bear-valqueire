class AppConstants {
  static const String appName = 'Maple Bear Valqueire';
  static const String appVersion = '1.0.0';

  // Sponte API
  static const String sponteBaseUrl = 'https://api.sponte.com.br/v2';
  static const String sponteTokenKey = 'sponte_token';
  static const String sponteRefreshTokenKey = 'sponte_refresh_token';
  static const String sponteEscolaId = 'sponte_escola_id';

  // Storage Keys
  static const String userKey = 'current_user';
  static const String themeKey = 'app_theme';
  static const String notificationsKey = 'notifications_enabled';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Paginação
  static const int pageSize = 20;

  // Módulos do App
  static const List<String> modulos = [
    'dashboard',
    'alunos',
    'financeiro',
    'matriculas',
    'agenda',
    'comunicados',
    'relatorios',
  ];
}

class SpontePaths {
  // Auth
  static const String login = '/auth/token';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Alunos
  static const String alunos = '/alunos';
  static String alunoById(String id) => '/alunos/$id';
  static String alunoFoto(String id) => '/alunos/$id/foto';
  static String alunoDocumentos(String id) => '/alunos/$id/documentos';
  static String alunoHistorico(String id) => '/alunos/$id/historico';

  // Responsáveis
  static const String responsaveis = '/responsaveis';
  static String responsavelById(String id) => '/responsaveis/$id';

  // Turmas
  static const String turmas = '/turmas';
  static String turmaById(String id) => '/turmas/$id';
  static String turmaAlunos(String id) => '/turmas/$id/alunos';

  // Matrículas
  static const String matriculas = '/matriculas';
  static String matriculaById(String id) => '/matriculas/$id';
  static String matriculaDocumentos(String id) => '/matriculas/$id/documentos';

  // Financeiro
  static const String financeiro = '/financeiro';
  static const String cobrancas = '/financeiro/cobrancas';
  static const String pagamentos = '/financeiro/pagamentos';
  static const String boletos = '/financeiro/boletos';
  static String cobrancaById(String id) => '/financeiro/cobrancas/$id';
  static String gerarBoleto(String id) => '/financeiro/cobrancas/$id/boleto';
  static String baixaManual(String id) => '/financeiro/cobrancas/$id/baixa';

  // Agenda
  static const String agenda = '/agenda';
  static const String eventos = '/agenda/eventos';
  static String eventoById(String id) => '/agenda/eventos/$id';

  // Comunicados
  static const String comunicados = '/comunicados';
  static String comunicadoById(String id) => '/comunicados/$id';

  // Relatórios
  static const String relatorios = '/relatorios';
  static const String relatorioInadimplencia = '/relatorios/inadimplencia';
  static const String relatorioMatriculas = '/relatorios/matriculas';
  static const String relatorioFrequencia = '/relatorios/frequencia';
  static const String relatorioFinanceiro = '/relatorios/financeiro';

  // Dashboard
  static const String dashboard = '/dashboard/resumo';

  // Usuários
  static const String usuarios = '/usuarios';
  static const String perfil = '/usuarios/perfil';
}
