import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/servico.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  List<Servico> _servicos = [];
  List<Servico> _servicosFiltrados = [];
  String _textoBusca = '';
  final TextEditingController _controladorBusca = TextEditingController();

  final rosaPrincipal = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
  final rosaTexto = const Color(0xFF8A4B57);

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    final lista = await DatabaseHelper().listarServicos();
    setState(() {
      _servicos = lista;
      _filtrarServicos();
    });
  }

  void _filtrarServicos() {
    setState(() {
      if (_textoBusca.isEmpty) {
        _servicosFiltrados = _servicos;
      } else {
        _servicosFiltrados = _servicos
            .where((servico) => servico.nome.toLowerCase().contains(_textoBusca.toLowerCase()))
            .toList();
      }
    });
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  String _formatarTempo(int minutos) {
    if (minutos >= 60) {
      final horas = minutos ~/ 60;
      final minutosRestantes = minutos % 60;
      if (minutosRestantes == 0) {
        return '${horas}h';
      } else {
        return '${horas}h ${minutosRestantes}min';
      }
    } else {
      return '${minutos}min';
    }
  }

  void _mostrarOpcoes(Servico servico) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.visibility, color: rosaTexto),
            title: const Text('Visualizar'),
            onTap: () {
              Navigator.pop(context);
              _mostrarDetalhes(servico);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: rosaTexto),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/servico_form',
                arguments: {'servico': servico},
              ).then((_) => _carregarServicos());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              _confirmarExclusao(servico);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmarExclusao(Servico servico) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Serviço'),
        content: Text('Deseja realmente excluir o serviço "${servico.nome}"?'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await DatabaseHelper().deletarServico(servico.id!);
      _carregarServicos();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Serviço "${servico.nome}" excluído com sucesso!')));
      }
    }
  }

  void _mostrarDetalhes(Servico servico) {
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
                  'Detalhes do Serviço',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: rosaTexto),
                ),
              ),
              const SizedBox(height: 20),
              _buildLinhaDetalhe(Icons.label, 'Nome', servico.nome),
              _buildLinhaDetalhe(Icons.attach_money, 'Valor', _formatarValor(servico.valor)),
              if (servico.custo != null)
                _buildLinhaDetalhe(Icons.money_off, 'Custo', _formatarValor(servico.custo!)),
              _buildLinhaDetalhe(
                Icons.timer,
                'Tempo médio',
                _formatarTempo(servico.tempoMedioMinutos),
              ),
              if (servico.custo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lucro por serviço: ${_formatarValor(servico.valor - servico.custo!)}',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
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
                          '/servico_form',
                          arguments: {'servico': servico},
                        ).then((_) => _carregarServicos());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmarExclusao(servico);
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

  Widget _buildLinhaDetalhe(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: rosaPrincipal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$titulo: $valor', style: TextStyle(fontSize: 16, color: rosaTexto)),
          ),
        ],
      ),
    );
  }

  void _mostrarRelatorioMensal() async {
    final mesAtual = DateTime.now();
    final relatorio = await DatabaseHelper().relatorioMensalServicos(mes: mesAtual);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.bar_chart, color: rosaTexto),
              const SizedBox(width: 8),
              Text(
                'Relatório - ${DateFormat('MMMM yyyy', 'pt_BR').format(mesAtual)}',
                style: TextStyle(color: rosaTexto),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Resumo geral
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rosaClaro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildResumoItem('Total de serviços', '${relatorio['totalServicos']}'),
                      _buildResumoItem('Valor total', _formatarValor(relatorio['valorTotal'])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Serviços por tipo
                if ((relatorio['servicosPorTipo'] as Map).isNotEmpty) ...[
                  Text(
                    'Serviços por tipo:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: rosaTexto),
                  ),
                  const SizedBox(height: 8),
                  ...(relatorio['servicosPorTipo'] as Map<String, int>).entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            '${entry.value}x',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Text('Nenhum serviço realizado este mês.'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text('Fechar'), onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    }
  }

  Widget _buildResumoItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        elevation: 0,
        title: const Text('Serviços', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _mostrarRelatorioMensal,
            tooltip: 'Relatório mensal',
          ),
        ],
      ),
      body: Column(
        children: [
          // Informações gerais
          Container(
            padding: const EdgeInsets.all(16),
            color: rosaClaro,
            child: Row(
              children: [
                Icon(Icons.favorite, color: rosaTexto, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total de serviços: ${_servicos.length}',
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
                hintText: 'Buscar serviço por nome...',
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
                            _filtrarServicos();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (valor) {
                setState(() {
                  _textoBusca = valor;
                  _filtrarServicos();
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
                    '${_servicosFiltrados.length} serviço(s) encontrado(s)',
                    style: TextStyle(fontSize: 12, color: rosaTexto),
                  ),
                ],
              ),
            ),

          // Lista de serviços
          Expanded(
            child: _servicosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _textoBusca.isEmpty ? Icons.favorite_border : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _textoBusca.isEmpty
                              ? 'Nenhum serviço cadastrado.\nToque no botão + para adicionar.'
                              : 'Nenhum serviço encontrado para "$_textoBusca"',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _servicosFiltrados.length,
                    itemBuilder: (context, index) {
                      final servico = _servicosFiltrados[index];
                      return GestureDetector(
                        onTap: () => _mostrarOpcoes(servico),
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
                                // Ícone do serviço
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: rosaPrincipal.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: rosaPrincipal.withOpacity(0.3)),
                                  ),
                                  child: Icon(Icons.favorite, color: rosaTexto, size: 24),
                                ),
                                const SizedBox(width: 16),

                                // Informações do serviço
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        servico.nome,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: rosaTexto,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_money,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatarValor(servico.valor),
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatarTempo(servico.tempoMedioMinutos),
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<int>(
                                        future: DatabaseHelper().contarServicosRealizados(
                                          servico.id!,
                                        ),
                                        builder: (context, snapshot) {
                                          final count = snapshot.data ?? 0;
                                          return Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$count realizados',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
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
          Navigator.pushNamed(context, '/servico_form').then((_) => _carregarServicos());
        },
        backgroundColor: rosaTexto,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }
}
