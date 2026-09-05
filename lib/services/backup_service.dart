import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<bool> fazerBackupAutomatico() async {
    try {
      final dadosBackup = await _coletarDadosCompletos();
      final arquivo = await _salvarBackupLocal(dadosBackup, 'backup_automatico');
      return arquivo != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> fazerBackupManual(BuildContext context) async {
    try {
      final dadosBackup = await _coletarDadosCompletos();
      File? arquivo = await _salvarBackupLocal(dadosBackup, 'backup_manual');

      if (!context.mounted) return arquivo != null;
      if (arquivo == null) {
        _mostrarMensagem(context, 'Erro: não foi possível criar o arquivo de backup');
        return false;
      }

      try {
        await Share.shareXFiles(
          [XFile(arquivo.path)],
          text: 'Backup AgendaLuz - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
        );

        if (context.mounted) {
          _mostrarMensagem(context, 'Backup criado e compartilhado!');
        }
        return true;
      } catch (shareError) {
        if (context.mounted) {
          _mostrarMensagem(context, 'Backup criado em: ${arquivo.path}\nMas não foi possível compartilhar');
        }
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        _mostrarMensagem(context, 'Erro ao criar backup: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> _coletarDadosCompletos() async {
    final db = await _databaseHelper.db;
    final info = await PackageInfo.fromPlatform();

    final clientes = await db.query('clientes');
    final atendimentos = await db.query('atendimentos');
    final movimentacoes = await db.query('movimentacoes_financeiras');
    final servicos = await db.query('servicos');

    return {
      'versao_backup': '2.0',
      'data_backup': DateTime.now().toIso8601String(),
      'app_version': '${info.version}+${info.buildNumber}',
      'dados': {
        'clientes': clientes,
        'atendimentos': atendimentos,
        'movimentacoes_financeiras': movimentacoes,
        'servicos': servicos,
      }
    };
  }

  Future<File?> _salvarBackupLocal(Map<String, dynamic> dados, String tipo) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final nomeArquivo = 'agendaluz_${tipo}_$timestamp.json';
    
    String jsonString;
    try {
      jsonString = jsonEncode(dados);
    } catch (e) {
      return null;
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final arquivo = File('${directory.path}/$nomeArquivo');
      await arquivo.writeAsString(jsonString);
      
      if (await arquivo.exists()) {
        return arquivo;
      }
    } catch (e) {
      // tenta o fallback abaixo
    }
    
    try {
      final directory = await getTemporaryDirectory();
      final arquivo = File('${directory.path}/$nomeArquivo');
      await arquivo.writeAsString(jsonString);
      
      if (await arquivo.exists()) {
        return arquivo;
      }
    } catch (e) {
      // sem diretório gravável disponível
    }
    
    return null;
  }

  Future<List<Map<String, dynamic>>> listarBackupsLocais() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final arquivos = directory.listSync()
          .where((item) => item is File && item.path.contains('agendaluz_') && item.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      List<Map<String, dynamic>> backups = [];
      
      for (var arquivo in arquivos) {
        try {
          final stat = await arquivo.stat();
          final nomeArquivo = arquivo.path.split('/').last;
          
          DateTime? dataBackup;
          final regex = RegExp(r'(\d{8}_\d{6})');
          final match = regex.firstMatch(nomeArquivo);
          if (match != null) {
            final timestamp = match.group(1)!;
            final ano = int.parse(timestamp.substring(0, 4));
            final mes = int.parse(timestamp.substring(4, 6));
            final dia = int.parse(timestamp.substring(6, 8));
            final hora = int.parse(timestamp.substring(9, 11));
            final minuto = int.parse(timestamp.substring(11, 13));
            final segundo = int.parse(timestamp.substring(13, 15));
            dataBackup = DateTime(ano, mes, dia, hora, minuto, segundo);
          }
          
          backups.add({
            'nome': nomeArquivo,
            'caminho': arquivo.path,
            'tamanho': stat.size,
            'dataModificacao': stat.modified,
            'dataBackup': dataBackup,
          });
        } catch (e) {
          // ignora arquivo corrompido/ilegível
        }
      }
      
      backups.sort((a, b) => (b['dataModificacao'] as DateTime).compareTo(a['dataModificacao'] as DateTime));
      
      return backups;
    } catch (e) {
      return [];
    }
  }

  Future<bool> escolherERestaurarBackup(BuildContext context) async {
    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (resultado == null || resultado.files.single.path == null) {
        return false;
      }

      if (!context.mounted) return false;
      final caminhoArquivo = resultado.files.single.path!;
      return restaurarBackup(context, caminhoArquivo);
    } catch (e) {
      if (context.mounted) {
        _mostrarMensagem(context, 'Erro ao selecionar arquivo: $e');
      }
      return false;
    }
  }

  Future<bool> restaurarBackup(BuildContext context, String caminhoArquivo) async {
    try {
      final arquivo = File(caminhoArquivo);
      if (!await arquivo.exists()) {
        if (context.mounted) {
          _mostrarMensagem(context, 'Arquivo de backup não encontrado!');
        }
        return false;
      }

      final conteudo = await arquivo.readAsString();
      final dadosBackup = jsonDecode(conteudo);

      if (!_validarEstruturalBackup(dadosBackup)) {
        if (context.mounted) {
          _mostrarMensagem(context, 'Arquivo de backup inválido!');
        }
        return false;
      }

      if (!context.mounted) return false;
      bool? confirmar = await _confirmarRestauracao(context, dadosBackup);
      if (confirmar != true) {
        if (context.mounted) {
          _mostrarMensagem(context, 'Restauração cancelada pelo usuário');
        }
        return false;
      }

      await fazerBackupAutomatico();
      await _restaurarDados(dadosBackup['dados']);

      if (context.mounted) {
        _mostrarMensagem(context, 'Backup restaurado com sucesso!');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        _mostrarMensagem(context, 'Erro ao restaurar backup: $e');
      }
      return false;
    }
  }
  
  bool _validarEstruturalBackup(Map<String, dynamic> dados) {
    try {
      if (!dados.containsKey('versao_backup') || 
          !dados.containsKey('data_backup') || 
          !dados.containsKey('dados')) {
        return false;
      }
      
      final dadosTabelas = dados['dados'];
      if (dadosTabelas == null || dadosTabelas is! Map<String, dynamic>) {
        return false;
      }
      
      final tabelasObrigatorias = ['clientes', 'atendimentos', 'movimentacoes_financeiras', 'servicos'];
      for (final tabela in tabelasObrigatorias) {
        if (dadosTabelas.containsKey(tabela) && dadosTabelas[tabela] is! List) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool?> _confirmarRestauracao(BuildContext context, Map<String, dynamic> dadosBackup) async {
    final dados = dadosBackup['dados'] as Map<String, dynamic>;
    final totalClientes = (dados['clientes'] as List).length;
    final totalAtendimentos = (dados['atendimentos'] as List).length;
    final dataBackup = DateTime.parse(dadosBackup['data_backup']);
    
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Restauração'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️ ATENÇÃO: Esta ação irá substituir todos os dados atuais!'),
              const SizedBox(height: 16),
              const Text('Dados do backup:'),
              Text('• Data: ${DateFormat('dd/MM/yyyy HH:mm').format(dataBackup)}'),
              Text('• Clientes: $totalClientes'),
              Text('• Atendimentos: $totalAtendimentos'),
              const SizedBox(height: 16),
              const Text('Um backup dos dados atuais será feito automaticamente antes da restauração.'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _restaurarDados(Map<String, dynamic> dados) async {
    final db = await _databaseHelper.db;

    // PRAGMA precisa ser executado fora da transação para ter efeito.
    await db.execute('PRAGMA foreign_keys = OFF');

    try {
      // Envolve tudo em uma transação: se qualquer inserção falhar,
      // as exclusões e inserções já feitas são revertidas automaticamente,
      // evitando deixar o banco com dados apagados pela metade.
      await db.transaction((txn) async {
        await txn.delete('movimentacoes_financeiras');
        await txn.delete('atendimentos');
        await txn.delete('servicos');
        await txn.delete('clientes');

        if (dados.containsKey('clientes')) {
          final clientes = dados['clientes'] as List;
          for (var cliente in clientes) {
            await txn.insert('clientes', cliente as Map<String, dynamic>);
          }
        }

        if (dados.containsKey('servicos')) {
          final servicos = dados['servicos'] as List;
          for (var servico in servicos) {
            await txn.insert('servicos', servico as Map<String, dynamic>);
          }
        }

        if (dados.containsKey('atendimentos')) {
          final atendimentos = dados['atendimentos'] as List;
          for (var atendimento in atendimentos) {
            await txn.insert('atendimentos', atendimento as Map<String, dynamic>);
          }
        }

        if (dados.containsKey('movimentacoes_financeiras')) {
          final movimentacoes = dados['movimentacoes_financeiras'] as List;
          for (var movimentacao in movimentacoes) {
            await txn.insert('movimentacoes_financeiras', movimentacao as Map<String, dynamic>);
          }
        }
      });
    } catch (e) {
      rethrow;
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
