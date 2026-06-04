class Cobranca {
  final String id;
  final String alunoId;
  final String alunoNome;
  final String descricao;
  final double valor;
  final double? desconto;
  final double? multa;
  final double? juros;
  final double valorFinal;
  final DateTime vencimento;
  final DateTime? pagamento;
  final String status; // pendente, pago, vencido, cancelado, negociado
  final String? formaPagamento;
  final String? boletoUrl;
  final String? boletoLinhaDigitavel;
  final String? observacoes;
  final String? competencia;
  final String tipo; // mensalidade, material, uniforme, excursao, outro
  final String? nossoNumero;

  const Cobranca({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.descricao,
    required this.valor,
    this.desconto,
    this.multa,
    this.juros,
    required this.valorFinal,
    required this.vencimento,
    this.pagamento,
    required this.status,
    this.formaPagamento,
    this.boletoUrl,
    this.boletoLinhaDigitavel,
    this.observacoes,
    this.competencia,
    required this.tipo,
    this.nossoNumero,
  });

  factory Cobranca.fromJson(Map<String, dynamic> json) => Cobranca(
        id: json['id']?.toString() ?? '',
        alunoId: json['aluno_id']?.toString() ?? '',
        alunoNome: json['aluno_nome'] ?? '',
        descricao: json['descricao'] ?? '',
        valor: (json['valor'] ?? 0).toDouble(),
        desconto: json['desconto']?.toDouble(),
        multa: json['multa']?.toDouble(),
        juros: json['juros']?.toDouble(),
        valorFinal: (json['valor_final'] ?? json['valor'] ?? 0).toDouble(),
        vencimento: DateTime.parse(json['vencimento']),
        pagamento: json['pagamento'] != null
            ? DateTime.tryParse(json['pagamento'])
            : null,
        status: json['status'] ?? 'pendente',
        formaPagamento: json['forma_pagamento'],
        boletoUrl: json['boleto_url'],
        boletoLinhaDigitavel: json['boleto_linha_digitavel'],
        observacoes: json['observacoes'],
        competencia: json['competencia'],
        tipo: json['tipo'] ?? 'mensalidade',
        nossoNumero: json['nosso_numero'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'aluno_id': alunoId,
        'aluno_nome': alunoNome,
        'descricao': descricao,
        'valor': valor,
        'desconto': desconto,
        'multa': multa,
        'juros': juros,
        'valor_final': valorFinal,
        'vencimento': vencimento.toIso8601String(),
        'pagamento': pagamento?.toIso8601String(),
        'status': status,
        'forma_pagamento': formaPagamento,
        'observacoes': observacoes,
        'competencia': competencia,
        'tipo': tipo,
      };

  bool get isVencida =>
      status == 'pendente' && vencimento.isBefore(DateTime.now());
  bool get isPago => status == 'pago';
  bool get isPendente => status == 'pendente' && !isVencida;

  int get diasAtraso {
    if (!isVencida) return 0;
    return DateTime.now().difference(vencimento).inDays;
  }
}

class ResumoFinanceiro {
  final double totalReceber;
  final double totalRecebido;
  final double totalVencido;
  final int qtdPendentes;
  final int qtdPagas;
  final int qtdVencidas;
  final double inadimplenciaPercentual;

  const ResumoFinanceiro({
    required this.totalReceber,
    required this.totalRecebido,
    required this.totalVencido,
    required this.qtdPendentes,
    required this.qtdPagas,
    required this.qtdVencidas,
    required this.inadimplenciaPercentual,
  });

  factory ResumoFinanceiro.fromJson(Map<String, dynamic> json) =>
      ResumoFinanceiro(
        totalReceber: (json['total_receber'] ?? 0).toDouble(),
        totalRecebido: (json['total_recebido'] ?? 0).toDouble(),
        totalVencido: (json['total_vencido'] ?? 0).toDouble(),
        qtdPendentes: json['qtd_pendentes'] ?? 0,
        qtdPagas: json['qtd_pagas'] ?? 0,
        qtdVencidas: json['qtd_vencidas'] ?? 0,
        inadimplenciaPercentual:
            (json['inadimplencia_percentual'] ?? 0).toDouble(),
      );
}

class BaixaManual {
  final String cobrancaId;
  final DateTime dataPagamento;
  final double valorPago;
  final String formaPagamento;
  final String? observacoes;

  const BaixaManual({
    required this.cobrancaId,
    required this.dataPagamento,
    required this.valorPago,
    required this.formaPagamento,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'cobranca_id': cobrancaId,
        'data_pagamento': dataPagamento.toIso8601String(),
        'valor_pago': valorPago,
        'forma_pagamento': formaPagamento,
        'observacoes': observacoes,
      };
}
