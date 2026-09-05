# AgendALuz

Aplicativo Flutter para gestão de agenda, clientes, serviços e financeiro de profissionais autônomos da área da beleza.

## Estado atual do app

- Nome do app: `AgendALuz`
- Versão atual: lida dinamicamente via `package_info_plus` (definida em `pubspec.yaml`, hoje `1.5.0+18`)
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
- Status de pagamento oculto na criação (todo agendamento novo nasce como "não pago"); o toggle Pago/Não Pago só aparece ao editar
- Edição, visualização de detalhes e exclusão (inclusive com `Dismissible`)
- Conclusão automática de atendimentos após o tempo estimado do serviço (ou 120 min como padrão, quando não há serviço/duração definida), marcando `concluido` e `pago` juntos e criando a movimentação financeira automática
- Conclusão manual de atendimento pendente (também marca como pago)
- Desmarcar um atendimento concluído impede que a conclusão automática o marque de novo, até a data ser reagendada

### Atendimentos

- Tela dedicada para atendimentos concluídos
- Considera concluídos explícitos e auto-concluídos (pelo tempo estimado do serviço)
- Filtro por mês
- Busca por nome da cliente
- Total de valor dos atendimentos listados no período
- Ações: visualizar, editar, excluir e desmarcar conclusão

### Clientes

- Cadastro, edição e exclusão com confirmação
- Formatação de telefone no formulário
- Busca por nome
- Exibição de último atendimento (`historico`) e do próximo agendamento
- Tags de relacionamento por recência do último atendimento
- Clientes sem atendimento concluído há 40+ dias (e sem agendamento futuro) ficam ocultas da lista por padrão, com opção de mostrar/ocultar e selo "Inativa"
- Lembrete de Agendamento: envia mensagem pelo WhatsApp convidando a cliente a agendar o próximo horário, citando há quanto tempo foi o último atendimento

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
- Movimentação automática para atendimento pago (manual ou por conclusão automática)
- Dashboard financeiro com estatísticas do mês (receita, despesas, atendimentos, ticket médio, taxa de conclusão, top serviços)
- Resumo mensal com:
  - Receita
  - Despesas
  - Saldo líquido
  - Previsão de receita (atendimentos não pagos)
- Filtro por mês (navegação entre meses)
- Edição/exclusão apenas de movimentações manuais

### Notificações

- Lembretes de atendimento totalmente configuráveis: uma lista de antecedências (1 semana, 3 dias, 2 dias, 1 dia, 3h, 2h, 1h, 30min antes) com toggle individual, mais um interruptor geral para ligar/desligar tudo
- Configurações persistidas com `shared_preferences`; reagendamento acontece automaticamente sempre que alguma opção muda
- Notificação existe apenas para lembrar a profissional do atendimento (não envia nada à cliente)

### Backup e restauração

- Backup automático na inicialização do app
- Backup manual em JSON com compartilhamento (`share_plus`)
- Restauração via seletor de arquivos nativo do Android (SAF, `file_picker`), sem precisar digitar caminho
- Restauração roda em uma única transação (reverte tudo se algo falhar no meio) e cria um backup de segurança antes de sobrescrever os dados
- Metadados do backup (`app_version`) gravados dinamicamente via `package_info_plus`

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
- `/dashboard_financeiro`

## Estrutura técnica

- `lib/database/`: acesso ao SQLite (`DatabaseHelper`)
- `lib/models/`: entidades de domínio
- `lib/screens/`: telas e formulários
- `lib/services/`:
  - `notification_service.dart`
  - `notification_settings_service.dart`
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
- `url_launcher`
- `file_picker`
- `shared_preferences`

## Banco de dados (SQLite)

Versão do schema: `6`
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
| reaberto_manual         | INTEGER (0 ou 1)   |

`reaberto_manual` marca um atendimento que a usuária desmarcou manualmente como concluído, impedindo que a rotina automática o marque de volta até a data ser reagendada.

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


