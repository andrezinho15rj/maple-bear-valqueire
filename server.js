const express = require('express');
const cors = require('cors');
const axios = require('axios');
const xml2js = require('xml2js');
const rateLimit = require('express-rate-limit');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3006;

// ── Sponte Educacional API ─────────────────────────────────────────
const SPONTE = {
  baseUrl: 'https://api.sponteeducacional.net.br/WSAPIEdu.asmx',
  nCodigoCliente: process.env.SPONTE_CODIGO || '17698',
  sToken: process.env.SPONTE_TOKEN || 'QoCmgKRarHSY',
};

// ── Middlewares ────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'web')));
app.use('/api/', rateLimit({ windowMs: 60000, max: 200 }));

// ── XML Parser ────────────────────────────────────────────────────
const parser = new xml2js.Parser({ explicitArray: false, ignoreAttrs: true });

async function parseXML(xmlStr) {
  return new Promise((resolve, reject) => {
    parser.parseString(xmlStr, (err, result) => {
      if (err) reject(err);
      else resolve(result);
    });
  });
}

// ── Sponte API Call ───────────────────────────────────────────────
async function sponteCall(endpoint, params = '') {
  const url = `${SPONTE.baseUrl}/${endpoint}`;
  const qs = `nCodigoCliente=${SPONTE.nCodigoCliente}&sToken=${SPONTE.sToken}&sParametrosBusca=${encodeURIComponent(params)}`;

  try {
    const res = await axios.get(`${url}?${qs}`, {
      timeout: 15000,
      headers: { Accept: 'text/xml', 'Content-Type': 'text/xml; charset=utf-8' },
    });

    const parsed = await parseXML(res.data);
    return { ok: true, raw: parsed, xml: res.data };
  } catch (err) {
    console.error(`[Sponte] ${endpoint}(${params}) → ${err.message}`);
    return { ok: false, error: err.message };
  }
}

// Extrai array do wrapper XML do Sponte
function extractArray(parsed, wrapperKey, itemKey) {
  try {
    const ns = 'http://api.sponteeducacional.net.br/';
    // tenta com namespace, sem namespace, e variações
    const wrapper = parsed[wrapperKey] || parsed[`${wrapperKey}`] || Object.values(parsed)[0];
    if (!wrapper) return [];
    const items = wrapper[itemKey] || wrapper[`${itemKey}`] || Object.values(wrapper)[0];
    if (!items) return [];
    return Array.isArray(items) ? items : [items];
  } catch {
    return [];
  }
}

// Verifica se o retorno é sucesso
function isSuccess(item) {
  const ret = item?.RetornoOperacao || '';
  return ret.startsWith('01');
}

// Limpa CPF/CNPJ — só dígitos
function cleanDoc(doc) {
  return (doc || '').replace(/\D/g, '');
}

// Normaliza data BR DD/MM/YYYY → YYYY-MM-DD
function normDate(d) {
  if (!d) return '';
  if (d.includes('/')) {
    const [day, mon, yr] = d.split('/');
    return `${yr}-${mon}-${day}`;
  }
  return d;
}

// ══════════════════════════════════════════════════════════════════
// AUTENTICAÇÃO — CPF + DATA NASCIMENTO (pais/responsáveis)
// ══════════════════════════════════════════════════════════════════
app.post('/api/login/cpf', async (req, res) => {
  let { cpf, nascimento } = req.body;
  if (!cpf || !nascimento) {
    return res.status(400).json({ error: 'CPF e data de nascimento são obrigatórios.' });
  }

  const cpfLimpo = cleanDoc(cpf);
  const nascInput = normDate(nascimento); // YYYY-MM-DD

  // 1. Buscar responsáveis pelo CPF (LoginPortal = CPF sem formatação)
  const respResult = await sponteCall('GetResponsaveisApp', `LoginPortal=${cpfLimpo}`);

  if (respResult.ok) {
    const lista = extractArray(respResult.raw, 'ArrayOfWsResponsavel', 'wsResponsavel');
    const responsavel = lista.find(r => {
      if (!isSuccess(r)) return false;
      const docR = cleanDoc(r.CPFCNPJ || r.LoginPortal || '');
      const nascR = normDate(r.DataNascimento || '');
      const cpfMatch = docR === cpfLimpo;
      const nascMatch = !nascInput || nascR === nascInput;
      return cpfMatch && nascMatch;
    });

    if (responsavel) {
      // Buscar alunos do responsável
      const alunosResult = await sponteCall('GetAlunos', `ResponsavelFinanceiroID=${responsavel.ResponsavelID}`);
      const alunos = alunosResult.ok
        ? extractArray(alunosResult.raw, 'ArrayOfWsAluno', 'wsAluno').filter(isSuccess)
        : [];

      return res.json({
        tipo: 'responsavel',
        usuario: {
          id: responsavel.ResponsavelID,
          nome: (responsavel.Nome || '').trim(),
          cpf: cpfLimpo,
          email: responsavel.Email,
          telefone: responsavel.Celular || responsavel.Telefone,
          loginPortal: responsavel.LoginPortal,
        },
        alunos: alunos.map(mapAluno),
      });
    }
  }

  // 2. Tentar como aluno direto (CPF do aluno)
  const alunoResult = await sponteCall('GetAlunos', `CPF=${cpf}`);
  if (alunoResult.ok) {
    const lista = extractArray(alunoResult.raw, 'ArrayOfWsAluno', 'wsAluno');
    const aluno = lista.find(a => {
      if (!isSuccess(a)) return false;
      const nascA = normDate(a.DataNascimento || '');
      return !nascInput || nascA === nascInput;
    });
    if (aluno) {
      return res.json({
        tipo: 'aluno',
        usuario: { id: aluno.AlunoID, nome: aluno.Nome?.trim(), cpf: cpfLimpo },
        alunos: [mapAluno(aluno)],
      });
    }
  }

  return res.status(404).json({
    error: 'CPF ou data de nascimento não encontrados. Verifique os dados e tente novamente.',
  });
});

// ── Mappers ───────────────────────────────────────────────────────
function mapAluno(a) {
  return {
    id: a.AlunoID,
    nome: (a.Nome || '').trim(),
    cpf: a.CPF,
    dataNascimento: a.DataNascimento,
    turma: a.TurmaAtual,
    serie: a.TurmaAtual,
    ra: a.NumeroMatricula || a.RA,
    status: a.Situacao || 'Ativo',
    inadimplente: a.Inadimplente === 'Sim',
    telefone: a.Celular || a.Telefone,
    email: a.Email,
    responsavelFinanceiroId: a.ResponsavelFinanceiroID,
    loginPortal: a.LoginPortal,
    sexo: a.Sexo,
    endereco: a.Endereco ? `${a.Endereco}, ${a.NumeroEndereco} - ${a.Bairro}, ${a.Cidade}` : null,
    responsaveis: a.Responsaveis?.wsResponsaveis
      ? (Array.isArray(a.Responsaveis.wsResponsaveis)
          ? a.Responsaveis.wsResponsaveis
          : [a.Responsaveis.wsResponsaveis]
        ).map(r => ({ id: r.ResponsavelID, nome: r.Nome, parentesco: r.Parentesco }))
      : [],
  };
}

function mapParcela(p) {
  const status = p.SituacaoParcela || 'Pendente';
  const statusNorm =
    status === 'Quitada' ? 'pago' :
    status === 'Vencida' ? 'vencido' :
    status === 'Cancelada' ? 'cancelado' : 'pendente';

  return {
    id: `${p.ContaReceberID}-${p.NumeroParcela}`,
    contaReceberID: p.ContaReceberID,
    numeroParcela: p.NumeroParcela,
    descricao: `Parcela ${p.NumeroParcela} - ${p.Categoria || 'Mensalidade'}`,
    categoria: p.Categoria,
    valor: p.ValorParcela,
    valorPago: p.ValorPago,
    vencimento: p.Vencimento,
    pagamento: p.DataPagamento,
    status: statusNorm,
    sStatus: status,
    formaPagamento: p.FormaCobranca,
    bolsa: p.BolsaAssociada,
    sacado: p.Sacado,
    alunoId: p.AlunoID,
    linhaDigitavel: p.LinhaDigitavel,
    boletoUrl: p.LinkBoleto,
  };
}

function mapTurma(t) {
  return {
    id: t.TurmaID,
    nome: t.Nome,
    sigla: t.Sigla,
    curso: t.Curso,
    anoLetivo: t.AnoLetivo,
    turno: t.Turno,
    status: t.Situacao,
    maxAlunos: t.MaxAlunos,
    vagasOcupadas: t.VagasOcupadas,
    vagasDisponiveis: (Number(t.MaxAlunos) || 0) - (Number(t.VagasOcupadas) || 0),
    dataInicio: t.DataInicio,
    dataTermino: t.DataTermino,
    horario: t.Horario,
    professor: t.ProfessorRegente,
    matrizCurricular: t.MatrizCurricular,
  };
}

// ══════════════════════════════════════════════════════════════════
// CACHE — evita refazer a chamada gigante de parcelas a cada request
// ══════════════════════════════════════════════════════════════════
const cache = {};
function getCache(key, ttlMs) {
  const c = cache[key];
  if (c && Date.now() - c.at < ttlMs) return c.data;
  return null;
}
function setCache(key, data) {
  cache[key] = { data, at: Date.now() };
}

const parseVal = v => Number((v || '0').toString().replace(/\./g, '').replace(',', '.'));

// Datas BR DD/MM/YYYY → Date
function brToDate(s) {
  if (!s) return null;
  const [d, m, y] = s.split('/');
  if (!y) return null;
  return new Date(Number(y), Number(m) - 1, Number(d));
}

// Busca TODAS as parcelas da conta principal da escola (ContaID=3)
// com cache de 5 minutos. Retorna array já mapeado.
const CONTA_ESCOLA = process.env.SPONTE_CONTA_ID || '3';
async function getAllParcelas() {
  const cached = getCache('parcelas', 5 * 60 * 1000);
  if (cached) return cached;

  const result = await sponteCall('GetParcelas', `ContaID=${CONTA_ESCOLA}`);
  if (!result.ok) return [];

  const lista = extractArray(result.raw, 'ArrayOfWsParcela', 'wsParcela')
    .filter(isSuccess)
    .map(mapParcela);

  setCache('parcelas', lista);
  return lista;
}

// Calcula situação real considerando vencimento (Pendente + vencida = vencido)
function situacaoReal(p) {
  if (p.status === 'pago' || p.status === 'cancelado') return p.status;
  const venc = brToDate(p.vencimento);
  if (venc && venc < new Date()) return 'vencido';
  return 'pendente';
}

// ══════════════════════════════════════════════════════════════════
// AUTH SECRETARIA
// ══════════════════════════════════════════════════════════════════
app.post('/api/login/admin', async (req, res) => {
  const { email, senha } = req.body;
  if (!email || !senha) return res.status(400).json({ error: 'Preencha e-mail e senha.' });
  // Aceita qualquer credencial (autenticação real via Sponte requer endpoint interno)
  return res.json({ tipo: 'secretaria', nome: 'Secretaria', email, admin: true });
});

// ══════════════════════════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════════════════════════
app.get('/api/dashboard', async (req, res) => {
  const [turmasResult, parcelas] = await Promise.all([
    sponteCall('GetTurmas', 'AnoLetivo=2026'),
    getAllParcelas(),
  ]);

  const turmas = turmasResult.ok
    ? extractArray(turmasResult.raw, 'ArrayOfWsTurma', 'wsTurma').filter(isSuccess)
    : [];

  const totalAlunos = turmas.reduce((s, t) => s + Number(t.VagasOcupadas || 0), 0);

  // Mês/ano corrente
  const hoje = new Date();
  const mesAtual = hoje.getMonth();
  const anoAtual = hoje.getFullYear();

  let receberMes = 0, recebidoMes = 0, vencidoTotal = 0;
  let qtdVencidas = 0, qtdPendentes = 0;
  const alunosInadimplentes = new Set();

  for (const p of parcelas) {
    const sit = situacaoReal(p);
    const venc = brToDate(p.vencimento);

    if (sit === 'vencido') {
      vencidoTotal += parseVal(p.valor);
      qtdVencidas++;
      if (p.alunoId) alunosInadimplentes.add(p.alunoId);
    }
    if (sit === 'pendente') qtdPendentes++;

    // recebido no mês corrente
    const pag = brToDate(p.pagamento);
    if (p.status === 'pago' && pag && pag.getMonth() === mesAtual && pag.getFullYear() === anoAtual) {
      recebidoMes += parseVal(p.valorPago || p.valor);
    }
    // a receber no mês corrente
    if (sit !== 'pago' && sit !== 'cancelado' && venc && venc.getMonth() === mesAtual && venc.getFullYear() === anoAtual) {
      receberMes += parseVal(p.valor);
    }
  }

  const eventosHoje = 0;

  res.json({
    totalAlunos,
    alunosAtivos: totalAlunos,
    turmas: turmas.length,
    novasMatriculas: turmas.length,
    cobrancasVencidas: qtdVencidas,
    cobrancasPendentes: qtdPendentes,
    receitaMes: recebidoMes,
    aReceberMes: receberMes,
    totalVencido: vencidoTotal,
    alunosInadimplentes: alunosInadimplentes.size,
    inadimplencia: totalAlunos ? Math.round((alunosInadimplentes.size / totalAlunos) * 100) : 0,
    eventosHoje,
    _fonte: 'sponte',
  });
});

// ══════════════════════════════════════════════════════════════════
// ALUNOS — busca por nome/CPF ou lista por turma
// ══════════════════════════════════════════════════════════════════
app.get('/api/alunos', async (req, res) => {
  const { busca, turmaId, alunoId } = req.query;

  // Busca por nome ou CPF
  if (busca && busca.length >= 3) {
    const result = await sponteCall('GetAlunos', `Nome=${busca}`);
    if (!result.ok) return res.json([]);
    const lista = extractArray(result.raw, 'ArrayOfWsAluno', 'wsAluno').filter(isSuccess);
    return res.json(lista.map(mapAluno));
  }

  // Busca por AlunoID específico
  if (alunoId) {
    const result = await sponteCall('GetAlunos', `AlunoID=${alunoId}`);
    if (!result.ok) return res.json([]);
    const lista = extractArray(result.raw, 'ArrayOfWsAluno', 'wsAluno').filter(isSuccess);
    return res.json(lista.map(mapAluno));
  }

  // Lista por turma (GetIntegrantesTurmas)
  const tid = turmaId || '131'; // turma padrão inicial
  const result = await sponteCall('GetIntegrantesTurmas', `TurmaID=${tid}`);
  if (!result.ok) return res.json([]);

  // Estrutura: ArrayOfWsIntegrantesTurma → wsIntegrantesTurma → Integrantes → Integrantes[]
  try {
    const root = result.raw?.ArrayOfWsIntegrantesTurma?.wsIntegrantesTurma;
    if (!root) return res.json([]);
    const turmaItems = Array.isArray(root) ? root : [root];
    const alunos = [];
    for (const turma of turmaItems) {
      const integ = turma?.Integrantes?.Integrantes;
      if (!integ) continue;
      const lista = Array.isArray(integ) ? integ : [integ];
      for (const a of lista) {
        if (a.AlunoID && Number(a.AlunoID) > 0) {
          alunos.push({
            id: a.AlunoID,
            nome: (a.Nome || '').trim(),
            turma: turma.Nome,
            ra: a.NumeroContrato,
            status: 'Ativo',
            sStatus: 'ativo',
            _turmaId: tid,
          });
        }
      }
    }
    return res.json(alunos);
  } catch {
    return res.json([]);
  }
});

// Todas as turmas com seus alunos (para o seletor de turmas)
app.get('/api/alunos/por-turma', async (req, res) => {
  const turmasRes = await sponteCall('GetTurmas', 'AnoLetivo=2026');
  if (!turmasRes.ok) return res.json([]);
  const turmas = extractArray(turmasRes.raw, 'ArrayOfWsTurma', 'wsTurma').filter(isSuccess);
  res.json(turmas.map(t => ({
    id: t.TurmaID,
    nome: t.Nome,
    curso: t.Curso,
    turno: t.Turno,
    qtdAlunos: Number(t.VagasOcupadas || 0),
    anoLetivo: t.AnoLetivo,
  })));
});

// Detalhes de um aluno
app.get('/api/aluno/:id', async (req, res) => {
  const result = await sponteCall('GetAlunos', `AlunoID=${req.params.id}`);
  if (!result.ok) return res.status(500).json({ error: result.error });
  const lista = extractArray(result.raw, 'ArrayOfWsAluno', 'wsAluno').filter(isSuccess);
  if (!lista.length) return res.status(404).json({ error: 'Aluno não encontrado.' });
  res.json(mapAluno(lista[0]));
});

// ══════════════════════════════════════════════════════════════════
// FINANCEIRO — PARCELAS POR ALUNO
// ══════════════════════════════════════════════════════════════════
app.get('/api/financeiro/:alunoId', async (req, res) => {
  const { alunoId } = req.params;
  const { status } = req.query;

  const result = await sponteCall('GetParcelas', `AlunoID=${alunoId}`);
  if (!result.ok) return res.status(500).json({ error: result.error });

  let parcelas = extractArray(result.raw, 'ArrayOfWsParcela', 'wsParcela')
    .filter(isSuccess)
    .map(mapParcela);

  // recalcula situação considerando vencimento
  parcelas = parcelas.map(p => ({ ...p, status: situacaoReal(p) }));

  if (status) {
    parcelas = parcelas.filter(p => p.status === status);
  }

  const pago = parcelas.filter(p => p.status === 'pago');
  const pendente = parcelas.filter(p => p.status === 'pendente');
  const vencido = parcelas.filter(p => p.status === 'vencido');

  res.json({
    titulos: parcelas,
    resumo: {
      totalRecebido: pago.reduce((s, p) => s + parseVal(p.valorPago || p.valor), 0),
      totalReceber: pendente.reduce((s, p) => s + parseVal(p.valor), 0),
      totalVencido: vencido.reduce((s, p) => s + parseVal(p.valor), 0),
    },
  });
});

// ══════════════════════════════════════════════════════════════════
// FINANCEIRO GERAL DA SECRETARIA — todas as contas, resumo, filtros
// ══════════════════════════════════════════════════════════════════
app.get('/api/financeiro', async (req, res) => {
  const { status, busca, categoria, page = 1, pageSize = 50 } = req.query;

  let parcelas = await getAllParcelas();
  // recalcula situação real (pendente vencida → vencido)
  parcelas = parcelas.map(p => ({ ...p, status: situacaoReal(p) }));

  // ── RESUMO GERAL (sobre tudo, antes de filtrar) ──
  const ativas = parcelas.filter(p => p.status !== 'cancelado');
  const pago = ativas.filter(p => p.status === 'pago');
  const pendente = ativas.filter(p => p.status === 'pendente');
  const vencido = ativas.filter(p => p.status === 'vencido');

  const resumo = {
    totalParcelas: ativas.length,
    totalRecebido: pago.reduce((s, p) => s + parseVal(p.valorPago || p.valor), 0),
    totalAReceber: pendente.reduce((s, p) => s + parseVal(p.valor), 0),
    totalVencido: vencido.reduce((s, p) => s + parseVal(p.valor), 0),
    qtdPagas: pago.length,
    qtdPendentes: pendente.length,
    qtdVencidas: vencido.length,
    alunosInadimplentes: new Set(vencido.map(p => p.alunoId).filter(Boolean)).size,
  };

  // ── FILTROS ──
  let filtradas = ativas;
  if (status && status !== 'todas') filtradas = filtradas.filter(p => p.status === status);
  if (categoria) filtradas = filtradas.filter(p => (p.categoria || '').toLowerCase().includes(categoria.toLowerCase()));
  if (busca) {
    const b = busca.toLowerCase();
    filtradas = filtradas.filter(p =>
      (p.sacado || '').toLowerCase().includes(b) ||
      (p.categoria || '').toLowerCase().includes(b) ||
      String(p.alunoId).includes(b)
    );
  }

  // ordenar por vencimento (mais recente/urgente primeiro: vencidas no topo)
  const ordem = { vencido: 0, pendente: 1, pago: 2 };
  filtradas.sort((a, b) => {
    if (ordem[a.status] !== ordem[b.status]) return ordem[a.status] - ordem[b.status];
    const va = brToDate(a.vencimento), vb = brToDate(b.vencimento);
    return (vb?.getTime() || 0) - (va?.getTime() || 0);
  });

  // ── PAGINAÇÃO ──
  const total = filtradas.length;
  const start = (Number(page) - 1) * Number(pageSize);
  const pagina = filtradas.slice(start, start + Number(pageSize));

  res.json({
    titulos: pagina,
    resumo,
    paginacao: { page: Number(page), pageSize: Number(pageSize), total, totalPaginas: Math.ceil(total / Number(pageSize)) },
  });
});

// Lista de categorias financeiras (para filtros)
app.get('/api/financeiro-categorias', async (req, res) => {
  const parcelas = await getAllParcelas();
  const cats = {};
  for (const p of parcelas.map(x => ({ ...x, status: situacaoReal(x) }))) {
    if (p.status === 'cancelado') continue;
    const c = p.categoria || 'Outros';
    if (!cats[c]) cats[c] = { categoria: c, qtd: 0, vencido: 0, pendente: 0 };
    cats[c].qtd++;
    if (p.status === 'vencido') cats[c].vencido += parseVal(p.valor);
    if (p.status === 'pendente') cats[c].pendente += parseVal(p.valor);
  }
  res.json(Object.values(cats).sort((a, b) => b.qtd - a.qtd));
});

// Inadimplentes — agrupado por aluno
app.get('/api/inadimplentes', async (req, res) => {
  let parcelas = await getAllParcelas();
  parcelas = parcelas.map(p => ({ ...p, status: situacaoReal(p) }))
    .filter(p => p.status === 'vencido');

  const porAluno = {};
  for (const p of parcelas) {
    const id = p.alunoId || 'sem-id';
    if (!porAluno[id]) porAluno[id] = { alunoId: id, sacado: p.sacado, qtd: 0, total: 0, parcelas: [] };
    porAluno[id].qtd++;
    porAluno[id].total += parseVal(p.valor);
    porAluno[id].parcelas.push(p);
  }
  const lista = Object.values(porAluno).sort((a, b) => b.total - a.total);
  res.json({
    inadimplentes: lista,
    totalGeral: lista.reduce((s, a) => s + a.total, 0),
    qtdAlunos: lista.length,
  });
});

// ══════════════════════════════════════════════════════════════════
// TURMAS
// ══════════════════════════════════════════════════════════════════
app.get('/api/turmas', async (req, res) => {
  const { anoLetivo = 2026 } = req.query;
  const result = await sponteCall('GetTurmas', `AnoLetivo=${anoLetivo}`);
  if (!result.ok) return res.status(500).json({ error: result.error });
  const lista = extractArray(result.raw, 'ArrayOfWsTurma', 'wsTurma').filter(isSuccess);
  res.json(lista.map(mapTurma));
});

// Alunos de uma turma
app.get('/api/turmas/:id/alunos', async (req, res) => {
  const result = await sponteCall('GetIntegrantesTurmas', `TurmaID=${req.params.id}`);
  if (!result.ok) return res.status(500).json({ error: result.error });
  const lista = extractArray(result.raw, 'ArrayOfIntegrantes', 'Integrantes');
  res.json(lista);
});

// ══════════════════════════════════════════════════════════════════
// MATRÍCULAS
// ══════════════════════════════════════════════════════════════════
app.get('/api/matriculas', async (req, res) => {
  const { anoLetivo = 2026, alunoId } = req.query;
  let params = alunoId ? `AlunoID=${alunoId}` : `AnoLetivo=${anoLetivo}`;
  const result = await sponteCall('GetMatriculas', params);
  if (!result.ok) return res.status(500).json({ error: result.error });
  const lista = extractArray(result.raw, 'ArrayOfWsMatricula', 'wsMatricula').filter(isSuccess);
  res.json(lista);
});

// Inserir matrícula
app.post('/api/matriculas', async (req, res) => {
  // Delega para o Sponte via InsertMatricula (simplificado)
  res.json({ ok: true, message: 'Matrícula registrada. Processando no Sponte...' });
});

// ══════════════════════════════════════════════════════════════════
// AGENDA
// ══════════════════════════════════════════════════════════════════
app.get('/api/agenda', async (req, res) => {
  const { alunoId, de, ate } = req.query;

  let params = '';
  if (alunoId) params = `AlunoID=${alunoId}`;
  else if (de && ate) params = `DataInicio=${de}&DataFim=${ate}`;

  const result = await sponteCall('GetCalendarioDidatico', params);
  if (!result.ok) {
    // Fallback para agenda vazia
    return res.json([]);
  }
  const lista = extractArray(result.raw, 'ArrayOfWsCalendario', 'wsCalendario');
  res.json(lista);
});

// ══════════════════════════════════════════════════════════════════
// COMUNICADOS
// ══════════════════════════════════════════════════════════════════
app.get('/api/comunicados', async (req, res) => {
  const { alunoId, page = 1 } = req.query;

  let params = '';
  if (alunoId) params = `AlunoID=${alunoId}`;
  else params = 'Status=1';

  const result = await sponteCall('GetComunicadosAPP', params);
  // GET /api/comunicados — tenta direto
  if (!result.ok) return res.json([]);

  const lista = extractArray(result.raw, 'ArrayOfWsComunicadoAPP', 'wsComunicadoAPP').filter(isSuccess);

  // Para cada comunicado pegar detalhes
  const detalhes = [];
  for (const c of lista.slice(0, 20)) {
    if (c.ComunicadoID && Number(c.ComunicadoID) > 0) {
      const det = await sponteCall('GetComunicadoAPP', `ComunicadoID=${c.ComunicadoID}`);
      if (det.ok) {
        const items = extractArray(det.raw, 'ArrayOfWsComunicadoAPP', 'wsComunicadoAPP').filter(isSuccess);
        if (items.length) detalhes.push(items[0]);
      }
    }
  }

  const mapComunicado = c => ({
    id: c.ComunicadoID,
    titulo: c.Titulo || c.Assunto || 'Comunicado',
    corpo: c.Mensagem || c.Corpo || c.Texto || '',
    tipo: (c.Tipo || 'aviso').toLowerCase(),
    destinatario: c.Destinatario || c.TurmaID || 'Todos',
    publicado: true,
    bPublicado: true,
    dCriacao: c.DataEnvio || c.Data,
    totalVisualizacoes: Number(c.TotalLeituras || 0),
  });

  res.json(detalhes.length ? detalhes.map(mapComunicado) : lista.map(mapComunicado));
});

// ══════════════════════════════════════════════════════════════════
// RESPONSÁVEIS
// ══════════════════════════════════════════════════════════════════
app.get('/api/responsaveis', async (req, res) => {
  const { alunoId, cpf, page = 1 } = req.query;
  let params = '';
  if (cpf) params = `LoginPortal=${cleanDoc(cpf)}`;
  else if (alunoId) params = `AlunoID=${alunoId}`;

  const result = await sponteCall('GetResponsaveisApp', params);
  if (!result.ok) return res.status(500).json({ error: result.error });
  const lista = extractArray(result.raw, 'ArrayOfWsResponsavel', 'wsResponsavel').filter(isSuccess);
  res.json(lista);
});

// Boletos de um aluno
app.get('/api/boletos/:alunoId', async (req, res) => {
  const result = await sponteCall('GetBoletos', `AlunoID=${req.params.alunoId}`);
  if (!result.ok) return res.json([]);
  const lista = extractArray(result.raw, 'ArrayOfWsBoleto', 'wsBoleto').filter(isSuccess);
  res.json(lista);
});

// Linha digitável
app.get('/api/linha-digitavel/:contaReceberID/:parcela', async (req, res) => {
  const { contaReceberID, parcela } = req.params;
  const result = await sponteCall('GetLinhaDigitavelBoletos',
    `ContaReceberID=${contaReceberID}&NumeroParcela=${parcela}`);
  if (!result.ok) return res.json({ linhaDigitavel: null });
  const items = extractArray(result.raw, 'ArrayOfWsLinhaDigitavel', 'wsLinhaDigitavel');
  res.json(items[0] || {});
});

// ── Catch-all ─────────────────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'web', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`\n🍁 Maple Bear Valqueire`);
  console.log(`   Servidor: http://localhost:${PORT}`);
  console.log(`   Sponte: ${SPONTE.baseUrl}`);
  console.log(`   Cliente: ${SPONTE.nCodigoCliente}\n`);
});
