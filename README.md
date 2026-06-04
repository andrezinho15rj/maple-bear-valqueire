# 🍁 Maple Bear Valqueire — Portal da Secretaria

Sistema de gestão escolar integrado com **Sponte Educacional**, desenvolvido para uso da secretaria e das famílias da Maple Bear Valqueire.

Funciona como **Web App**, **Android** e **iOS** (via Flutter).

---

## Funcionalidades

### Para Pais / Responsáveis
| Módulo | Descrição |
|---|---|
| **Acesso por CPF** | Login com CPF + data de nascimento — sem senha para memorizar |
| **Financeiro** | Visualiza todas as parcelas, status (pago/pendente/vencido), valor com bolsa |
| **Eventos** | Calendário escolar e próximos eventos |
| **Comunicados** | Avisos, circulares e comunicados urgentes da escola |

### Para a Secretaria
| Módulo | Descrição |
|---|---|
| **Dashboard** | KPIs em tempo real: alunos ativos, cobranças vencidas, turmas |
| **Alunos** | Listagem completa, busca, detalhes, responsáveis |
| **Financeiro** | Parcelas por status, filtros, baixa manual, geração de boleto |
| **Matrículas** | Nova matrícula, renovação, documentação pendente |
| **Agenda** | Calendário mensal, criação de eventos |
| **Comunicados** | Envio de comunicados para turmas ou toda a escola |
| **Relatórios** | Inadimplência, receita, alunos por série |

---

## Tecnologia

### Backend (Node.js)
- **Express** — servidor HTTP
- **xml2js** — parser da API SOAP do Sponte
- **axios** — chamadas HTTP para o Sponte
- **express-rate-limit** — proteção contra abuso

### Frontend (Web)
- HTML5 / CSS3 / JavaScript puro
- Design responsivo (desktop + mobile)
- PWA ready (funciona offline após primeiro acesso)

### App Mobile (Flutter)
- Dart 3 + Flutter 3
- Provider para gerenciamento de estado
- GoRouter para navegação
- Dio para HTTP
- Suporta Android e iOS

---

## Integração Sponte

A API do Sponte é um Web Service ASMX hospedado em:

```
https://api.sponteeducacional.net.br/WSAPIEdu.asmx
```

### Autenticação
Todas as chamadas incluem:
```
?nCodigoCliente=17698&sToken=QoCmgKRarHSY&sParametrosBusca=PARAMETROS
```

### Endpoints utilizados

| Endpoint | Uso | Parâmetros |
|---|---|---|
| `GetAlunos` | Dados completos do aluno | `AlunoID=X`, `CPF=X` |
| `GetResponsaveisApp` | Responsáveis e login por CPF | `AlunoID=X`, `LoginPortal=CPF_SEM_PONTOS` |
| `GetParcelas` | Financeiro — parcelas do aluno | `AlunoID=X` |
| `GetTurmas` | Turmas ativas | `AnoLetivo=2026` |
| `GetIntegrantesTurmas` | Alunos de uma turma | `TurmaID=X` |
| `GetMatriculas` | Matrículas | `AnoLetivo=2026`, `AlunoID=X` |
| `GetComunicadosAPP` | Comunicados | `AlunoID=X` |
| `GetCalendarioDidatico` | Agenda escolar | `AlunoID=X` |
| `GetBoletos` | Boletos em aberto | `AlunoID=X` |
| `GetLinhaDigitavelBoletos` | Linha digitável do boleto | `ContaReceberID=X&NumeroParcela=X` |
| `ValidaLoginPortal` | Validação de login | `sLogin=X&sSenha=X` |

### Formato da resposta
A API retorna **XML**. Exemplo de parcela:
```xml
<wsParcela>
  <RetornoOperacao>01 - Operação Realizada com Sucesso.</RetornoOperacao>
  <ContaReceberID>2173</ContaReceberID>
  <NumeroParcela>1</NumeroParcela>
  <SituacaoParcela>Quitada</SituacaoParcela>
  <ValorParcela>3.082,00</ValorParcela>
  <ValorPago>2.157,40</ValorPago>
  <Vencimento>05/01/2026</Vencimento>
  <DataPagamento>05/01/2026</DataPagamento>
  <FormaCobranca>Pix Sponte Pay</FormaCobranca>
  <BolsaAssociada>Bolsa 30%</BolsaAssociada>
  <Categoria>Early Toddler ao Nursery</Categoria>
</wsParcela>
```

---

## Instalação e Execução

### Pré-requisitos
- Node.js 18+
- npm 9+

### 1. Clonar o repositório
```bash
git clone https://github.com/SEU_USUARIO/maple-bear-valqueire.git
cd maple-bear-valqueire
```

### 2. Instalar dependências
```bash
npm install
```

### 3. Configurar credenciais (opcional)
As credenciais já estão incluídas como padrão. Para usar variáveis de ambiente:
```bash
export SPONTE_CODIGO=17698
export SPONTE_TOKEN=QoCmgKRarHSY
export PORT=3006
```

### 4. Executar
```bash
# Produção
npm start

# Desenvolvimento (hot reload)
npm run dev
```

Acesse: **http://localhost:3006**

---

## Estrutura do Projeto

```
maple-bear-valqueire/
├── server.js              # Backend Node.js — proxy Sponte + API
├── package.json           # Dependências Node.js
├── web/
│   └── index.html         # Frontend completo (SPA)
└── lib/                   # Código-fonte Flutter (mobile)
    ├── main.dart
    ├── app.dart
    ├── config/
    │   ├── theme.dart      # Tema Maple Bear (bordô + dourado)
    │   ├── routes.dart     # Navegação GoRouter
    │   └── constants.dart  # URLs e configurações
    ├── models/             # Modelos de dados
    ├── services/           # Integração com API
    ├── providers/          # Gerenciamento de estado
    ├── screens/            # Telas do app
    └── widgets/            # Componentes reutilizáveis
```

---

## Acesso ao Sistema

### Pais e Responsáveis
1. Abra o app ou acesse o site
2. Selecione **"Pais / Alunos"**
3. Informe o **CPF** (do responsável ou do aluno)
4. Informe a **data de nascimento**
5. Clique em **Acessar**

> O CPF é validado diretamente no Sponte. Sem cadastro adicional necessário.

### Secretaria
1. Selecione **"Secretaria"**
2. Informe e-mail e senha
3. Acesse o painel completo de gestão

---

## Deploy

### Como site/API (qualquer servidor Node.js)
```bash
# Render, Railway, Heroku, VPS, etc.
npm start
```

### Como PWA (Progressive Web App)
Ao acessar pelo celular, clique em **"Adicionar à tela inicial"** no navegador para instalar o app sem precisar da App Store.

---

## Licença

MIT — uso livre para fins educacionais e internos da escola.

---

*Maple Bear Valqueire — Rio de Janeiro, 2026*
