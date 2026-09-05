import 'package:AgendaLuz/database/database_helper.dart';
import 'package:AgendaLuz/models/cliente.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_colors.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const int _diasInatividade = 40;

  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  Map<int, Map<String, dynamic>> _tagsPorCliente = {};
  String _textoBusca = '';
  bool _mostrarInativas = false;
  final TextEditingController _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    final lista = await DatabaseHelper().listarClientes();

    final entradas = await Future.wait(
      lista.map((cliente) async => MapEntry(cliente.id!, await _obterTagCliente(cliente))),
    );

    if (!mounted) return;
    setState(() {
      _clientes = lista;
      _tagsPorCliente = Map.fromEntries(entradas);
      _filtrarClientes();
    });
  }

  bool _clienteInativo(Cliente cliente) {
    final tag = _tagsPorCliente[cliente.id];
    if (tag == null) return false;

    final dias = tag['dias'] as int?;
    final temAgendamento = tag['temAgendamento'] as bool? ?? false;
    return dias != null && dias >= _diasInatividade && !temAgendamento;
  }

  int get _quantidadeInativas => _clientes.where(_clienteInativo).length;

  void _filtrarClientes() {
    setState(() {
      Iterable<Cliente> base = _clientes;

      if (_textoBusca.isNotEmpty) {
        base = base.where(
          (cliente) => cliente.nome.toLowerCase().contains(_textoBusca.toLowerCase()),
        );
      }

      if (!_mostrarInativas) {
        base = base.where((cliente) => !_clienteInativo(cliente));
      }

      _clientesFiltrados = base.toList();
    });
  }

  void _alternarMostrarInativas() {
    setState(() {
      _mostrarInativas = !_mostrarInativas;
      _filtrarClientes();
    });
  }

  String _formatarHistorico(String? historicoIso) {
    if (historicoIso == null || historicoIso.trim().isEmpty) {
      return 'Sem atendimento concluído';
    }

    try {
      final data = DateTime.parse(historicoIso);
      return DateFormat('dd/MM/yyyy – HH:mm').format(data);
    } catch (_) {
      return 'Data inválida';
    }
  }

  Future<Map<String, dynamic>> _obterTagCliente(Cliente cliente) async {
    final proximoAgendamento = await DatabaseHelper().buscarProximoAgendamento(cliente.id!);
    final temAgendamento = proximoAgendamento != null;
    
    final ultimoAtendimento = await DatabaseHelper().buscarUltimoAtendimentoConcluido(cliente.id!);
    
    if (ultimoAtendimento == null) {
      return {
        'texto': 'Sem histórico de atendimento', 
        'dias': null,
        'temAgendamento': temAgendamento,
        'cor': AppColors.rosaPrincipal, 
        'corFundo': AppColors.rosaPrincipal.withValues(alpha: 0.1)
      };
    }

    final agora = DateTime.now();
    final diasAtras = agora.difference(ultimoAtendimento).inDays;

    String texto;
    if (diasAtras == 0) {
      texto = 'Hoje';
    } else if (diasAtras == 1) {
      texto = 'Ontem';
    } else {
      texto = 'Há $diasAtras dias';
    }

    return {
      'texto': texto,
      'dias': diasAtras,
      'temAgendamento': temAgendamento,
      'cor': AppColors.rosaPrincipal,
      'corFundo': AppColors.rosaPrincipal.withValues(alpha: 0.1)
    };
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

  String _formatarTempoDecorrido(DateTime data) {
    final dias = DateTime.now().difference(data).inDays;
    if (dias <= 0) return 'hoje';
    if (dias == 1) return '1 dia';
    if (dias < 30) return '$dias dias';
    if (dias < 365) {
      final meses = (dias / 30).round();
      return '$meses ${meses == 1 ? 'mês' : 'meses'}';
    }
    final anos = (dias / 365).round();
    return '$anos ${anos == 1 ? 'ano' : 'anos'}';
  }

  Future<void> _enviarLembreteAgendamento(Cliente cliente) async {
    final ultimoAtendimento = await DatabaseHelper().buscarUltimoAtendimentoConcluido(cliente.id!);

    if (!mounted) return;

    final numeroLimpo = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final numeroCompleto = numeroLimpo.startsWith('55') ? numeroLimpo : '55$numeroLimpo';

    final mensagem = StringBuffer('Olá! Tudo bem? ✨\n\n')
      ..write(
        'Passando para saber se já gostaria de deixar seu próximo horário '
        'para o design de sobrancelhas agendado.\n\n',
      );

    if (ultimoAtendimento != null) {
      mensagem.write(
        'Já faz ${_formatarTempoDecorrido(ultimoAtendimento)} desde o seu último atendimento! ',
      );
    }

    mensagem.write(
      'Estou organizando minha agenda dos próximos dias e gostaria de saber '
      'se posso reservar um horário para você. 🤍\n\n'
      'Caso tenha interesse, me informe o melhor dia e período para verificarmos a disponibilidade.',
    );

    final url = Uri.parse('https://wa.me/$numeroCompleto?text=${Uri.encodeComponent(mensagem.toString())}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
        );
      }
    }
  }

  void _mostrarOpcoes(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.green),
            title: const Text('Lembrete de Agendamento'),
            onTap: () {
              Navigator.pop(context);
              _enviarLembreteAgendamento(cliente);
            },
          ),
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

  void _mostrarDetalhes(Cliente cliente) async {
    final ultimoAtendimento = await DatabaseHelper().buscarUltimoAtendimentoConcluido(cliente.id!);
    
    final proximoAgendamento = await DatabaseHelper().buscarProximoAgendamento(cliente.id!);
    
    final textoUltimoAtendimento = ultimoAtendimento != null
        ? DateFormat('dd/MM/yyyy – HH:mm').format(ultimoAtendimento)
        : 'Sem histórico de atendimento';
    
    final textoProximoAgendamento = proximoAgendamento != null
        ? DateFormat('dd/MM/yyyy – HH:mm').format(proximoAgendamento)
        : null;
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.rosaPrincipal,
                                  AppColors.rosaMedio,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                cliente.nome[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            cliente.nome,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textoEscuro,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildInfoCard(
                      Icons.phone,
                      'Telefone',
                      _formatarTelefone(cliente.telefone),
                      onTap: () => _enviarLembreteAgendamento(cliente),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoCard(
                      Icons.calendar_today,
                      'Último atendimento',
                      textoUltimoAtendimento,
                    ),
                    
                    if (textoProximoAgendamento != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        Icons.event_available,
                        'Próximo agendamento',
                        textoProximoAgendamento,
                        corDestaque: Colors.green,
                      ),
                    ],
                    
                    if ((cliente.observacoes?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        Icons.notes,
                        'Observações',
                        cliente.observacoes!,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.rosaClaro,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('Enviar Lembrete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _enviarLembreteAgendamento(cliente);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, color: AppColors.textoEscuro),
                                  label: const Text('Editar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textoEscuro,
                                    side: const BorderSide(color: AppColors.rosaPrincipal),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Excluir'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(IconData icone, String titulo, String valor, {VoidCallback? onTap, Color? corDestaque}) {
    final cor = corDestaque ?? AppColors.rosaPrincipal;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: corDestaque != null ? cor.withValues(alpha: 0.05) : AppColors.rosaClaro,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icone,
                color: cor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textoEscuro.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textoEscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: corDestaque ?? AppColors.rosaPrincipal,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: const Text('Clientes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.rosaClaro,
            child: Row(
              children: [
                const Icon(Icons.people, color: AppColors.textoEscuro, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total de clientes: ${_clientes.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textoEscuro),
                ),
              ],
            ),
          ),
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
          if (_quantidadeInativas > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.visibility_off, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mostrarInativas
                          ? 'Mostrando $_quantidadeInativas cliente(s) sem atendimento há $_diasInatividade+ dias'
                          : '$_quantidadeInativas cliente(s) sem atendimento há $_diasInatividade+ dias estão ocultas',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                  TextButton(
                    onPressed: _alternarMostrarInativas,
                    child: Text(_mostrarInativas ? 'Ocultar' : 'Mostrar'),
                  ),
                ],
              ),
            ),
          if (_textoBusca.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.rosaPrincipal.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textoEscuro),
                  const SizedBox(width: 8),
                  Text(
                    '${_clientesFiltrados.length} cliente(s) encontrada(s)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textoEscuro),
                  ),
                ],
              ),
            ),
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
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.rosaPrincipal.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: AppColors.rosaPrincipal.withValues(alpha: 0.3)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : 'C',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textoEscuro,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.nome,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textoEscuro,
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
                                      Builder(
                                        builder: (context) {
                                          final tag = _tagsPorCliente[cliente.id];
                                          if (tag == null) return const SizedBox.shrink();

                                          final temAgendamento = tag['temAgendamento'] as bool;
                                          final inativa = _clienteInativo(cliente);

                                          return Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
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
                                              ),
                                              if (temAgendamento)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.green, width: 1),
                                                  ),
                                                  child: const Text(
                                                    'Agendado',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (inativa)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.grey[500]!, width: 1),
                                                  ),
                                                  child: Text(
                                                    'Inativa',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.rosaPrincipal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.more_vert, color: AppColors.textoEscuro, size: 20),
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
        backgroundColor: AppColors.textoEscuro,
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
