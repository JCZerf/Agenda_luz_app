import 'package:AgendaLuz/database/database_helper.dart';
import 'package:flutter/material.dart';

import '../models/movimentacao_financeira.dart';

class MovimentacaoFormScreen extends StatefulWidget {
  const MovimentacaoFormScreen({super.key});

  @override
  State<MovimentacaoFormScreen> createState() => _MovimentacaoFormScreenState();
}

class _MovimentacaoFormScreenState extends State<MovimentacaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  DateTime _data = DateTime.now();
  bool _isReceita = true;
  bool _modoEdicao = false;
  int? _idMovimentacao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['modo'] == 'editar' && args['movimentacao'] != null && !_modoEdicao) {
      final MovimentacaoFinanceira m = args['movimentacao'];

      _descricaoController.text = m.descricao;
      _valorController.text = m.valor.toStringAsFixed(2);
      _data = m.data;
      _isReceita = m.tipo == 'receita';
      _idMovimentacao = m.id;
      _modoEdicao = true;
    }
  }

  Future<void> _salvarMovimentacao() async {
    if (_formKey.currentState!.validate()) {
      final movimentacao = MovimentacaoFinanceira(
        id: _idMovimentacao,
        valor: double.parse(_valorController.text),
        descricao: _descricaoController.text,
        data: _data,
        tipo: _isReceita ? 'receita' : 'despesa',
        origem: 'manual',
      );

      if (_modoEdicao) {
        await DatabaseHelper().atualizarMovimentacao(movimentacao);
      } else {
        await DatabaseHelper().inserirMovimentacao(movimentacao);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modoEdicao ? 'Editar Movimentação' : 'Nova Movimentação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe uma descrição' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                validator: (value) => value == null || value.isEmpty ? 'Informe um valor' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text('${_data.day}/${_data.month}/${_data.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _data,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _data = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                value: _isReceita,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Receita')),
                  DropdownMenuItem(value: false, child: Text('Despesa')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isReceita = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarMovimentacao,
                child: Text(_modoEdicao ? 'Atualizar' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
