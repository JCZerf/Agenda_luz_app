import 'package:agendaluz/database/database_helper.dart';
import 'package:agendaluz/models/atendimento.dart';
import 'package:agendaluz/models/cliente.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendamentoFormScreen extends StatefulWidget {
  const AgendamentoFormScreen({super.key});

  @override
  State<AgendamentoFormScreen> createState() => _AgendamentoFormScreenState();
}

class _AgendamentoFormScreenState extends State<AgendamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeLivreController = TextEditingController();
  final valorController = TextEditingController();
  final observacoesController = TextEditingController();

  String modo = 'comCliente';
  int? clienteSelecionadoId;
  List<Cliente> clientes = [];

  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;
  bool pago = false;

  Atendimento? agendamentoEdicao;

  final rosa = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
  final rosaTexto = const Color(0xFF8A4B57);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      modo = args['modo'] ?? 'comCliente';
      if (args['atendimento'] != null && args['atendimento'] is Atendimento) {
        agendamentoEdicao = args['atendimento'] as Atendimento;
        final a = agendamentoEdicao!;

        clienteSelecionadoId = a.clienteId;
        nomeLivreController.text = a.nomeLivre ?? '';
        valorController.text = a.valor.toStringAsFixed(2);
        observacoesController.text = a.observacoes ?? '';
        dataSelecionada = a.dataHora;
        horaSelecionada = TimeOfDay.fromDateTime(a.dataHora);
        pago = a.pago;

        if (a.clienteId == null) modo = 'semCliente';
      }
    }
    carregarClientes();
  }

  void carregarClientes() async {
    clientes = await DatabaseHelper().listarClientes();
    setState(() {});
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data != null) setState(() => dataSelecionada = data);
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) setState(() => horaSelecionada = hora);
  }

  void _salvar() async {
    if (_formKey.currentState!.validate() && dataSelecionada != null && horaSelecionada != null) {
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
        nomeLivre: modo == 'semCliente' ? nomeLivreController.text.trim() : null,
        dataHora: dataHora,
        valor: double.tryParse(valorController.text) ?? 0.0,
        pago: pago,
        observacoes: observacoesController.text.trim(),
      );

      if (agendamentoEdicao != null) {
        await DatabaseHelper().atualizarAtendimento(novo);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agendamento atualizado com sucesso!')));
      } else {
        await DatabaseHelper().inserirAtendimento(novo);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agendamento salvo com sucesso!')));
      }

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos obrigatórios')));
    }
  }

  Widget _buildCampoTexto({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    int maxLines = 1,
    bool obrigatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon ?? Icons.favorite_border),
        ),
        validator: obrigatorio
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Preencha o campo $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = dataSelecionada != null
        ? DateFormat('dd/MM/yyyy').format(dataSelecionada!)
        : 'Selecionar data';
    final horaFormatada = horaSelecionada != null
        ? horaSelecionada!.format(context)
        : 'Selecionar hora';

    return Scaffold(
      appBar: AppBar(
        title: Text(agendamentoEdicao != null ? 'Editar Agendamento' : 'Novo Agendamento'),
      ),
      body: Container(
        color: rosaClaro,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (modo == 'comCliente') ...[
                const Text('Selecionar Cliente'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: clienteSelecionadoId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  items: clientes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                      .toList(),
                  onChanged: (value) => setState(() => clienteSelecionadoId = value),
                  validator: (value) => value == null ? 'Selecione uma cliente' : null,
                ),
              ] else ...[
                _buildCampoTexto(label: 'Nome da cliente', controller: nomeLivreController),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(dataFormatada),
                      onPressed: _selecionarData,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(horaFormatada),
                      onPressed: _selecionarHora,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCampoTexto(
                label: 'Valor',
                controller: valorController,
                icon: Icons.attach_money,
              ),
              const SizedBox(height: 12),
              const Text(
                'Status de pagamento',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => pago = true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: pago ? rosa : Colors.white,
                        side: BorderSide(color: rosa),
                      ),
                      child: Text(
                        'Pago',
                        style: TextStyle(
                          color: pago ? Colors.white : rosaTexto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => pago = false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !pago ? rosa : Colors.white,
                        side: BorderSide(color: rosa),
                      ),
                      child: Text(
                        'Não Pago',
                        style: TextStyle(
                          color: !pago ? Colors.white : rosaTexto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: observacoesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Observações',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.favorite),
                label: const Text('Salvar Agendamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
