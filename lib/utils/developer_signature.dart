import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeveloperSignature extends StatefulWidget {
  const DeveloperSignature({super.key});

  @override
  State<DeveloperSignature> createState() => _DeveloperSignatureState();
}

class _DeveloperSignatureState extends State<DeveloperSignature> {
  String _versao = '';

  @override
  void initState() {
    super.initState();
    _carregarVersao();
  }

  Future<void> _carregarVersao() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _versao = 'v${info.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Developed by josecarlosleite',
            style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
          Text(_versao, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
