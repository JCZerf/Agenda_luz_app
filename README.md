# 📒 AgendALuz

Aplicativo desenvolvido para auxiliar profissionais autônomos, com foco em **designers de sobrancelhas**, a **gerenciar seus agendamentos, finanças e clientes** de forma simples, organizada e totalmente **offline**.

---

## 🚩 Visão Geral

O app **AgendALuz** foi criado para atender às necessidades reais de uma profissional da beleza (Amanda), permitindo:

- Agendar atendimentos com e sem cliente cadastrada
- Acompanhar o status de cada atendimento (pago, pendente, concluído)
- Registrar receitas e despesas
- Visualizar o desempenho mensal
- Ter controle completo do histórico de clientes e movimentações
- Cadastrar tipos de serviços com valores padrão

---

## 🔧 Funcionalidades Implementadas

### ✅ Clientes
- Cadastro de clientes com:
  - Nome
  - Telefone (formatação automática)
  - Observações
- Visualização detalhada com último atendimento
- Edição e exclusão com confirmação
- Suporte a agendamentos sem cliente cadastrado
- Histórico automático de atendimentos

### ✅ Agendamentos
- Criação de agendamento com ou sem cliente
- Campos:
  - Data e hora
  - Valor
  - Status de pagamento
  - Status de conclusão (concluído ou pendente)
  - Observações
  - Tempo estimado (opcional)
  - Tipo de serviço (opcional)
- Conclusão manual ou automática após a data
- Edição e exclusão com modal de confirmação
- Swipe (`Dismissible`) para deletar direto da lista
- Proteção contra múltiplos salvamentos

### ✅ Agenda (Visualização)
- Modos de exibição: **Diário**, **Semanal**, **Mensal**
- Exibição baseada em **data de referência personalizada**
- Botão “Voltar para Hoje” para retornar ao dia atual
- Destaques visuais:
  - Ícones de status (verde para pago, laranja para pendente)
  - Nome da cliente (mesmo sem cadastro)
  - Cores suaves para foco visual
- Marcação automática de conclusão para atendimentos passados

### ✅ Atendimentos Realizados
- Lista apenas de atendimentos concluídos
- Exibição com nome da cliente e data/hora
- Possibilidade de reverter para “pendente”
- Contador total de atendimentos realizados
- Detalhes completos do atendimento

### ✅ Controle Financeiro
- Tela separada com lista de movimentações
- Receitas e despesas lançadas manualmente
- Receita automática com base em atendimentos pagos
- Distinção clara entre origem **manual** e **automática**
- Exibição do valor total do mês
- Comparativo com mês anterior (crescimento ou queda)
- Edição e exclusão de movimentações

### ✅ Tipos de Serviço
- Cadastro de serviços com:
  - Nome
  - Valor padrão
  - Custo (opcional)
  - Tempo médio em minutos
- Integração com formulário de agendamento
- Preenchimento automático de valor e tempo
- Edição e exclusão com confirmação

---

## 💾 Estrutura do Banco de Dados (SQLite)

### 📌 Tabela: `clientes`
| Campo                | Tipo     |
|----------------------|----------|
| id                   | INTEGER  |
| nome                 | TEXT     |
| telefone             | TEXT     |
| observacoes          | TEXT     |
| frequencia_retorno   | INTEGER  |
| proximo_atendimento  | TEXT     |

### 📌 Tabela: `atendimentos`
| Campo       | Tipo     |
|-------------|----------|
| id          | INTEGER  |
| cliente_id  | INTEGER (nullable) |
| data_hora   | TEXT     |
| valor       | REAL     |
| pago        | INTEGER (0 ou 1) |
| concluido   | INTEGER (0 ou 1) |
| observacoes | TEXT     |

### 📌 Tabela: `movimentacoes_financeiras`
| Campo     | Tipo   |
|-----------|--------|
| id        | INTEGER |
| descricao | TEXT    |
| valor     | REAL    |
| data      | TEXT    |
| tipo      | TEXT    | ('receita' ou 'despesa')
| origem    | TEXT    | ('manual' ou 'automatica')

---

## 🎨 Estilo e Design

- Paleta de cores:
  - 🎀 Rosa principal: `#D9A7B0`
  - 🌸 Rosa claro: `#FFF1F3`
  - 🌺 Rosa escuro (texto): `#8A4B57`
- Visual feminino e delicado, alinhado ao perfil da cliente
- Bordas arredondadas (`Radius.circular(16 ou 20)`)
- Ícones com toque emocional (ex: `Icons.favorite`)
- Tipografia com legibilidade e bom contraste
- `BottomNavigationBar` com 5 abas: Agenda, Atendimentos, Clientes, Serviços e Financeiro

---

## 🧠 Arquitetura Técnica

- **Flutter com SQLite offline**
- Modularização:
  - `models/` para entidades
  - `database/` com `DatabaseHelper`
  - `screens/` para cada tela principal
- Navegação com `Navigator.pushNamed` e argumentos
- Estado local com `setState` e lógica bem encapsulada
- Separação visual e lógica em widgets reutilizáveis
- Modal Bottom Sheets para ações contextuais
- Exibição de data e hora com `intl` (`DateFormat`)
- Compatível com Android e iOS (não requer login)
- Sistema de versionamento do banco de dados com migrations

---

## 🛠️ Versão

```txt
Versão: 1.3.3+8
Status: MVP Completo e Funcional (Correções para Dispositivos Físicos)
Publicação: Uso interno da cliente Amanda (offline)
APK: Disponível em build/app/outputs/flutter-apk/app-release.apk
