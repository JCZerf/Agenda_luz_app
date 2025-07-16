import 'package:AgendaLuz/database/database_helper.dart';
import 'package:AgendaLuz/models/atendimento.dart';
import 'package:AgendaLuz/models/cliente.dart';
import 'package:AgendaLuz/models/servico.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendamentoFormScreen extends StatefulWidget {
  const AgendamentoFormScreen({super.key});

  @override
  State<AgendamentoFormScreen> createState() => _AgendamentoFormScreenState();
}

bool _dadosIniciaisCarregados = false;

class _AgendamentoFormScreenState extends State<AgendamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeLivreController = TextEditingController();
  final valorController = TextEditingController();
  final observacoesController = TextEditingController();
  final tempoEstimadoController = TextEditingController();

  String modo = 'comCliente';
  int? clienteSelecionadoId;
  List<Cliente> clientes = [];
  List<Servico> servicos = [];
  int? servicoSelecionadoId;

  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;
  bool pago = false;
  bool _salvando = false; // Estado para controlar o salvamento

  Atendimento? agendamentoEdicao;

  final rosa = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
  final rosaTexto = const Color(0xFF8A4B57);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dadosIniciaisCarregados) return; // <-- evita sobrescrever os dados após edição

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      modo = args['modo'] ?? 'comCliente';
      if (args['atendimento'] != null && args['atendimento'] is Atendimento) {
        agendamentoEdicao = args['atendimento'] as Atendimento;
        final a = agendamentoEdicao!;

        clienteSelecionadoId = a.clienteId;
        servicoSelecionadoId = a.servicoId;
        nomeLivreController.text = a.nomeLivre;
        valorController.text = a.valor.toStringAsFixed(2);
        observacoesController.text = a.observacoes ?? '';
        tempoEstimadoController.text = a.tempoEstimadoMinutos?.toString() ?? '';
        dataSelecionada = a.dataHora;
        horaSelecionada = TimeOfDay.fromDateTime(a.dataHora);
        pago = a.pago;

        if (a.clienteId == null) modo = 'semCliente';
      }
    }

    _dadosIniciaisCarregados = true; // <-- importante
    carregarClientes();
  }

  void carregarClientes() async {
    clientes = await DatabaseHelper().listarClientes();
    servicos = await DatabaseHelper().listarServicos();
    setState(() {});
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() {
        horaSelecionada = hora;
      });
    }
  }

  String _buscarNomeClienteSelecionado(int? id) {
    final cliente = clientes.firstWhere(
      (c) => c.id == id,
      orElse: () => Cliente(nome: 'Cliente', telefone: ''),
    );
    return cliente.nome;
  }

  void _onServicoSelecionado(int? servicoId) {
    setState(() {
      servicoSelecionadoId = servicoId;
    });

    if (servicoId != null) {
      final servico = servicos.firstWhere((s) => s.id == servicoId);
      valorController.text = servico.valor.toStringAsFixed(2);
      tempoEstimadoController.text = servico.tempoMedioMinutos.toString();
    }
  }

  void _salvar() async {
    if (_salvando) return; // Previne múltiplos cliques

    if (_formKey.currentState!.validate() && dataSelecionada != null && horaSelecionada != null) {
      setState(() {
        _salvando = true;
      });

      try {
        final dataHora = DateTime(
          dataSelecionada!.year,
          dataSelecionada!.month,
          dataSelecionada!.day,
          horaSelecionada!.hour,
          horaSelecionada!.minute,
        );

        final novo = Atendimento(
          id: agendamentoEdicao?.id,
          clienteId: modo == 'comCliente' ? clienteSelecionadoId : null,
          nomeLivre: modo == 'semCliente'
              ? nomeLivreController.text.trim()
              : _buscarNomeClienteSelecionado(clienteSelecionadoId),
          dataHora: dataHora,
          valor: double.tryParse(valorController.text) ?? 0.0,
          pago: pago,
          observacoes: observacoesController.text.trim(),
          concluido: agendamentoEdicao?.concluido ?? false,
          servicoId: servicoSelecionadoId,
          tempoEstimadoMinutos: int.tryParse(tempoEstimadoController.text),
        );

        final helper = DatabaseHelper();

        if (agendamentoEdicao != null) {
          await helper.atualizarAtendimento(novo);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Agendamento atualizado com sucesso!')));
        } else {
          final id = await helper.inserirAtendimento(novo);
          novo.id = id;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Agendamento salvo com sucesso!')));
        }

        // Lançar no financeiro se pago == true e ainda não houver movimentação automática
        if (pago && novo.id != null) {
          final jaExiste = await helper.movimentacaoExisteParaAtendimento(novo.id!);
          if (!jaExiste) {
            await helper.inserirMovimentacaoAutomatica(novo);
          }
        }

        // Fechar o formulário retornando true para indicar sucesso
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String mensagem = 'Erro ao salvar agendamento. Tente novamente.';

          if (e.toString().contains('TimeoutException')) {
            mensagem = 'Operação demorou muito. Tente novamente.';
          } else if (e.toString().contains('DatabaseException')) {
            mensagem = 'Erro no banco de dados. Tente novamente.';
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
        }
      } finally {
        if (mounted) {
          setState(() {
            _salvando = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos obrigatórios')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        elevation: 0,
        title: Text(
          agendamentoEdicao != null ? 'Editar Agendamento' : 'Novo Agendamento',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: rosaClaro,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),

              // Seção de Cliente
              _buildSecaoCliente(),
              const SizedBox(height: 20),

              // Seção de Data e Hora
              _buildSecaoDataHora(),
              const SizedBox(height: 20),

              // Seção de Serviço
              _buildSecaoServico(),
              const SizedBox(height: 20),

              // Seção de Valor
              _buildSecaoValor(),
              const SizedBox(height: 20),

              // Seção de Pagamento
              _buildSecaoStatusPagamento(),
              const SizedBox(height: 20),

              // Seção de Observações
              _buildSecaoObservacoes(),

              // Status de conclusão (apenas para edição)
              if (agendamentoEdicao != null) ...[
                const SizedBox(height: 20),
                _buildSecaoStatusConclusao(),
              ],

              const SizedBox(height: 32),

              // Botão de Salvar
              _buildBotaoSalvar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecaoCliente() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: rosaTexto),
                const SizedBox(width: 8),
                Text(
                  'Cliente',
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (modo == 'comCliente') ...[
              // Dropdown para cliente cadastrada
              DropdownButtonFormField<int>(
                value: clienteSelecionadoId,
                decoration: InputDecoration(
                  hintText: 'Selecione uma cliente',
                  prefixIcon: Icon(Icons.person_search, color: rosaTexto),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: rosa, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: clientes
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                    .toList(),
                onChanged: (value) => setState(() => clienteSelecionadoId = value),
                validator: (value) => value == null ? 'Selecione uma cliente' : null,
              ),
            ] else ...[
              // Campo de texto para cliente sem cadastro
              TextFormField(
                controller: nomeLivreController,
                decoration: InputDecoration(
                  hintText: 'Nome da cliente',
                  prefixIcon: Icon(Icons.person_add, color: rosaTexto),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: rosa, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da cliente';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoDataHora() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: rosaTexto),
                const SizedBox(width: 8),
                Text(
                  'Data e Horário',
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: rosaTexto, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dataSelecionada != null
                                  ? DateFormat('dd/MM/yyyy').format(dataSelecionada!)
                                  : 'Selecionar data',
                              style: TextStyle(
                                color: dataSelecionada != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _selecionarHora,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: rosaTexto, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              horaSelecionada != null
                                  ? horaSelecionada!.format(context)
                                  : 'Selecionar hora',
                              style: TextStyle(
                                color: horaSelecionada != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoServico() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: rosaTexto),
                const SizedBox(width: 8),
                Text(
                  'Tipo de Serviço',
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<int>(
                value: servicoSelecionadoId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: InputBorder.none,
                  hintText: 'Selecione um serviço (opcional)',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Nenhum serviço específico'),
                  ),
                  ...servicos.map((servico) {
                    return DropdownMenuItem<int>(
                      value: servico.id,
                      child: Text(
                        '${servico.nome} - R\$ ${servico.valor.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                ],
                onChanged: _onServicoSelecionado,
              ),
            ),
            if (servicoSelecionadoId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: tempoEstimadoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tempo estimado (min)',
                        hintText: 'Ex: 60',
                        prefixIcon: Icon(Icons.timer, color: rosaTexto),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoValor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: rosaTexto),
                const SizedBox(width: 8),
                Text(
                  'Valor do Atendimento',
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Digite o valor',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.monetization_on, color: rosaTexto),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: rosa, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o valor do atendimento';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoStatusPagamento() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: rosaTexto),
                const SizedBox(width: 8),
                Text(
                  'Status de Pagamento',
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => pago = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: pago ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: pago ? Colors.green : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: pago ? Colors.green : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pago',
                            style: TextStyle(
                              color: pago ? Colors.green[700] : Colors.grey[600],
                              fontWeight: pago ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => pago = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: !pago ? Colors.orange[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !pago ? Colors.orange : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pending,
                            color: !pago ? Colors.orange : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Não Pago',
                            style: TextStyle(
                              color: !pago ? Colors.orange[700] : Colors.grey[600],
                              fontWeight: !pago ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoObservacoes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: rosaTexto),
                const SizedBox(width: 8),
                Text(
                  'Observações (opcional)',
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: observacoesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Adicione observações sobre o atendimento...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: rosa, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoStatusConclusao() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              agendamentoEdicao!.concluido ? Icons.check_circle : Icons.pending,
              color: agendamentoEdicao!.concluido ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Text(
              agendamentoEdicao!.concluido ? 'Atendimento concluído' : 'Atendimento pendente',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: agendamentoEdicao!.concluido ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _salvando
              ? [Colors.grey, Colors.grey.withOpacity(0.8)]
              : [rosaTexto, rosaTexto.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _salvando ? Colors.grey.withOpacity(0.3) : rosaTexto.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _salvando ? null : _salvar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_salvando)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            else
              const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _salvando
                  ? 'Salvando...'
                  : (agendamentoEdicao != null ? 'Atualizar Agendamento' : 'Salvar Agendamento'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dadosIniciaisCarregados = false;
    super.dispose();
  }
}
