import 'package:AgendaLuz/database/database_helper.dart';
import '../utils/app_colors.dart';
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

  double _calcularTotal() {
    return _atendimentosFiltrados.fold(0.0, (total, atendimento) {
      final valor = (atendimento['valor'] as num).toDouble();
      return total + valor;
    });
  }

  Future<void> _atualizarAtendimentoNoBanco(Atendimento atendimento) async {
    try {
      await DatabaseHelper().atualizarAtendimento(atendimento);
    } catch (e) {
      print('Erro ao atualizar atendimento no banco: $e');
    }
  }

  String _nomeMes(int mes) {
    final nome = DateFormat('MMMM', 'pt_BR').format(DateTime(2000, mes));
    return toBeginningOfSentenceCase(nome) ?? nome;
  }

  void _selecionarMes() async {
    int mesSelecionadoTemp = _mesSelecionado.month;
    int anoSelecionadoTemp = _mesSelecionado.year;
    final anoAtual = DateTime.now().year;
    final anosDisponiveis = List<int>.generate((anoAtual + 5) - 2020 + 1, (i) => 2020 + i)
        .reversed
        .toList();

    final DateTime? dataSelecionada = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Selecionar mês e ano'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: mesSelecionadoTemp,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mês',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  final mes = index + 1;
                  return DropdownMenuItem<int>(
                    value: mes,
                    child: Text(_nomeMes(mes)),
                  );
                }),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => mesSelecionadoTemp = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: anoSelecionadoTemp,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                ),
                items: anosDisponiveis
                    .map(
                      (ano) => DropdownMenuItem<int>(
                        value: ano,
                        child: Text(ano.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => anoSelecionadoTemp = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                DateTime(anoSelecionadoTemp, mesSelecionadoTemp),
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );

    if (dataSelecionada != null) {
      setState(() {
        _mesSelecionado = DateTime(dataSelecionada.year, dataSelecionada.month);
      });
      _filtrarAtendimentos();
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.textoEscuro,
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
        color: AppColors.rosaClaro,
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
                      const Icon(Icons.calendar_today, color: AppColors.textoEscuro),
                      const SizedBox(width: 8),
                      Text(
                        'Mês: ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textoEscuro,
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
                      prefixIcon: const Icon(Icons.search, color: AppColors.textoEscuro),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.rosaPrincipal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.textoEscuro),
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
              color: AppColors.rosaPrincipal.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textoEscuro),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_atendimentosFiltrados.length} atendimento(s) concluído(s)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textoEscuro),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Total: R\$ ${_calcularTotal().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
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
                                  color: autoConcluido ? Colors.orange : AppColors.rosaPrincipal,
                                ),
                                title: Text(
                                  nome,
                                  style: const TextStyle(
                                    color: AppColors.textoEscuro,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Data: $data', style: const TextStyle(color: AppColors.textoEscuro)),
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
                                trailing: const Icon(Icons.more_vert, color: AppColors.textoEscuro),
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
