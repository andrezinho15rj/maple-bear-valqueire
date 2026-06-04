class Usuario {
  final String id;
  final String nome;
  final String email;
  final String cargo;
  final String? foto;
  final List<String> permissoes;
  final bool ativo;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.cargo,
    this.foto,
    required this.permissoes,
    required this.ativo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id']?.toString() ?? '',
        nome: json['nome'] ?? '',
        email: json['email'] ?? '',
        cargo: json['cargo'] ?? 'Secretaria',
        foto: json['foto'],
        permissoes: List<String>.from(json['permissoes'] ?? []),
        ativo: json['ativo'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'cargo': cargo,
        'foto': foto,
        'permissoes': permissoes,
        'ativo': ativo,
      };

  bool temPermissao(String modulo) =>
      permissoes.contains('*') || permissoes.contains(modulo);
}
