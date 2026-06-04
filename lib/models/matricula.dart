class Matricula {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String? turmaId;
  final String? turma;
  final String? serie;
  final String periodo;
  final String anoLetivo;
  final String status; // ativa, inativa, trancada, cancelada, transferida
  final DateTime dataMatricula;
  final DateTime? dataCancelamento;
  final String? motivoCancelamento;
  final double? valorMensalidade;
  final double? desconto;
  final String? planoPagamento;
  final List<String> documentosEntregues;
  final List<String> documentosPendentes;
  final String? observacoes;
  final bool renovacao;
  final String? matriculaAnteriorId;

  const Matricula({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    this.turmaId,
    this.turma,
    this.serie,
    required this.periodo,
    required this.anoLetivo,
    required this.status,
    required this.dataMatricula,
    this.dataCancelamento,
    this.motivoCancelamento,
    this.valorMensalidade,
    this.desconto,
    this.planoPagamento,
    this.documentosEntregues = const [],
    this.documentosPendentes = const [],
    this.observacoes,
    this.renovacao = false,
    this.matriculaAnteriorId,
  });

  factory Matricula.fromJson(Map<String, dynamic> json) => Matricula(
        id: json['id']?.toString() ?? '',
        alunoId: json['aluno_id']?.toString() ?? '',
        alunoNome: json['aluno_nome'] ?? '',
        turmaId: json['turma_id']?.toString(),
        turma: json['turma'],
        serie: json['serie'],
        periodo: json['periodo'] ?? '',
        anoLetivo: json['ano_letivo'] ?? '',
        status: json['status'] ?? 'ativa',
        dataMatricula: DateTime.parse(json['data_matricula']),
        dataCancelamento: json['data_cancelamento'] != null
            ? DateTime.tryParse(json['data_cancelamento'])
            : null,
        motivoCancelamento: json['motivo_cancelamento'],
        valorMensalidade: json['valor_mensalidade']?.toDouble(),
        desconto: json['desconto']?.toDouble(),
        planoPagamento: json['plano_pagamento'],
        documentosEntregues:
            List<String>.from(json['documentos_entregues'] ?? []),
        documentosPendentes:
            List<String>.from(json['documentos_pendentes'] ?? []),
        observacoes: json['observacoes'],
        renovacao: json['renovacao'] ?? false,
        matriculaAnteriorId: json['matricula_anterior_id']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'aluno_id': alunoId,
        'turma_id': turmaId,
        'serie': serie,
        'periodo': periodo,
        'ano_letivo': anoLetivo,
        'status': status,
        'data_matricula': dataMatricula.toIso8601String(),
        'valor_mensalidade': valorMensalidade,
        'desconto': desconto,
        'plano_pagamento': planoPagamento,
        'documentos_entregues': documentosEntregues,
        'documentos_pendentes': documentosPendentes,
        'observacoes': observacoes,
        'renovacao': renovacao,
      };

  double get valorFinal =>
      (valorMensalidade ?? 0) - ((valorMensalidade ?? 0) * (desconto ?? 0) / 100);

  bool get documentacaoCompleta => documentosPendentes.isEmpty;
}

class Turma {
  final String id;
  final String nome;
  final String serie;
  final String periodo;
  final String? professor;
  final int capacidade;
  final int qtdAlunos;
  final String anoLetivo;
  final bool ativa;

  const Turma({
    required this.id,
    required this.nome,
    required this.serie,
    required this.periodo,
    this.professor,
    required this.capacidade,
    required this.qtdAlunos,
    required this.anoLetivo,
    required this.ativa,
  });

  factory Turma.fromJson(Map<String, dynamic> json) => Turma(
        id: json['id']?.toString() ?? '',
        nome: json['nome'] ?? '',
        serie: json['serie'] ?? '',
        periodo: json['periodo'] ?? '',
        professor: json['professor'],
        capacidade: json['capacidade'] ?? 0,
        qtdAlunos: json['qtd_alunos'] ?? 0,
        anoLetivo: json['ano_letivo'] ?? '',
        ativa: json['ativa'] ?? true,
      );

  int get vagasDisponiveis => capacidade - qtdAlunos;
  bool get temVaga => vagasDisponiveis > 0;
}
