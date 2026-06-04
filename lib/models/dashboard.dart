class DashboardResumo {
  final int totalAlunos;
  final int alunosAtivos;
  final int novasMatriculas;
  final int renovacoesPendentes;
  final double receitaMes;
  final double inadimplencia;
  final int cobrancasVencidas;
  final int eventosHoje;
  final int comunicadosPendentes;
  final List<ResumoMensal> receitaMensal;
  final List<AlunosPorSerie> alunosPorSerie;

  const DashboardResumo({
    required this.totalAlunos,
    required this.alunosAtivos,
    required this.novasMatriculas,
    required this.renovacoesPendentes,
    required this.receitaMes,
    required this.inadimplencia,
    required this.cobrancasVencidas,
    required this.eventosHoje,
    required this.comunicadosPendentes,
    required this.receitaMensal,
    required this.alunosPorSerie,
  });

  factory DashboardResumo.fromJson(Map<String, dynamic> json) =>
      DashboardResumo(
        totalAlunos: json['total_alunos'] ?? 0,
        alunosAtivos: json['alunos_ativos'] ?? 0,
        novasMatriculas: json['novas_matriculas'] ?? 0,
        renovacoesPendentes: json['renovacoes_pendentes'] ?? 0,
        receitaMes: (json['receita_mes'] ?? 0).toDouble(),
        inadimplencia: (json['inadimplencia'] ?? 0).toDouble(),
        cobrancasVencidas: json['cobrancas_vencidas'] ?? 0,
        eventosHoje: json['eventos_hoje'] ?? 0,
        comunicadosPendentes: json['comunicados_pendentes'] ?? 0,
        receitaMensal: (json['receita_mensal'] as List<dynamic>?)
                ?.map((e) => ResumoMensal.fromJson(e))
                .toList() ??
            [],
        alunosPorSerie: (json['alunos_por_serie'] as List<dynamic>?)
                ?.map((e) => AlunosPorSerie.fromJson(e))
                .toList() ??
            [],
      );
}

class ResumoMensal {
  final String mes;
  final double previsto;
  final double recebido;

  const ResumoMensal({
    required this.mes,
    required this.previsto,
    required this.recebido,
  });

  factory ResumoMensal.fromJson(Map<String, dynamic> json) => ResumoMensal(
        mes: json['mes'] ?? '',
        previsto: (json['previsto'] ?? 0).toDouble(),
        recebido: (json['recebido'] ?? 0).toDouble(),
      );
}

class AlunosPorSerie {
  final String serie;
  final int quantidade;

  const AlunosPorSerie({required this.serie, required this.quantidade});

  factory AlunosPorSerie.fromJson(Map<String, dynamic> json) => AlunosPorSerie(
        serie: json['serie'] ?? '',
        quantidade: json['quantidade'] ?? 0,
      );
}
