# 📘 Documentação do MVP — AgendALuz

## 🧾 Visão Geral

**AgendALuz** é um aplicativo voltado para profissionais autônomos — neste caso, especificamente para Amanda Letícia Luz, designer de sobrancelhas — que desejam organizar seus atendimentos, clientes e finanças de maneira prática, eficiente e personalizada.

O aplicativo será desenvolvido utilizando **Flutter/Dart** com persistência local via **SQLite**, e terá foco em funcionalidades que atendam a realidade de um trabalho autônomo baseado em agendamentos, retorno de clientes e controle financeiro direto.

---

## 🎯 Objetivo

Facilitar a gestão da agenda e do faturamento da profissional, otimizando o tempo, melhorando o relacionamento com a clientela e proporcionando clareza sobre os resultados financeiros.

---

## 🔧 Funcionalidades Essenciais

### 1. Cadastro de Clientes

* Nome completo
* Telefone para contato (WhatsApp)
* Observações específicas (ex: alergias, preferências, etc.)
* Data do próximo atendimento
* Frequência personalizada de retorno (ex: a cada 15 ou 30 dias)
* Histórico de atendimentos (lista de datas e valores)

### 2. Agendamento de Atendimentos

* Cliente vinculada
* Data e hora
* Valor do atendimento
* Status de pagamento (Pago / Não pago)
* Observações adicionais (ex: atraso, cancelamento, etc.)
* Possibilidade de reagendar rapidamente a partir do histórico

### 3. Visualização de Agenda

* Visão semanal (foco principal)
* Visão mensal
* Filtros por status de pagamento
* Destaque para atendimentos do dia atual

### 4. Controle Financeiro

* Cadastro de despesas (materiais, transporte, aluguel, etc.)
* Cálculo automático das receitas com base nos atendimentos pagos
* Relatórios e gráficos:

  * Faturamento semanal
  * Faturamento mensal
  * Faturamento trimestral
  * Total de despesas por período
  * Saldo líquido (Receita - Despesas)

### 5. Notificações

* Lembrete do atendimento com horário personalizável (ex: 1h antes, 1 dia antes)
* Lembrete para entrar em contato com a cliente quando estiver próximo o retorno (baseado na frequência personalizada)

### 6. Lista de Clientes

* Pesquisa por nome
* Ordenação por próxima data de retorno
* Indicador visual de cliente com atendimento próximo ou pendente

### 7. Cadastro/Atualização

* Clientes
* Atendimentos
* Despesas

---

## 🔒 Segurança e Privacidade

* Armazenamento local com possibilidade de criptografia (em futuras versões)
* Backup manual/exportação de dados (futuro)
* Acesso local sem necessidade de login em nuvem (offline first)

---

## 📱 Tecnologias Utilizadas

* Flutter (UI e lógica)
* Dart
* SQLite (armazenamento local)
* Path/PathProvider (acesso ao sistema de arquivos)
* flutter\_local\_notifications (notificações locais)
* intl (formatação de datas e moeda)

---

## 🗃️ Estrutura de Dados (Modelagem Inicial)

### Cliente

| Campo                | Tipo     | Descrição                          |
| -------------------- | -------- | ---------------------------------- |
| id                   | int      | Identificador único                |
| nome                 | string   | Nome completo                      |
| telefone             | string   | Telefone com DDD                   |
| observacoes          | string   | Informações específicas do cliente |
| frequencia\_retorno  | int      | Em dias (ex: 15, 30)               |
| proximo\_atendimento | DateTime | Próxima data esperada de retorno   |

### Atendimento

| Campo       | Tipo     | Descrição                  |
| ----------- | -------- | -------------------------- |
| id          | int      | Identificador único        |
| cliente\_id | int      | FK para cliente            |
| data\_hora  | DateTime | Data e hora do atendimento |
| valor       | double   | Valor cobrado              |
| pago        | bool     | Indica se o valor foi pago |
| observacoes | string   | Observações relevantes     |

### Despesa

| Campo     | Tipo     | Descrição                         |
| --------- | -------- | --------------------------------- |
| id        | int      | Identificador único               |
| descricao | string   | Ex: "Cera", "Pinça", "Transporte" |
| valor     | double   | Valor da despesa                  |
| data      | DateTime | Data da despesa                   |

---

## 🚀 Funcionalidades Futuras (pós-MVP)

* Backup automático ou exportação CSV
* Sincronização com Google Agenda
* Cadastro de pacotes de atendimento (ex: combo 3 sessões)
* Controle de estoque básico (materiais)
* Painel de metas mensais
* Proteção com senha/PIN
* Tema escuro

---

## 📌 Considerações Finais

O AgendALuz busca ser mais do que uma agenda digital — é uma ferramenta de autonomia, clareza e profissionalismo para a Amanda e para outros(as) profissionais autônomos(as) que trabalham com atendimento pessoal e recorrente.

A estrutura do MVP foi pensada para ser simples, útil e eficiente. As próximas etapas envolvem a modelagem das classes em Dart, criação do banco de dados SQLite e início da construção das telas com navegação básica.

---

> Documento mantido por José Carlos Leite • Versão inicial — Julho de 2025
