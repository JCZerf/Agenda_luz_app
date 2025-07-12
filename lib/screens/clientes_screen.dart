import 'package:AgendaLuz/database/database_helper.dart';
import 'package:AgendaLuz/models/cliente.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];

  final rosa = const Color(0xFFD9A7B0);
  final rosaClaro = const Color.fromARGB(255, 255, 255, 255);
  final rosaTexto = const Color(0xFF8A4B57);

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    final lista = await DatabaseHelper().listarClientes();
    setState(() {
      _clientes = lista;
    });
  }

  String _formatarHistorico(String? historicoIso) {
    if (historicoIso == null || historicoIso.trim().isEmpty) {
      return 'Sem histórico de atendimento';
    }

    try {
      final data = DateTime.parse(historicoIso);
      return DateFormat('dd/MM/yyyy – HH:mm').format(data);
    } catch (_) {
      return 'Data inválida';
    }
  }

  void _mostrarOpcoes(Cliente cliente) {
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
              _mostrarDetalhes(cliente);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/cliente_form',
                arguments: {'modo': 'editar', 'cliente': cliente},
              ).then((_) => _carregarClientes());
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
                  title: const Text('Excluir Cliente'),
                  content: Text('Deseja realmente excluir ${cliente.nome}?'),
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
                await DatabaseHelper().deletarCliente(cliente.id!);
                _carregarClientes();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _linhaDetalhe(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: const Color(0xFFD9A7B0)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$titulo: $valor',
              style: const TextStyle(fontSize: 16, color: Color(0xFF8A4B57)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhes(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: rosaClaro,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Detalhes da Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: rosaTexto),
                ),
              ),
              const SizedBox(height: 16),
              _linhaDetalhe(Icons.person, 'Nome', cliente.nome),
              _linhaDetalhe(Icons.phone, 'Telefone', cliente.telefone),
              if ((cliente.observacoes?.trim().isNotEmpty ?? false))
                _linhaDetalhe(Icons.notes, 'Observações', cliente.observacoes!),
              _linhaDetalhe(
                Icons.calendar_today,
                'Último atendimento',
                _formatarHistorico(cliente.historico),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/cliente_form',
                          arguments: {'modo': 'editar', 'cliente': cliente},
                        ).then((_) => _carregarClientes());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        Navigator.pop(context);
                        final confirmado = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Excluir Cliente'),
                            content: Text('Deseja realmente excluir ${cliente.nome}?'),
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
                          await DatabaseHelper().deletarCliente(cliente.id!);
                          _carregarClientes();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
      appBar: AppBar(title: const Text('Clientes')),
      body: _clientes.isEmpty
          ? const Center(child: Text('Nenhuma cliente cadastrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return GestureDetector(
                  onTap: () => _mostrarOpcoes(cliente),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: rosaClaro,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFFD9A7B0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cliente.nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A4B57),
                              ),
                            ),
                          ),
                          const Icon(Icons.more_vert, color: Color(0xFF8A4B57)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cliente_form').then((_) => _carregarClientes());
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
