import 'package:flutter/material.dart';

class DeveloperSignature extends StatelessWidget {
  const DeveloperSignature({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Text(
          'Developed by josecarlosleite',
          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
