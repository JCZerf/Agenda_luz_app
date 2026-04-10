import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Fazer backup automatico
  Future<bool> fazerBackupAutomatico() async {
    try {
      final dadosBackup = await _coletarDadosCompletos();
      final arquivo = await _salvarBackupLocal(dadosBackup, 'backup_automatico');
      return arquivo != null;
    } catch (e) {
      debugPrint('Erro no backup automatico: $e');
      return false;
    }
  }

  // Fazer backup manual e compartilhar
  Future<bool> fazerBackupManual(BuildContext context) async {
    try {
      final dadosBackup = await _coletarDadosCompletos();
      File? arquivo = await _salvarBackupLocal(dadosBackup, 'backup_manual');
      
      if (arquivo == null) {
        _mostrarMensagem(context, 'Erro: não foi possível criar o arquivo de backup');
        return false;
      }
      
      try {
        await Share.shareXFiles(
          [XFile(arquivo.path)], 
          text: 'Backup AgendaLuz - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
        );
        
        _mostrarMensagem(context, 'Backup criado e compartilhado!');
        return true;
      } catch (shareError) {
        _mostrarMensagem(context, 'Backup criado em: ${arquivo.path}\nMas não foi possível compartilhar');
        return true;
      }
    } catch (e) {
      _mostrarMensagem(context, 'Erro ao criar backup: $e');
      return false;
    }
  }

  // Coletar todos os dados do banco
  Future<Map<String, dynamic>> _coletarDadosCompletos() async {
    final db = await _databaseHelper.db;
    
    final clientes = await db.query('clientes');
    final atendimentos = await db.query('atendimentos');
    final movimentacoes = await db.query('movimentacoes_financeiras');
    final servicos = await db.query('servicos');

    return {
      'versao_backup': '2.0',
      'data_backup': DateTime.now().toIso8601String(),
      'app_version': '1.4.2+17',
      'dados': {
        'clientes': clientes,
        'atendimentos': atendimentos,
        'movimentacoes_financeiras': movimentacoes,
        'servicos': servicos,
      }
    };
  }

  // Salvar backup localmente com estratégia de fallback
  Future<File?> _salvarBackupLocal(Map<String, dynamic> dados, String tipo) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final nomeArquivo = 'agendaluz_${tipo}_$timestamp.json';
    
    String jsonString;
    try {
      jsonString = jsonEncode(dados);
    } catch (e) {
      debugPrint('Erro ao converter dados para JSON: $e');
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
      debugPrint('Falha ao salvar em documentos: $e');
    }
    
    try {
      final directory = await getTemporaryDirectory();
      final arquivo = File('${directory.path}/$nomeArquivo');
      await arquivo.writeAsString(jsonString);
      
      if (await arquivo.exists()) {
        return arquivo;
      }
    } catch (e) {
      debugPrint('Falha ao salvar em temp: $e');
    }
    
    return null;
  }

  // Listar backups salvos localmente
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
          
          // Tentar extrair data do nome do arquivo
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
          debugPrint('Erro ao processar arquivo ${arquivo.path}: $e');
        }
      }
      
      // Ordenar por data de modificação (mais recente primeiro)
      backups.sort((a, b) => (b['dataModificacao'] as DateTime).compareTo(a['dataModificacao'] as DateTime));
      
      return backups;
    } catch (e) {
      debugPrint('Erro ao listar backups: $e');
      return [];
    }
  }

  // Restaurar backup de um arquivo
  Future<bool> restaurarBackup(BuildContext context, String caminhoArquivo) async {
    try {
      final arquivo = File(caminhoArquivo);
      if (!await arquivo.exists()) {
        _mostrarMensagem(context, 'Arquivo de backup não encontrado!');
        return false;
      }
      
      final conteudo = await arquivo.readAsString();
      final dadosBackup = jsonDecode(conteudo);
      
      if (!_validarEstruturalBackup(dadosBackup)) {
        _mostrarMensagem(context, 'Arquivo de backup inválido!');
        return false;
      }
      
      bool? confirmar = await _confirmarRestauracao(context, dadosBackup);
      if (confirmar != true) {
        _mostrarMensagem(context, 'Restauração cancelada pelo usuário');
        return false;
      }
      
      await fazerBackupAutomatico();
      await _restaurarDados(dadosBackup['dados']);
      
      _mostrarMensagem(context, 'Backup restaurado com sucesso!');
      return true;
      
    } catch (e) {
      debugPrint('Erro na restauracao: $e');
      _mostrarMensagem(context, 'Erro ao restaurar backup: $e');
      return false;
    }
  }
  
  // Validar estrutura do backup
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
      debugPrint('Erro na validacao: $e');
      return false;
    }
  }
  
  // Confirmar restauração com o usuário
  Future<bool?> _confirmarRestauracao(BuildContext context, Map<String, dynamic> dadosBackup) async {
    final dados = dadosBackup['dados'] as Map<String, dynamic>;
    final totalClientes = (dados['clientes'] as List).length;
    final totalAtendimentos = (dados['atendimentos'] as List).length;
    final dataBackup = DateTime.parse(dadosBackup['data_backup']);
    
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Restauração'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️ ATENÇÃO: Esta ação irá substituir todos os dados atuais!'),
              SizedBox(height: 16),
              Text('Dados do backup:'),
              Text('• Data: ${DateFormat('dd/MM/yyyy HH:mm').format(dataBackup)}'),
              Text('• Clientes: $totalClientes'),
              Text('• Atendimentos: $totalAtendimentos'),
              SizedBox(height: 16),
              Text('Um backup dos dados atuais será feito automaticamente antes da restauração.'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Restaurar'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Restaurar dados no banco
  Future<void> _restaurarDados(Map<String, dynamic> dados) async {
    final db = await _databaseHelper.db;
    
    try {
      await db.execute('PRAGMA foreign_keys = OFF');
      
      await db.delete('movimentacoes_financeiras');
      await db.delete('atendimentos');
      await db.delete('servicos');
      await db.delete('clientes');
      
      if (dados.containsKey('clientes')) {
        final clientes = dados['clientes'] as List;
        for (var cliente in clientes) {
          try {
            await db.insert('clientes', cliente as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Erro ao restaurar cliente: $e');
          }
        }
      }
      
      if (dados.containsKey('servicos')) {
        final servicos = dados['servicos'] as List;
        for (var servico in servicos) {
          try {
            await db.insert('servicos', servico as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Erro ao restaurar servico: $e');
          }
        }
      }
      
      if (dados.containsKey('atendimentos')) {
        final atendimentos = dados['atendimentos'] as List;
        for (var atendimento in atendimentos) {
          try {
            await db.insert('atendimentos', atendimento as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Erro ao restaurar atendimento: $e');
          }
        }
      }
      
      if (dados.containsKey('movimentacoes_financeiras')) {
        final movimentacoes = dados['movimentacoes_financeiras'] as List;
        for (var movimentacao in movimentacoes) {
          try {
            await db.insert('movimentacoes_financeiras', movimentacao as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Erro ao restaurar movimentacao: $e');
          }
        }
      }
      
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      debugPrint('Erro durante restauracao: $e');
      
      try {
        await db.execute('PRAGMA FOREIGN_KEYS = ON');
      } catch (_) {}
      
      rethrow;
    }
  }

  // Mostrar mensagem
  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
