
---

## 🔧 Funcionalidades Implementadas

### ✅ Cadastro de Clientes
- Campos: nome, telefone, observações, frequência de retorno, próximo atendimento
- Histórico de atendimentos e reusabilidade da cliente

### ✅ Agendamento de Atendimentos
- Agendamento com ou sem cliente vinculado
- Campos: data/hora, valor, status de pagamento, observações
- Edição e exclusão
- Dismissible para deletar com alerta

### ✅ Visualização da Agenda
- Visões: diária, semanal, mensal
- Filtros de exibição dinâmicos
- Destaque para o dia atual
- Ícones de status de pagamento (check verde para pago)

### ✅ Lista de Clientes
- Exibição em `ListView` com design delicado
- Modal de ações rápidas: visualizar, editar, excluir
- Modal de confirmação de exclusão

### ✅ Controle de Navegação
- Rotas nomeadas organizadas em `main.dart`
- Navegação com argumentos entre telas (modo de edição, atendimento, cliente etc.)

---

## 💾 Estrutura de Banco de Dados (SQLite)

### 📌 Cliente
| Campo                | Tipo     |
|----------------------|----------|
| id                   | INTEGER  |
| nome                 | TEXT     |
| telefone             | TEXT     |
| observacoes          | TEXT     |
| frequencia_retorno   | INTEGER  |
| proximo_atendimento  | TEXT     |

### 📌 Atendimento
| Campo       | Tipo     |
|-------------|----------|
| id          | INTEGER  |
| cliente_id  | INTEGER (nullable) |
| data_hora   | TEXT     |
| valor       | REAL     |
| pago        | INTEGER  |
| observacoes | TEXT     |

### 📌 Despesa
| Campo     | Tipo   |
|-----------|--------|
| id        | INTEGER |
| descricao | TEXT    |
| valor     | REAL    |
| data      | TEXT    |

---

## 🎨 Estilo e Design

- Paleta de cores:
  - Rosa principal: `#D9A7B0`
  - Rosa claro: `#FFF1F3`
  - Texto escuro: `#8A4B57`
- Estilo visual feminino e delicado, alinhado ao público-alvo
- Componentes com bordas arredondadas (`Radius.circular(16 ou 20)`)
- Botão flutuante com ícone de coração (`Icons.favorite`)

---

## 📌 Recursos Técnicos Adicionais

- Utilização de `setState` para reatividade nas telas
- Uso de `Navigator.pushNamed` com argumentos tipados (modo de operação, dados de edição)
- Modularização por responsabilidade (cada função em seu arquivo)

---

## 🚀 Como Executar

1. Clone o projeto:
   ```bash
   git clone https://github.com/seu-usuario/agendaluz.git
   cd agendaluz
