# AgendALuz

Aplicativo Flutter para gestão de agenda, clientes, serviços e financeiro de profissionais autônomos da área da beleza.

## Estado atual do app

- Nome do app: `AgendALuz`
- Versão atual: `1.4.2+17` (conforme `pubspec.yaml`)
- Plataforma: Flutter (Android/iOS)
- Idioma padrão: `pt_BR`
- Persistência local: SQLite (`agendaluz_v5.db`)
- Operação: offline (sem login)

## Funcionalidades implementadas

### Agenda

- Visualização por período: diário, semanal e mensal
- Seleção de data de referência na agenda
- Botão "Voltar para Hoje"
- Criação de agendamento em dois modos:
  - Com cliente cadastrado
  - Sem cliente cadastrado (`nome_livre`)
- Edição, visualização de detalhes e exclusão (inclusive com `Dismissible`)
- Conclusão automática de atendimentos passados em mais de 2 horas
- Conclusão manual de atendimento pendente

### Atendimentos

- Tela dedicada para atendimentos concluídos
- Considera concluídos explícitos e auto-concluídos (2h+)
- Filtro por mês
- Busca por nome da cliente
- Total de valor dos atendimentos listados no período
- Ações: visualizar, editar, excluir e desmarcar conclusão

### Clientes

- Cadastro, edição e exclusão com confirmação
- Formatação de telefone no formulário
- Busca por nome
- Exibição de último atendimento (`historico`)
- Tags de relacionamento por recência do último atendimento (ex.: Recente, Em rotina, Agendar logo)

### Serviços

- Cadastro de serviço com:
  - Nome
  - Valor
  - Custo opcional
  - Tempo médio em minutos
- Edição, exclusão e visualização de detalhes
- Preenchimento automático de valor e tempo no agendamento
- Contagem de serviços realizados por serviço
- Relatório mensal de serviços (total, valor e distribuição por tipo)

### Financeiro

- Registro de movimentações manuais (receita/despesa)
- Movimentação automática para atendimento pago
- Resumo mensal com:
  - Receita
  - Despesas
  - Saldo líquido
  - Previsão de receita (atendimentos não pagos)
- Filtro por mês (navegação entre meses)
- Edição/exclusão apenas de movimentações manuais

### Notificações

- Inicialização de notificações locais na abertura do app
- Agendamento automático por atendimento futuro:
  - 2 dias antes
  - 1 dia antes
  - 2 horas antes
- Reagendamento global de notificações
- Cancelamento global de notificações
- Tela de gerenciamento com listagem de notificações pendentes
- Notificação de teste imediata

### Backup e restauração

- Backup automático na inicialização do app
- Backup manual em JSON com compartilhamento (`share_plus`)
- Listagem de backups locais salvos no diretório da aplicação
- Restauração de backup com confirmação e backup de segurança prévio
- Opção de restauração por caminho de arquivo

## Navegação principal

A `BottomNavigationBar` possui 5 abas:

- Agenda
- Atendimentos
- Clientes
- Serviços
- Financeiro

Rotas nomeadas em `MaterialApp`:

- `/home`
- `/agendamento`
- `/cliente_form`
- `/nova_movimentacao`
- `/servico_form`
- `/notifications`
- `/configuracoes`

## Estrutura técnica

- `lib/database/`: acesso ao SQLite (`DatabaseHelper`)
- `lib/models/`: entidades de domínio
- `lib/screens/`: telas e formulários
- `lib/services/`:
  - `notification_service.dart`
  - `backup_service.dart`
- `lib/utils/`: componentes auxiliares

Principais pacotes:

- `sqflite`
- `path`
- `intl`
- `flutter_local_notifications`
- `timezone`
- `path_provider`
- `share_plus`
- `package_info_plus`

## Banco de dados (SQLite)

Versão do schema: `5`
Arquivo: `agendaluz_v5.db`

### Tabela `clientes`

| Campo        | Tipo    |
|--------------|---------|
| id           | INTEGER |
| nome         | TEXT    |
| telefone     | TEXT    |
| observacoes  | TEXT    |
| historico    | TEXT    |

### Tabela `atendimentos`

| Campo                   | Tipo               |
|-------------------------|--------------------|
| id                      | INTEGER            |
| cliente_id              | INTEGER (nullable) |
| nome_livre              | TEXT               |
| data_hora               | TEXT               |
| valor                   | REAL               |
| pago                    | INTEGER (0 ou 1)   |
| observacoes             | TEXT               |
| concluido               | INTEGER (0 ou 1)   |
| servico_id              | INTEGER (nullable) |
| tempo_estimado_minutos  | INTEGER (nullable) |

### Tabela `movimentacoes_financeiras`

| Campo          | Tipo                       |
|----------------|----------------------------|
| id             | INTEGER                    |
| tipo           | TEXT (`receita`/`despesa`) |
| valor          | REAL                       |
| descricao      | TEXT                       |
| data           | TEXT                       |
| origem         | TEXT (`manual`/`automatica`) |
| atendimento_id | INTEGER (nullable)         |

### Tabela `servicos`

| Campo               | Tipo    |
|---------------------|---------|
| id                  | INTEGER |
| nome                | TEXT    |
| valor               | REAL    |
| custo               | REAL    |
| tempo_medio_minutos | INTEGER |
| data_criacao        | TEXT    |

## Execução do projeto

```bash
flutter pub get
flutter run
```

## Observações

- O app inclui telas de configurações para backup e notificações.
- O projeto possui classes legadas (`agendamento.dart` e `atedimento_Com_Cliente.dart`) que não são o modelo principal atualmente.
