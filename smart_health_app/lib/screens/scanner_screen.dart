import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _handledBarcode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlaç Barkodu Oku')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handledBarcode) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final value = barcode.rawValue;
            if (value == null || value.isEmpty) continue;
            _handledBarcode = true;
            debugPrint('Barkod bulundu: $value');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Barkod okundu: $value')),
            );
            Navigator.pop(context, value);
            break;
          }
        },
      ),
    );
  }
}
