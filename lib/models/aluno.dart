class Aluno {
  final String id;
  final String nome;
  final String? nomeSocial;
  final String? cpf;
  final String? rg;
  final DateTime? dataNascimento;
  final String? sexo;
  final String? foto;
  final String status; // ativo, inativo, trancado
  final String? turmaId;
  final String? turma;
  final String? serie;
  final String? periodo; // manha, tarde, integral
  final String? turno;
  final String? ra;
  final String? email;
  final String? telefone;
  final String? endereco;
  final List<Responsavel> responsaveis;
  final String? observacoes;
  final DateTime? dataMatricula;
  final String? anoLetivo;
  final Map<String, dynamic>? dadosAdicionais;

  const Aluno({
    required this.id,
    required this.nome,
    this.nomeSocial,
    this.cpf,
    this.rg,
    this.dataNascimento,
    this.sexo,
    this.foto,
    required this.status,
    this.turmaId,
    this.turma,
    this.serie,
    this.periodo,
    this.turno,
    this.ra,
    this.email,
    this.telefone,
    this.endereco,
    this.responsaveis = const [],
    this.observacoes,
    this.dataMatricula,
    this.anoLetivo,
    this.dadosAdicionais,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
        id: json['id']?.toString() ?? '',
        nome: json['nome'] ?? '',
        nomeSocial: json['nome_social'],
        cpf: json['cpf'],
        rg: json['rg'],
        dataNascimento: json['data_nascimento'] != null
            ? DateTime.tryParse(json['data_nascimento'])
            : null,
        sexo: json['sexo'],
        foto: json['foto'],
        status: json['status'] ?? 'ativo',
        turmaId: json['turma_id']?.toString(),
        turma: json['turma'],
        serie: json['serie'],
        periodo: json['periodo'],
        turno: json['turno'],
        ra: json['ra'],
        email: json['email'],
        telefone: json['telefone'],
        endereco: json['endereco'],
        responsaveis: (json['responsaveis'] as List<dynamic>?)
                ?.map((r) => Responsavel.fromJson(r))
                .toList() ??
            [],
        observacoes: json['observacoes'],
        dataMatricula: json['data_matricula'] != null
            ? DateTime.tryParse(json['data_matricula'])
            : null,
        anoLetivo: json['ano_letivo'],
        dadosAdicionais: json['dados_adicionais'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'nome_social': nomeSocial,
        'cpf': cpf,
        'rg': rg,
        'data_nascimento': dataNascimento?.toIso8601String(),
        'sexo': sexo,
        'foto': foto,
        'status': status,
        'turma_id': turmaId,
        'turma': turma,
        'serie': serie,
        'periodo': periodo,
        'turno': turno,
        'ra': ra,
        'email': email,
        'telefone': telefone,
        'endereco': endereco,
        'responsaveis': responsaveis.map((r) => r.toJson()).toList(),
        'observacoes': observacoes,
        'data_matricula': dataMatricula?.toIso8601String(),
        'ano_letivo': anoLetivo,
      };

  String get nomeExibicao => nomeSocial?.isNotEmpty == true ? nomeSocial! : nome;

  int? get idade {
    if (dataNascimento == null) return null;
    final now = DateTime.now();
    int age = now.year - dataNascimento!.year;
    if (now.month < dataNascimento!.month ||
        (now.month == dataNascimento!.month && now.day < dataNascimento!.day)) {
      age--;
    }
    return age;
  }
}

class Responsavel {
  final String id;
  final String nome;
  final String? cpf;
  final String? rg;
  final String parentesco;
  final String? email;
  final String telefone;
  final String? celular;
  final bool financeiro;
  final bool pedagocico;
  final bool autorizado;

  const Responsavel({
    required this.id,
    required this.nome,
    this.cpf,
    this.rg,
    required this.parentesco,
    this.email,
    required this.telefone,
    this.celular,
    this.financeiro = false,
    this.pedagocico = false,
    this.autorizado = true,
  });

  factory Responsavel.fromJson(Map<String, dynamic> json) => Responsavel(
        id: json['id']?.toString() ?? '',
        nome: json['nome'] ?? '',
        cpf: json['cpf'],
        rg: json['rg'],
        parentesco: json['parentesco'] ?? '',
        email: json['email'],
        telefone: json['telefone'] ?? '',
        celular: json['celular'],
        financeiro: json['financeiro'] ?? false,
        pedagocico: json['pedagogico'] ?? false,
        autorizado: json['autorizado'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'cpf': cpf,
        'rg': rg,
        'parentesco': parentesco,
        'email': email,
        'telefone': telefone,
        'celular': celular,
        'financeiro': financeiro,
        'pedagogico': pedagocico,
        'autorizado': autorizado,
      };
}
