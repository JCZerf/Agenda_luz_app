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
      print('Erro no backup automatico: $e');
      return false;
    }
  }

  // Fazer backup manual e compartilhar
  Future<bool> fazerBackupManual(BuildContext context) async {
    try {
      print('=== INICIANDO BACKUP MANUAL ===');
      
      // Teste 1: Verificar se consegue coletar dados
      final dadosBackup = await _coletarDadosCompletos();
      final totalClientes = dadosBackup['dados']['clientes'].length;
      final totalAtendimentos = dadosBackup['dados']['atendimentos'].length;
      print('✅ Dados coletados: $totalClientes clientes, $totalAtendimentos atendimentos');
      
      // Teste 2: Verificar se consegue acessar diretórios
      try {
        final directory = await getApplicationDocumentsDirectory();
        print('✅ Diretório documentos: ${directory.path}');
      } catch (e) {
        print('❌ Erro ao acessar diretório documentos: $e');
      }
      
      try {
        final tempDir = await getTemporaryDirectory();
        print('✅ Diretório temporário: ${tempDir.path}');
      } catch (e) {
        print('❌ Erro ao acessar diretório temporário: $e');
      }
      
      // Teste 3: Criar backup usando método simples
      File? arquivo = await _salvarBackupSimples(dadosBackup, 'backup_manual');
      
      if (arquivo != null) {
        print('✅ Arquivo criado: ${arquivo.path}');
        
        // Teste 4: Verificar se o Share funciona
        try {
          final resultado = await Share.shareXFiles([XFile(arquivo.path)], 
            text: 'Backup AgendaLuz - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
          
          print('✅ Compartilhamento: $resultado');
          _mostrarMensagem(context, 'Backup criado e compartilhado! 🎉');
          return true;
        } catch (shareError) {
          print('❌ Erro no compartilhamento: $shareError');
          _mostrarMensagem(context, 'Backup criado mas erro ao compartilhar: $shareError');
          return false;
        }
      } else {
        print('❌ FALHA: Não foi possível criar arquivo');
        _mostrarMensagem(context, 'Erro: não foi possível criar o arquivo de backup');
        return false;
      }
    } catch (e) {
      print('❌ ERRO GERAL: $e');
      _mostrarMensagem(context, 'Erro no backup: $e');
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
      'versao_backup': '1.0',
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

  // Salvar backup com método simples
  Future<File?> _salvarBackupSimples(Map<String, dynamic> dados, String tipo) async {
    try {
      print('📁 Tentando salvar backup...');
      
      // Tentar primeiro no diretório de documentos
      try {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final nomeArquivo = 'agendaluz_${tipo}_$timestamp.json';
        final arquivo = File('${directory.path}/$nomeArquivo');
        
        final jsonString = jsonEncode(dados);
        await arquivo.writeAsString(jsonString);
        
        if (await arquivo.exists()) {
          final tamanho = await arquivo.length();
          print('✅ Arquivo salvo em documentos: ${arquivo.path} ($tamanho bytes)');
          return arquivo;
        }
      } catch (e) {
        print('⚠️ Falha em documentos: $e');
      }
      
      // Se falhou, tentar no diretório temporário
      try {
        final directory = await getTemporaryDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final nomeArquivo = 'agendaluz_${tipo}_$timestamp.json';
        final arquivo = File('${directory.path}/$nomeArquivo');
        
        final jsonString = jsonEncode(dados);
        await arquivo.writeAsString(jsonString);
        
        if (await arquivo.exists()) {
          final tamanho = await arquivo.length();
          print('✅ Arquivo salvo em temp: ${arquivo.path} ($tamanho bytes)');
          return arquivo;
        }
      } catch (e) {
        print('⚠️ Falha em temp: $e');
      }
      
      print('❌ Todas as tentativas falharam');
      return null;
    } catch (e) {
      print('❌ Erro geral ao salvar: $e');
      return null;
    }
  }

  // Salvar backup localmente
  Future<File?> _salvarBackupLocal(Map<String, dynamic> dados, String tipo) async {
    try {
      print('Iniciando salvamento do backup...');
      
      final directory = await getApplicationDocumentsDirectory();
      print('Diretório: ${directory.path}');
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nomeArquivo = 'agendaluz_${tipo}_$timestamp.json';
      final arquivo = File('${directory.path}/$nomeArquivo');
      
      print('Salvando arquivo: ${arquivo.path}');
      
      final jsonString = jsonEncode(dados);
      await arquivo.writeAsString(jsonString);
      
      // Verificar se o arquivo foi criado
      if (await arquivo.exists()) {
        final tamanho = await arquivo.length();
        print('Arquivo criado com sucesso! Tamanho: $tamanho bytes');
        return arquivo;
      } else {
        print('Erro: arquivo não foi criado');
        return null;
      }
    } catch (e) {
      print('Erro ao salvar backup: $e');
      return null;
    }
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
          print('Erro ao processar arquivo ${arquivo.path}: $e');
        }
      }
      
      // Ordenar por data de modificação (mais recente primeiro)
      backups.sort((a, b) => (b['dataModificacao'] as DateTime).compareTo(a['dataModificacao'] as DateTime));
      
      return backups;
    } catch (e) {
      print('Erro ao listar backups: $e');
      return [];
    }
  }

  // Restaurar backup de um arquivo
  Future<bool> restaurarBackup(BuildContext context, String caminhoArquivo) async {
    try {
      print('=== INICIANDO RESTAURAÇÃO ===');
      print('Arquivo: $caminhoArquivo');
      
      // Verificar se o arquivo existe
      final arquivo = File(caminhoArquivo);
      if (!await arquivo.exists()) {
        _mostrarMensagem(context, 'Arquivo de backup não encontrado!');
        return false;
      }
      
      // Ler o conteúdo do arquivo
      final conteudo = await arquivo.readAsString();
      final dadosBackup = jsonDecode(conteudo);
      
      // Validar estrutura do backup
      if (!_validarEstruturalBackup(dadosBackup)) {
        _mostrarMensagem(context, 'Arquivo de backup inválido!');
        return false;
      }
      
      // Confirmar com o usuário antes de restaurar
      bool? confirmar = await _confirmarRestauracao(context, dadosBackup);
      if (confirmar != true) {
        _mostrarMensagem(context, 'Restauração cancelada pelo usuário');
        return false;
      }
      
      // Fazer backup atual antes de restaurar (segurança)
      await fazerBackupAutomatico();
      
      // Restaurar dados
      await _restaurarDados(dadosBackup['dados']);
      
      _mostrarMensagem(context, 'Backup restaurado com sucesso! 🎉');
      return true;
      
    } catch (e) {
      print('❌ Erro na restauração: $e');
      _mostrarMensagem(context, 'Erro ao restaurar backup: $e');
      return false;
    }
  }
  
  // Validar estrutura do backup
  bool _validarEstruturalBackup(Map<String, dynamic> dados) {
    try {
      // Verificar campos obrigatórios
      if (!dados.containsKey('versao_backup') || 
          !dados.containsKey('data_backup') || 
          !dados.containsKey('dados')) {
        print('❌ Estrutura inválida: campos obrigatórios ausentes');
        return false;
      }
      
      final dadosTabelas = dados['dados'] as Map<String, dynamic>;
      
      // Verificar se contém as tabelas principais
      if (!dadosTabelas.containsKey('clientes')) {
        print('❌ Tabela clientes não encontrada');
        return false;
      }
      
      print('✅ Estrutura do backup válida');
      return true;
    } catch (e) {
      print('❌ Erro na validação: $e');
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
    
    print('🔄 Iniciando restauração dos dados...');
    
    // Limpar tabelas existentes
    await db.delete('movimentacoes_financeiras');
    await db.delete('atendimentos'); 
    await db.delete('servicos');
    await db.delete('clientes');
    print('✅ Tabelas limpas');
    
    // Restaurar clientes
    if (dados.containsKey('clientes')) {
      final clientes = dados['clientes'] as List;
      for (var cliente in clientes) {
        await db.insert('clientes', cliente as Map<String, dynamic>);
      }
      print('✅ Clientes restaurados: ${clientes.length}');
    }
    
    // Restaurar serviços
    if (dados.containsKey('servicos')) {
      final servicos = dados['servicos'] as List;
      for (var servico in servicos) {
        await db.insert('servicos', servico as Map<String, dynamic>);
      }
      print('✅ Serviços restaurados: ${servicos.length}');
    }
    
    // Restaurar atendimentos
    if (dados.containsKey('atendimentos')) {
      final atendimentos = dados['atendimentos'] as List;
      for (var atendimento in atendimentos) {
        await db.insert('atendimentos', atendimento as Map<String, dynamic>);
      }
      print('✅ Atendimentos restaurados: ${atendimentos.length}');
    }
    
    // Restaurar movimentações financeiras
    if (dados.containsKey('movimentacoes_financeiras')) {
      final movimentacoes = dados['movimentacoes_financeiras'] as List;
      for (var movimentacao in movimentacoes) {
        await db.insert('movimentacoes_financeiras', movimentacao as Map<String, dynamic>);
      }
      print('✅ Movimentações restauradas: ${movimentacoes.length}');
    }
    
    print('🎉 Restauração concluída!');
  }

  // Mostrar mensagem
  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
