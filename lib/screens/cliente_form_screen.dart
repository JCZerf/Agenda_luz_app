import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/cliente.dart';

class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Remove todos os caracteres não numéricos
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 11 dígitos (DDD + 9 dígitos)
    final limitedDigits = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;

    String formatted = '';

    if (limitedDigits.isNotEmpty) {
      // Adiciona parênteses ao DDD
      if (limitedDigits.length >= 2) {
        formatted = '(${limitedDigits.substring(0, 2)})';

        if (limitedDigits.length > 2) {
          formatted += ' ';

          // Para números com 11 dígitos (celular com 9)
          if (limitedDigits.length == 11) {
            formatted += limitedDigits.substring(2, 7);
            if (limitedDigits.length > 7) {
              formatted += '-${limitedDigits.substring(7)}';
            }
          }
          // Para números com 10 dígitos (fixo)
          else if (limitedDigits.length == 10) {
            formatted += limitedDigits.substring(2, 6);
            if (limitedDigits.length > 6) {
              formatted += '-${limitedDigits.substring(6)}';
            }
          }
          // Para números incompletos
          else {
            final remaining = limitedDigits.substring(2);
            if (remaining.length <= 4) {
              formatted += remaining;
            } else if (remaining.length <= 5) {
              formatted += remaining.substring(0, 4);
              if (remaining.length > 4) {
                formatted += '-${remaining.substring(4)}';
              }
            } else {
              formatted += '${remaining.substring(0, 5)}-${remaining.substring(5)}';
            }
          }
        }
      } else {
        formatted = limitedDigits;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

  Cliente? clienteEdicao;
  bool _salvando = false; // Estado para controlar o salvamento

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['cliente'] is Cliente) {
      clienteEdicao = args['cliente'] as Cliente;
      nomeController.text = clienteEdicao!.nome;

      // Formatar o telefone para exibição
      final telefone = clienteEdicao!.telefone;
      if (telefone.isNotEmpty) {
        telefoneController.text = _formatarTelefone(telefone);
      }

      observacoesController.text = clienteEdicao!.observacoes ?? '';
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

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvarCliente() async {
    if (_salvando) return; // Previne múltiplos cliques

    if (_formKey.currentState!.validate()) {
      setState(() {
        _salvando = true;
      });

      try {
        // Validação adicional para nome
        if (nomeController.text.trim().isEmpty) {
          throw Exception('Nome é obrigatório');
        }

        // Remove formatação do telefone para salvar apenas os dígitos
        final telefoneFormatado = telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

        // Validação do telefone
        if (telefoneFormatado.length < 10) {
          throw Exception('Telefone deve ter pelo menos 10 dígitos');
        }

        final novo = Cliente(
          id: clienteEdicao?.id,
          nome: nomeController.text.trim(),
          telefone: telefoneFormatado,
          observacoes: observacoesController.text.trim().isEmpty
              ? null
              : observacoesController.text.trim(),
          historico: clienteEdicao?.historico, // histórico continua intacto, mas não é editável
        );

        // Operação com timeout
        final operacao = clienteEdicao != null
            ? DatabaseHelper().atualizarCliente(novo)
            : DatabaseHelper().inserirCliente(novo);

        await operacao.timeout(const Duration(seconds: 10));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                clienteEdicao != null
                    ? 'Cliente atualizada com sucesso!'
                    : 'Cliente salva com sucesso!',
              ),
            ),
          );

          // Aguarda um pouco antes de fechar para garantir que o SnackBar seja visto
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          String mensagem = 'Erro ao salvar cliente. Tente novamente.';

          // Mensagens específicas para alguns erros
          if (e.toString().contains('Nome é obrigatório')) {
            mensagem = 'Nome é obrigatório';
          } else if (e.toString().contains('Telefone deve ter')) {
            mensagem = 'Telefone deve ter pelo menos 10 dígitos';
          } else if (e.toString().contains('TimeoutException')) {
            mensagem = 'Operação demorou muito. Tente novamente.';
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
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

  Widget _buildCampo({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
  }) {
    const rosaTexto = Color(0xFF8A4B57);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label == 'Observações' ? '$label (opcional)' : label,
          hintText: 'Digite $label',
          prefixIcon: icon != null
              ? Icon(icon, color: rosaTexto)
              : const Icon(Icons.favorite_border, color: rosaTexto),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: rosaTexto, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        validator: (value) {
          // Campo obrigatório apenas para Nome e Telefone
          if (label == 'Nome' || label == 'Telefone') {
            if (value == null || value.trim().isEmpty) {
              return 'Preencha o campo $label';
            }
          }

          // Validação específica para telefone
          if (label == 'Telefone') {
            final digitsOnly = value!.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly.length < 10) {
              return 'Telefone deve ter pelo menos 10 dígitos';
            }
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rosaTexto = Color(0xFF8A4B57);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaTexto,
        title: Text(
          clienteEdicao != null ? 'Editar Cliente' : 'Cadastro de Cliente',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              _buildCampo(label: 'Nome', controller: nomeController, icon: Icons.person),
              const SizedBox(height: 8),
              _buildCampo(
                label: 'Telefone',
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneFormatter()],
                icon: Icons.phone,
              ),
              const SizedBox(height: 8),
              _buildCampo(
                label: 'Observações',
                controller: observacoesController,
                maxLines: 3,
                icon: Icons.note_alt,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvando ? null : _salvarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosaTexto,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _salvando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Salvando...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        clienteEdicao != null ? 'Salvar Alterações' : 'Salvar',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
