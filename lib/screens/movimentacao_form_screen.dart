import 'package:AgendaLuz/database/database_helper.dart';
import '../utils/app_colors.dart';
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
  bool _salvando = false;

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
    if (_salvando) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _salvando = true;
      });

      try {
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

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar movimentação. Tente novamente.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _salvando = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: Text(
          _modoEdicao ? 'Editar Movimentação' : 'Nova Movimentação',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: AppColors.rosaClaro,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                Container(
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
                  child: TextFormField(
                    controller: _descricaoController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Digite a descrição da movimentação',
                      prefixIcon: const Icon(Icons.description, color: AppColors.textoEscuro),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.rosaPrincipal, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Informe uma descrição' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                  child: TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Valor (R\$)',
                      hintText: 'Digite o valor',
                      prefixIcon: const Icon(Icons.attach_money, color: AppColors.textoEscuro),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.rosaPrincipal, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Informe um valor' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.calendar_today, color: AppColors.textoEscuro),
                    title: const Text(
                      'Data',
                      style: TextStyle(color: AppColors.textoEscuro, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textoEscuro),
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
                ),
                const SizedBox(height: 16),
                Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de Movimentação',
                          style: TextStyle(
                            color: AppColors.textoEscuro,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isReceita = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: _isReceita ? Colors.green[50] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isReceita ? Colors.green : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: _isReceita ? Colors.green : Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Receita',
                                        style: TextStyle(
                                          color: _isReceita ? Colors.green[700] : Colors.grey[600],
                                          fontWeight: _isReceita
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isReceita = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: !_isReceita ? Colors.red[50] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !_isReceita ? Colors.red : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: !_isReceita ? Colors.red : Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Despesa',
                                        style: TextStyle(
                                          color: !_isReceita ? Colors.red[700] : Colors.grey[600],
                                          fontWeight: !_isReceita
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _salvando
                          ? [Colors.grey, Colors.grey.withValues(alpha: 0.8)]
                          : [AppColors.textoEscuro, AppColors.textoEscuro.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _salvando
                            ? Colors.grey.withValues(alpha: 0.3)
                            : AppColors.textoEscuro.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvarMovimentacao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _salvando
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Salvando...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _modoEdicao ? 'Atualizar Movimentação' : 'Salvar Movimentação',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
