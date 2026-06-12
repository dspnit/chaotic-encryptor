import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // برای پردازش سریع پیکسل‌ها

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const ChaoticEncryptor(),
    );
  }
}

class ChaoticEncryptor extends StatefulWidget {
  const ChaoticEncryptor({super.key});
  @override
  State<ChaoticEncryptor> createState() => _ChaoticEncryptorState();
}

class _ChaoticEncryptorState extends State<ChaoticEncryptor> {
  Uint8List? _originalBytes;
  Uint8List? _encryptedBytes;
  bool _isProcessing = false;

  // هسته متلب شما: فرمول آشوبی نگاشت خیمه (Tent Map)
  double tentMap(double x, double mu) {
    return (x < 0.5) ? mu * x : mu * (1.0 - x);
  }

  // فرآیند رمزنگاری آشوبی روی پیکسل‌های تصویر
  void _runEncryption() async {
    if (_originalBytes == null) return;
    setState(() => _isProcessing = true);

    // اجرای محاسبات در پس‌زمینه برای روان ماندن UI
    final encrypted = await Timer.run(() {
      img.Image? image = img.decodeImage(_originalBytes!);
      if (image == null) return _originalBytes;

      double x = 0.3456; // کلید اولیه ۱
      double mu = 1.9999; // کلید اولیه ۲ (پارامتر کنترل)

      List<int> pixels = image.getBytes();
      for (int i = 0; i < pixels.length; i++) {
        x = tentMap(x, mu);
        int key = (x * 255).floor() & 0xFF;
        pixels[i] = pixels[i] ^ key; // عملیات XOR آشوبی
      }
      return Uint8List.fromList(img.encodeJpg(image));
    });

    setState(() {
      _encryptedBytes = encrypted;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chaotic Image Encryptor')),
      body: Row(
        children: [
          // ستون اول: منوی کنترل و دکمه‌ها
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black26,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // شبیه‌ساز عکس کلمن یا لود دیتای فرضی برای تست اولیه
                      setState(() {
                        _originalBytes = Uint8List.fromList(List.generate(10000, (i) => i % 255));
                        _encryptedBytes = null;
                      });
                    },
                    child: const Text('Select File'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _originalBytes != null && !_isProcessing ? _runEncryption : null,
                    child: _isProcessing ? const CircularProgressIndicator() : const Text('Encrypt'),
                  ),
                ],
              ),
            ),
          ),
          // ستون دوم: نمایش تصویر اصلی
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black38,
              child: Center(
                child: _originalBytes != null
                    ? const Text('Image Loaded Successfully') // در محیط واقعی: Image.memory(_originalBytes!)
                    : const Text('No Image Selected'),
              ),
            ),
          ),
          // ستون سوم: نمایش تصویر رمزنگاری شده (آشوب نهایی)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black45,
              child: Center(
                child: _encryptedBytes != null
                    ? const Text('Encrypted (Chaos State)') // در محیط واقعی: Image.memory(_encryptedBytes!)
                    : const Text('Waiting for Encryption...'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
