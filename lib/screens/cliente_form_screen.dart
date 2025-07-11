import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/cliente.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final observacoesController = TextEditingController();
  final historicoController = TextEditingController();

  Cliente? clienteEdicao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['cliente'] is Cliente) {
      clienteEdicao = args['cliente'] as Cliente;
      nomeController.text = clienteEdicao!.nome;
      telefoneController.text = clienteEdicao!.telefone ?? '';
      observacoesController.text = clienteEdicao!.observacoes ?? '';
      historicoController.text = clienteEdicao!.historico ?? '';
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    observacoesController.dispose();
    historicoController.dispose();
    super.dispose();
  }

  Future<void> _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      final novo = Cliente(
        id: clienteEdicao?.id,
        nome: nomeController.text.trim(),
        telefone: telefoneController.text.trim(),
        observacoes: observacoesController.text.trim(),
        historico: historicoController.text.trim(),
      );

      if (clienteEdicao != null) {
        await DatabaseHelper().atualizarCliente(novo);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cliente atualizada com sucesso!')));
      } else {
        await DatabaseHelper().inserirCliente(novo);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cliente salva com sucesso!')));
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildCampo({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: label, prefixIcon: const Icon(Icons.favorite_border)),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Preencha o campo $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(clienteEdicao != null ? 'Editar Cliente' : 'Cadastro de Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCampo(label: 'Nome', controller: nomeController),
              _buildCampo(label: 'Telefone', controller: telefoneController),
              _buildCampo(label: 'Observações', controller: observacoesController, maxLines: 3),
              _buildCampo(label: 'Histórico', controller: historicoController, maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarCliente,
                child: Text(clienteEdicao != null ? 'Salvar Alterações' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
