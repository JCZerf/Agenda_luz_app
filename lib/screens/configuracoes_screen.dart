import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../utils/app_colors.dart';
import 'notifications_screen.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final BackupService _backupService = BackupService();
  bool _carregandoBackup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rosaClaro,
      appBar: AppBar(
        backgroundColor: AppColors.rosaPrincipal,
        title: const Text(
          'Configuracoes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecaoBackup(),
            const SizedBox(height: 20),
            _buildSecaoNotificacoes(),
            const SizedBox(height: 20),
            _buildSecaoSobre(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoBackup() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: AppColors.textoEscuro, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Backup dos Dados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Proteja seus dados criando backups e restaure quando necessário.',
              style: TextStyle(
                color: AppColors.rosaTextoComOpacidade(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildBotaoBackup(),
            const SizedBox(height: 12),
            _buildBotaoRestaurar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoBackup() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _carregandoBackup ? null : _fazerBackupManual,
        icon: _carregandoBackup
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.share),
        label: Text(_carregandoBackup ? 'Criando backup...' : 'Criar Backup'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rosaPrincipal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildBotaoRestaurar() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _carregandoBackup ? null : _selecionarArquivoBackup,
        icon: const Icon(Icons.restore),
        label: const Text('Restaurar Backup'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textoEscuro,
          side: BorderSide(color: AppColors.textoEscuro),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSecaoNotificacoes() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: AppColors.textoEscuro, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Notificacoes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Gerencie suas notificacoes de atendimentos.',
              style: TextStyle(
                color: AppColors.rosaTextoComOpacidade(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Gerenciar Notificacoes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rosaPrincipalComOpacidade(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoSobre() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textoEscuro, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sobre o App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Versao: 1.4.2+17', style: TextStyle(color: AppColors.textoEscuro)),
            Text('Desenvolvido por: JCZerf', style: TextStyle(color: AppColors.textoEscuro)),
          ],
        ),
      ),
    );
  }

  Future<void> _fazerBackupManual() async {
    setState(() => _carregandoBackup = true);
    
    try {
      final sucesso = await _backupService.fazerBackupManual(context);
      if (sucesso) {
        _mostrarMensagem('Backup criado com sucesso!');
      }
    } finally {
      setState(() => _carregandoBackup = false);
    }
  }

  Future<void> _selecionarArquivoBackup() async {
    // Listar backups disponíveis
    final backups = await _backupService.listarBackupsLocais();
    
    if (backups.isEmpty) {
      // Se não há backups locais, mostrar diálogo para inserir caminho
      _mostrarDialogoSelecaoManual();
    } else {
      // Mostrar lista de backups disponíveis
      _mostrarDialogoSelecaoBackup(backups);
    }
  }
  
  Future<void> _mostrarDialogoSelecaoBackup(List<Map<String, dynamic>> backups) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Backups encontrados:'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    final dataModificacao = backup['dataModificacao'] as DateTime;
                    final tamanho = backup['tamanho'] as int;
                    final tamanhoKB = (tamanho / 1024).toStringAsFixed(1);
                    
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.backup),
                        title: Text(
                          backup['nome'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(dataModificacao)} • $tamanhoKB KB',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _restaurarBackupSelecionado(backup['caminho']);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _mostrarDialogoSelecaoManual();
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Selecionar outro arquivo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _restaurarBackupSelecionado(String caminhoArquivo) async {
    setState(() => _carregandoBackup = true);
    
    try {
      final sucesso = await _backupService.restaurarBackup(context, caminhoArquivo);
      if (sucesso) {
        _mostrarMensagem('Backup restaurado com sucesso!');
      }
    } finally {
      setState(() => _carregandoBackup = false);
    }
  }
  
  Future<void> _mostrarDialogoSelecaoManual() async {
    final caminhoArquivo = await _mostrarDialogoInsercaoCaminho();
    
    if (caminhoArquivo != null && caminhoArquivo.isNotEmpty) {
      _restaurarBackupSelecionado(caminhoArquivo);
    }
  }
  
  Future<String?> _mostrarDialogoInsercaoCaminho() async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cole o caminho completo do arquivo de backup:'),
            const SizedBox(height: 8),
            const Text(
              'Exemplo: /storage/emulated/0/Download/agendaluz_backup_20250801_143500.json',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Caminho do arquivo',
                hintText: '/caminho/para/o/arquivo.json',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Dica:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use um gerenciador de arquivos para encontrar o arquivo de backup que você compartilhou anteriormente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final caminho = controller.text.trim();
              Navigator.of(context).pop(caminho);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rosaPrincipal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.rosaPrincipal,
      ),
    );
  }
}
