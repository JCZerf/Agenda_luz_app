import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/servico.dart';

class ServicoFormScreen extends StatefulWidget {
  const ServicoFormScreen({super.key});

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final valorController = TextEditingController();
  final custoController = TextEditingController();
  final tempoController = TextEditingController();

  Servico? servicoEdicao;

  final rosaPrincipal = const Color(0xFFD9A7B0);
  final rosaClaro = const Color(0xFFFFF1F3);
  final rosaTexto = const Color(0xFF8A4B57);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['servico'] is Servico) {
      servicoEdicao = args['servico'] as Servico;
      nomeController.text = servicoEdicao!.nome;
      valorController.text = servicoEdicao!.valor.toStringAsFixed(2);
      custoController.text = servicoEdicao!.custo?.toStringAsFixed(2) ?? '';
      tempoController.text = servicoEdicao!.tempoMedioMinutos.toString();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    valorController.dispose();
    custoController.dispose();
    tempoController.dispose();
    super.dispose();
  }

  Future<void> _salvarServico() async {
    if (_formKey.currentState!.validate()) {
      try {
        final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
        final custo = custoController.text.isNotEmpty
            ? double.tryParse(custoController.text.replaceAll(',', '.'))
            : null;
        final tempo = int.tryParse(tempoController.text) ?? 0;

        final servico = Servico(
          id: servicoEdicao?.id,
          nome: nomeController.text.trim(),
          valor: valor,
          custo: custo,
          tempoMedioMinutos: tempo,
          dataCriacao: servicoEdicao?.dataCriacao,
        );

        if (servicoEdicao != null) {
          await DatabaseHelper().atualizarServico(servico);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Serviço atualizado com sucesso!')));
          }
        } else {
          await DatabaseHelper().inserirServico(servico);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Serviço cadastrado com sucesso!')));
          }
        }

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Erro ao salvar serviço. Tente novamente.')));
        }
      }
    }
  }

  Widget _buildSecao({required String titulo, required IconData icone, required Widget conteudo}) {
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
                Icon(icone, color: rosaTexto, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(color: rosaTexto, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            conteudo,
          ],
        ),
      ),
    );
  }

  Widget _buildCampoTexto({
    required String hintText,
    required TextEditingController controller,
    required IconData icone,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icone, color: rosaTexto),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rosaPrincipal, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        elevation: 0,
        title: Text(
          servicoEdicao != null ? 'Editar Serviço' : 'Novo Serviço',
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

              // Informações Básicas
              _buildSecao(
                titulo: 'Informações do Serviço',
                icone: Icons.favorite,
                conteudo: Column(
                  children: [
                    _buildCampoTexto(
                      hintText: 'Nome do serviço',
                      controller: nomeController,
                      icone: Icons.label,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do serviço';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Valores
              _buildSecao(
                titulo: 'Valores',
                icone: Icons.monetization_on,
                conteudo: Column(
                  children: [
                    _buildCampoTexto(
                      hintText: 'Valor do serviço (R\$)',
                      controller: valorController,
                      icone: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o valor do serviço';
                        }
                        final valor = double.tryParse(value.replaceAll(',', '.'));
                        if (valor == null || valor <= 0) {
                          return 'Valor deve ser maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCampoTexto(
                      hintText: 'Custo do serviço (R\$) - opcional',
                      controller: custoController,
                      icone: Icons.money_off,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final custo = double.tryParse(value.replaceAll(',', '.'));
                          if (custo == null || custo < 0) {
                            return 'Custo deve ser zero ou positivo';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tempo
              _buildSecao(
                titulo: 'Duração',
                icone: Icons.access_time,
                conteudo: _buildCampoTexto(
                  hintText: 'Tempo médio em minutos',
                  controller: tempoController,
                  icone: Icons.timer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o tempo médio do serviço';
                    }
                    final tempo = int.tryParse(value);
                    if (tempo == null || tempo <= 0) {
                      return 'Tempo deve ser maior que zero';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Botão Salvar
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rosaTexto, rosaTexto.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: rosaTexto.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _salvarServico,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        servicoEdicao != null ? 'Atualizar Serviço' : 'Salvar Serviço',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
