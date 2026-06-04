class Evento {
  final String id;
  final String titulo;
  final String? descricao;
  final DateTime inicio;
  final DateTime? fim;
  final bool diaInteiro;
  final String tipo; // reuniao, feriado, evento, tarefa, outro
  final String? local;
  final List<String> destinatarios; // todos, turma, serie, aluno
  final String? turmaId;
  final bool notificarResponsaveis;
  final String? cor;
  final String criadoPor;
  final DateTime criadoEm;
  final bool recorrente;
  final String? recorrencia; // diaria, semanal, mensal

  const Evento({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.inicio,
    this.fim,
    this.diaInteiro = false,
    required this.tipo,
    this.local,
    this.destinatarios = const ['todos'],
    this.turmaId,
    this.notificarResponsaveis = false,
    this.cor,
    required this.criadoPor,
    required this.criadoEm,
    this.recorrente = false,
    this.recorrencia,
  });

  factory Evento.fromJson(Map<String, dynamic> json) => Evento(
        id: json['id']?.toString() ?? '',
        titulo: json['titulo'] ?? '',
        descricao: json['descricao'],
        inicio: DateTime.parse(json['inicio']),
        fim: json['fim'] != null ? DateTime.tryParse(json['fim']) : null,
        diaInteiro: json['dia_inteiro'] ?? false,
        tipo: json['tipo'] ?? 'evento',
        local: json['local'],
        destinatarios: List<String>.from(json['destinatarios'] ?? ['todos']),
        turmaId: json['turma_id']?.toString(),
        notificarResponsaveis: json['notificar_responsaveis'] ?? false,
        cor: json['cor'],
        criadoPor: json['criado_por'] ?? '',
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'])
            : DateTime.now(),
        recorrente: json['recorrente'] ?? false,
        recorrencia: json['recorrencia'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'inicio': inicio.toIso8601String(),
        'fim': fim?.toIso8601String(),
        'dia_inteiro': diaInteiro,
        'tipo': tipo,
        'local': local,
        'destinatarios': destinatarios,
        'turma_id': turmaId,
        'notificar_responsaveis': notificarResponsaveis,
        'cor': cor,
        'recorrente': recorrente,
        'recorrencia': recorrencia,
      };
}

class Comunicado {
  final String id;
  final String titulo;
  final String corpo;
  final String tipo; // aviso, circular, urgente
  final List<String> destinatarios;
  final String? turmaId;
  final String? alunoId;
  final bool publicado;
  final DateTime? dataPublicacao;
  final String? anexoUrl;
  final String criadoPor;
  final DateTime criadoEm;
  final int? totalVisualizacoes;
  final int? totalDestinatarios;

  const Comunicado({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.tipo,
    this.destinatarios = const ['todos'],
    this.turmaId,
    this.alunoId,
    this.publicado = false,
    this.dataPublicacao,
    this.anexoUrl,
    required this.criadoPor,
    required this.criadoEm,
    this.totalVisualizacoes,
    this.totalDestinatarios,
  });

  factory Comunicado.fromJson(Map<String, dynamic> json) => Comunicado(
        id: json['id']?.toString() ?? '',
        titulo: json['titulo'] ?? '',
        corpo: json['corpo'] ?? '',
        tipo: json['tipo'] ?? 'aviso',
        destinatarios: List<String>.from(json['destinatarios'] ?? ['todos']),
        turmaId: json['turma_id']?.toString(),
        alunoId: json['aluno_id']?.toString(),
        publicado: json['publicado'] ?? false,
        dataPublicacao: json['data_publicacao'] != null
            ? DateTime.tryParse(json['data_publicacao'])
            : null,
        anexoUrl: json['anexo_url'],
        criadoPor: json['criado_por'] ?? '',
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'])
            : DateTime.now(),
        totalVisualizacoes: json['total_visualizacoes'],
        totalDestinatarios: json['total_destinatarios'],
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'corpo': corpo,
        'tipo': tipo,
        'destinatarios': destinatarios,
        'turma_id': turmaId,
        'aluno_id': alunoId,
        'publicado': publicado,
        'anexo_url': anexoUrl,
      };
}
