# AgendALuz

Aplicativo para profissionais autônomos, com foco em designers de sobrancelhas, para gerenciar agendamentos, finanças e clientes de forma simples, organizada e totalmente offline.

## Visão geral

O AgendALuz foi criado para atender às necessidades reais de uma profissional da beleza (Amanda), permitindo:

- Agendar atendimentos com e sem cliente cadastrado
- Acompanhar o status de cada atendimento (pago, pendente, concluído)
- Registrar receitas e despesas
- Visualizar o desempenho mensal
- Controlar histórico de clientes e movimentações
- Cadastrar tipos de serviço com valores padrão

## Funcionalidades implementadas

### Clientes

- Cadastro de clientes com nome, telefone e observações
- Formatação automática de telefone
- Visualização detalhada com último atendimento
- Edição e exclusão com confirmação
- Suporte a agendamentos sem cliente cadastrado
- Histórico automático de atendimentos

### Agendamentos

- Criação de agendamento com ou sem cliente
- Campos de data/hora, valor, status de pagamento, status de conclusão, observações, tempo estimado (opcional) e tipo de serviço (opcional)
- Conclusão manual ou automática após a data
- Edição e exclusão com confirmação
- Exclusão rápida com `Dismissible`
- Proteção contra múltiplos salvamentos

### Agenda (visualização)

- Modos de exibição: diário, semanal e mensal
- Exibição baseada em data de referência personalizada
- Botão para retorno ao dia atual
- Destaques visuais para status, cliente e foco de leitura
- Marcação automática de conclusão para atendimentos passados

### Atendimentos realizados

- Lista apenas atendimentos concluídos
- Exibição com cliente e data/hora
- Possibilidade de reverter para pendente
- Contador total de atendimentos realizados
- Detalhes completos do atendimento

### Controle financeiro

- Tela separada para movimentações
- Receitas e despesas lançadas manualmente
- Receita automática com base em atendimentos pagos
- Distinção entre origem manual e automática
- Exibição do valor total do mês
- Comparativo com mês anterior
- Edição e exclusão de movimentações

### Tipos de serviço

- Cadastro com nome, valor padrão, custo (opcional) e tempo médio em minutos
- Integração com formulário de agendamento
- Preenchimento automático de valor e tempo
- Edição e exclusão com confirmação

## Estrutura do banco de dados (SQLite)

### Tabela `clientes`

| Campo               | Tipo              |
|---------------------|-------------------|
| id                  | INTEGER           |
| nome                | TEXT              |
| telefone            | TEXT              |
| observacoes         | TEXT              |
| frequencia_retorno  | INTEGER           |
| proximo_atendimento | TEXT              |

### Tabela `atendimentos`

| Campo       | Tipo               |
|-------------|--------------------|
| id          | INTEGER            |
| cliente_id  | INTEGER (nullable) |
| data_hora   | TEXT               |
| valor       | REAL               |
| pago        | INTEGER (0 ou 1)   |
| concluido   | INTEGER (0 ou 1)   |
| observacoes | TEXT               |

### Tabela `movimentacoes_financeiras`

| Campo     | Tipo                         |
|-----------|------------------------------|
| id        | INTEGER                      |
| descricao | TEXT                         |
| valor     | REAL                         |
| data      | TEXT                         |
| tipo      | TEXT (`receita` ou `despesa`) |
| origem    | TEXT (`manual` ou `automatica`) |

## Estilo e interface

- Paleta de cores principal:
  - Rosa principal: `#D9A7B0`
  - Rosa claro: `#FFF1F3`
  - Rosa escuro (texto): `#8A4B57`
- Interface visual alinhada ao perfil da cliente
- Bordas arredondadas (`Radius.circular(16 ou 20)`)
- Boa legibilidade e contraste
- `BottomNavigationBar` com 5 abas: Agenda, Atendimentos, Clientes, Serviços e Financeiro

## Arquitetura técnica

- Flutter com SQLite offline
- Estrutura por módulos:
  - `models/` para entidades
  - `database/` com `DatabaseHelper`
  - `screens/` para telas principais
- Navegação com `Navigator.pushNamed` e argumentos
- Estado local com `setState`
- Componentes reutilizáveis para separação de UI e lógica
- Modal Bottom Sheets para ações contextuais
- Formatação de data/hora com `intl` (`DateFormat`)
- Compatível com Android e iOS
- Migrations para versionamento do banco de dados

## Versão

```txt
Versão: 1.3.3+8
Status: MVP completo e funcional (correções para dispositivos físicos)
Publicação: uso interno da cliente Amanda (offline)
APK: build/app/outputs/flutter-apk/app-release.apk
```
