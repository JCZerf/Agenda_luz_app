import 'package:agendaluz/database/database_helper.dart';
import 'package:agendaluz/models/cliente.dart';
import 'package:flutter/material.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];

  final rosa = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
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

  void _mostrarDetalhes(Cliente cliente) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cliente.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telefone: ${cliente.telefone}'),
            if (cliente.observacoes.isNotEmpty ?? false)
              Text('Observações: ${cliente.observacoes}'),
            if (cliente.historico.isNotEmpty ?? false) Text('Histórico: ${cliente.historico}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
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
