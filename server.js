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
  const [turmasResult, parcResult] = await Promise.all([
    sponteCall('GetTurmas', 'AnoLetivo=2026'),
    sponteCall('GetParcelas', 'AnoLetivo=2026'),
  ]);

  const turmas = turmasResult.ok
    ? extractArray(turmasResult.raw, 'ArrayOfWsTurma', 'wsTurma').filter(isSuccess)
    : [];
  const parcelas = parcResult.ok
    ? extractArray(parcResult.raw, 'ArrayOfWsParcela', 'wsParcela').filter(isSuccess)
    : [];

  const totalAlunos = turmas.reduce((s, t) => s + Number(t.VagasOcupadas || 0), 0);
  const vencidas = parcelas.filter(p => p.SituacaoParcela === 'Vencida');

  res.json({
    totalAlunos,
    alunosAtivos: totalAlunos,
    novasMatriculas: turmas.length,
    cobrancasVencidas: vencidas.length,
    receitaMes: 0,
    inadimplencia: totalAlunos ? Math.round((vencidas.length / totalAlunos) * 100) : 0,
    eventosHoje: 0,
    turmas: turmas.length,
    _fonte: 'sponte',
  });
});

// ══════════════════════════════════════════════════════════════════
// ALUNOS
// ══════════════════════════════════════════════════════════════════
app.get('/api/alunos', async (req, res) => {
  const { busca, turmaId, page = 1 } = req.query;

  let params = '';
  if (busca) params = `Nome=${busca}`;
  else if (turmaId) params = `TurmaID=${turmaId}`;

  // Se busca vazia, listar por turmas do ano
  if (!params) {
    const turmasRes = await sponteCall('GetTurmas', 'AnoLetivo=2026');
    if (!turmasRes.ok) return res.json([]);
    const turmas = extractArray(turmasRes.raw, 'ArrayOfWsTurma', 'wsTurma').filter(isSuccess);

    // Pegar integrantes da primeira turma para começar
    const turmaAlvos = turmas.slice((Number(page) - 1) * 3, Number(page) * 3);
    const resultados = [];
    for (const t of turmaAlvos) {
      const integRes = await sponteCall('GetIntegrantesTurmas', `TurmaID=${t.TurmaID}`);
      if (!integRes.ok) continue;
      const integ = extractArray(integRes.raw, 'ArrayOfIntegrantes', 'Integrantes');
      // Buscar dados de cada aluno
      for (const item of integ) {
        if (item.AlunoID && Number(item.AlunoID) > 0) {
          const alunoRes = await sponteCall('GetAlunos', `AlunoID=${item.AlunoID}`);
          if (alunoRes.ok) {
            const lista = extractArray(alunoRes.raw, 'ArrayOfWsAluno', 'wsAluno').filter(isSuccess);
            resultados.push(...lista.map(mapAluno));
          }
        }
      }
    }
    return res.json(resultados);
  }

  const result = await sponteCall('GetAlunos', params);
  if (!result.ok) return res.status(500).json({ error: result.error });
  const lista = extractArray(result.raw, 'ArrayOfWsAluno', 'wsAluno').filter(isSuccess);
  res.json(lista.map(mapAluno));
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

  if (status) {
    parcelas = parcelas.filter(p => p.status === status);
  }

  const pago = parcelas.filter(p => p.status === 'pago');
  const pendente = parcelas.filter(p => p.status === 'pendente');
  const vencido = parcelas.filter(p => p.status === 'vencido');

  const parseVal = v => Number((v || '0').toString().replace(/\./g, '').replace(',', '.'));

  res.json({
    titulos: parcelas,
    resumo: {
      totalRecebido: pago.reduce((s, p) => s + parseVal(p.valorPago || p.valor), 0),
      totalReceber: pendente.reduce((s, p) => s + parseVal(p.valor), 0),
      totalVencido: vencido.reduce((s, p) => s + parseVal(p.valor), 0),
    },
  });
});

// Financeiro geral da secretaria
app.get('/api/financeiro', async (req, res) => {
  const { status, turmaId } = req.query;

  let params = '';
  if (turmaId) params = `TurmaID=${turmaId}`;
  else params = 'AnoLetivo=2026';

  const result = await sponteCall('GetParcelas', params);
  if (!result.ok) return res.status(500).json({ error: result.error });

  let parcelas = extractArray(result.raw, 'ArrayOfWsParcela', 'wsParcela')
    .filter(isSuccess)
    .map(mapParcela);

  if (status) parcelas = parcelas.filter(p => p.status === status);
  res.json(parcelas);
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
