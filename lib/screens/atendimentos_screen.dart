import 'package:AgendaLuz/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/atendimento.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
  List<Map<String, dynamic>> _todosAtendimentos = [];
  List<Map<String, dynamic>> _atendimentosFiltrados = [];
  DateTime _mesSelecionado = DateTime.now();
  String _textoBusca = '';
  final TextEditingController _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarAtendimentosConcluidos();
  }

  Future<void> _carregarAtendimentosConcluidos() async {
    final todos = await DatabaseHelper().listarAtendimentosComNomeCliente();
    final agora = DateTime.now();

    // Filtra atendimentos concluídos ou que deveriam ser concluídos automaticamente
    // MAS apenas se a data não for no futuro
    final concluidos = todos.where((a) {
      final concluido = a['concluido'] == 1;
      final dataHora = DateTime.parse(a['data_hora']);
      final duasHorasDepois = dataHora.add(const Duration(hours: 2));
      final deveSerConcluido = agora.isAfter(duasHorasDepois) && dataHora.isBefore(agora);

      return concluido || deveSerConcluido;
    }).toList();

    setState(() {
      _todosAtendimentos = concluidos;
      _filtrarAtendimentos();
    });
  }

  void _filtrarAtendimentos() {
    setState(() {
      _atendimentosFiltrados = _todosAtendimentos.where((atendimento) {
        // Filtra por mês
        final dataAtendimento = DateTime.parse(atendimento['data_hora']);
        final mesAtendimento = DateTime(dataAtendimento.year, dataAtendimento.month);
        final mesFiltro = DateTime(_mesSelecionado.year, _mesSelecionado.month);

        bool mesCorreto = mesAtendimento == mesFiltro;

        // Filtra por nome se há texto de busca
        bool nomeCorreto = true;
        if (_textoBusca.isNotEmpty) {
          final nome = atendimento['nome_cliente'] ?? atendimento['nome_livre'] ?? 'Sem cadastro';
          nomeCorreto = nome.toLowerCase().contains(_textoBusca.toLowerCase());
        }

        return mesCorreto && nomeCorreto;
      }).toList();

      // Ordena por data (mais recente primeiro)
      _atendimentosFiltrados.sort(
        (a, b) => DateTime.parse(b['data_hora']).compareTo(DateTime.parse(a['data_hora'])),
      );
    });
  }

  Future<void> _atualizarAtendimentoNoBanco(Atendimento atendimento) async {
    try {
      await DatabaseHelper().atualizarAtendimento(atendimento);
    } catch (e) {
      print('Erro ao atualizar atendimento no banco: $e');
    }
  }

  void _selecionarMes() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _mesSelecionado,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecione o mês',
      fieldLabelText: 'Mês',
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada != null) {
      setState(() {
        _mesSelecionado = dataSelecionada;
        _filtrarAtendimentos();
      });
    }
  }

  void _mostrarOpcoes(Map<String, dynamic> agendamento) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Visualizar'),
            onTap: () {
              Navigator.pop(context);
              _mostrarDetalhes(agendamento);
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Desmarcar como concluído'),
            onTap: () async {
              Navigator.pop(context);
              final atendimento = Atendimento.fromMap(agendamento);
              atendimento.concluido = false;
              await _atualizarAtendimentoNoBanco(atendimento);
              _carregarAtendimentosConcluidos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atendimento desmarcado como concluído')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/agendamento',
                arguments: {
                  'modo': agendamento['cliente_id'] == null ? 'semCliente' : 'comCliente',
                  'atendimento': Atendimento.fromMap(agendamento),
                },
              ).then((_) => _carregarAtendimentosConcluidos());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirmado = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Excluir Atendimento'),
                  content: const Text('Deseja realmente excluir este atendimento?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      child: const Text('Excluir'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirmado == true) {
                await DatabaseHelper().deletarAtendimento(agendamento['id']);
                _carregarAtendimentosConcluidos();
              }
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhes(Map<String, dynamic> a) {
    final data = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(a['data_hora']));
    final valor = (a['valor'] as num).toDouble();
    final nome = a['nome_livre'] ?? 'Cliente';
    final pago = a['pago'] == 1;
    final observacoes = a['observacoes'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Detalhes do Atendimento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[900],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Cliente: $nome')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Data/Hora: $data')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Valor: R\$ ${valor.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    pago ? Icons.check_circle : Icons.cancel,
                    color: pago ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Pago: ${pago ? 'Sim' : 'Não'}')),
                ],
              ),
              if (observacoes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Obs: $observacoes')),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  child: const Text('Fechar'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const rosaPrincipal = Color(0xFFD9A7B0);
    const rosaClaro = Color(0xFFFFF1F3);
    const rosaTexto = Color(0xFF8A4B57);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        elevation: 0,
        title: const Text('Atendimentos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _selecionarMes,
            tooltip: 'Selecionar mês',
          ),
        ],
      ),
      body: Container(
        color: rosaClaro,
        child: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  // Seletor de mês
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: rosaTexto),
                      const SizedBox(width: 8),
                      Text(
                        'Mês: ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: rosaTexto,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _selecionarMes,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Alterar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Campo de busca
                  TextField(
                    controller: _controladorBusca,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome do cliente...',
                      prefixIcon: const Icon(Icons.search, color: rosaTexto),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: rosaPrincipal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: rosaTexto),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: _textoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controladorBusca.clear();
                                setState(() {
                                  _textoBusca = '';
                                  _filtrarAtendimentos();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (valor) {
                      setState(() {
                        _textoBusca = valor;
                        _filtrarAtendimentos();
                      });
                    },
                  ),
                ],
              ),
            ),
            // Informações do filtro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: rosaPrincipal.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: rosaTexto),
                  const SizedBox(width: 8),
                  Text(
                    '${_atendimentosFiltrados.length} atendimento(s) concluído(s)',
                    style: const TextStyle(fontSize: 12, color: rosaTexto),
                  ),
                ],
              ),
            ),
            // Lista de atendimentos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _atendimentosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _textoBusca.isEmpty ? Icons.event_busy : Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _textoBusca.isEmpty
                                  ? 'Nenhum atendimento concluído neste mês'
                                  : 'Nenhum atendimento encontrado para "$_textoBusca"',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mês: ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _atendimentosFiltrados.length,
                        itemBuilder: (context, index) {
                          final a = _atendimentosFiltrados[index];
                          final dataHora = DateTime.parse(a['data_hora']);
                          final data = DateFormat('dd/MM/yyyy HH:mm').format(dataHora);
                          final nome = a['nome_cliente'] ?? a['nome_livre'] ?? 'Sem cadastro';
                          final valor = (a['valor'] as num).toDouble();
                          final concluido = a['concluido'] == 1;

                          // Verifica se foi concluído automaticamente
                          final agora = DateTime.now();
                          final duasHorasDepois = dataHora.add(const Duration(hours: 2));
                          final deveSerConcluido = agora.isAfter(duasHorasDepois);
                          final autoConcluido = !concluido && deveSerConcluido;

                          return GestureDetector(
                            onTap: () => _mostrarOpcoes(a),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Icon(
                                  autoConcluido ? Icons.schedule : Icons.check_circle,
                                  color: autoConcluido ? Colors.orange : rosaPrincipal,
                                ),
                                title: Text(
                                  nome,
                                  style: const TextStyle(
                                    color: rosaTexto,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Data: $data', style: const TextStyle(color: rosaTexto)),
                                    Text(
                                      'Valor: R\$ ${valor.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (autoConcluido) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange, width: 1),
                                        ),
                                        child: Text(
                                          'AUTO-CONCLUÍDO',
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(Icons.more_vert, color: rosaTexto),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }
}
