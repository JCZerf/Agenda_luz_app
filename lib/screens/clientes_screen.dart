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
  List<Cliente> _clientesFiltrados = [];
  String _textoBusca = '';
  final TextEditingController _controladorBusca = TextEditingController();

  final rosaPrincipal = const Color(0xFFD9A7B0);
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
      _filtrarClientes();
    });
  }

  void _filtrarClientes() {
    setState(() {
      if (_textoBusca.isEmpty) {
        _clientesFiltrados = _clientes;
      } else {
        _clientesFiltrados = _clientes
            .where((cliente) => cliente.nome.toLowerCase().contains(_textoBusca.toLowerCase()))
            .toList();
      }
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

  Map<String, dynamic> _obterTagCliente(String? historicoIso) {
    if (historicoIso == null || historicoIso.trim().isEmpty) {
      return {'texto': 'Novo cliente', 'cor': Colors.blue, 'corFundo': Colors.blue.shade50};
    }

    try {
      final ultimoAtendimento = DateTime.parse(historicoIso);
      final agora = DateTime.now();
      final diasAtras = agora.difference(ultimoAtendimento).inDays;

      if (diasAtras <= 5) {
        return {'texto': 'Recente', 'cor': Colors.green, 'corFundo': Colors.green.shade50};
      } else if (diasAtras <= 10) {
        return {'texto': 'Em rotina', 'cor': Colors.blue, 'corFundo': Colors.blue.shade50};
      } else if (diasAtras <= 15) {
        return {'texto': 'Agendar logo', 'cor': Colors.orange, 'corFundo': Colors.orange.shade50};
      } else if (diasAtras <= 30) {
        return {'texto': 'Atrasando', 'cor': Colors.red, 'corFundo': Colors.red.shade50};
      } else {
        return {'texto': 'Há muito tempo', 'cor': Colors.grey, 'corFundo': Colors.grey.shade50};
      }
    } catch (e) {
      return {'texto': 'Data inválida', 'cor': Colors.grey, 'corFundo': Colors.grey.shade50};
    }
  }

  String _formatarTelefone(String telefone) {
    final digitsOnly = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length == 11) {
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 7)}-${digitsOnly.substring(7)}';
    } else if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
    }

    return telefone;
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
              _linhaDetalhe(Icons.phone, 'Telefone', _formatarTelefone(cliente.telefone)),
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
      appBar: AppBar(
        backgroundColor: rosaTexto,
        elevation: 0,
        title: const Text('Clientes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Informações gerais
          Container(
            padding: const EdgeInsets.all(16),
            color: rosaClaro,
            child: Row(
              children: [
                Icon(Icons.people, color: rosaTexto, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total de clientes: ${_clientes.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: rosaTexto),
                ),
              ],
            ),
          ),
          // Campo de busca
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: TextField(
              controller: _controladorBusca,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nome...',
                prefixIcon: Icon(Icons.search, color: rosaTexto),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: rosaPrincipal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: rosaTexto),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _textoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controladorBusca.clear();
                          setState(() {
                            _textoBusca = '';
                            _filtrarClientes();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (valor) {
                setState(() {
                  _textoBusca = valor;
                  _filtrarClientes();
                });
              },
            ),
          ),
          // Informações do filtro
          if (_textoBusca.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: rosaPrincipal.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: rosaTexto),
                  const SizedBox(width: 8),
                  Text(
                    '${_clientesFiltrados.length} cliente(s) encontrada(s)',
                    style: TextStyle(fontSize: 12, color: rosaTexto),
                  ),
                ],
              ),
            ),
          // Lista de clientes
          Expanded(
            child: _clientesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _textoBusca.isEmpty ? Icons.person_off : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _textoBusca.isEmpty
                              ? 'Nenhuma cliente cadastrada.'
                              : 'Nenhuma cliente encontrada para "$_textoBusca"',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      80,
                    ), // Padding inferior para evitar sobreposição com FAB
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientesFiltrados[index];
                      return GestureDetector(
                        onTap: () => _mostrarOpcoes(cliente),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Avatar com inicial do nome
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: rosaPrincipal.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: rosaPrincipal.withOpacity(0.3)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : 'C',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: rosaTexto,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Informações da cliente
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.nome,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: rosaTexto,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatarTelefone(cliente.telefone),
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _formatarHistorico(cliente.historico),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Tag do cliente
                                      Row(
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final tag = _obterTagCliente(cliente.historico);
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: tag['corFundo'],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: tag['cor'], width: 1),
                                                ),
                                                child: Text(
                                                  tag['texto'],
                                                  style: TextStyle(
                                                    color: tag['cor'],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Ícone de mais opções
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: rosaPrincipal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.more_vert, color: rosaTexto, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cliente_form').then((_) => _carregarClientes());
        },
        backgroundColor: rosaTexto,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }
}
