import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart'; 

void main() {
  runApp(const TotpApp());
}

class TotpApp extends StatelessWidget {
  const TotpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOTP Generator',
      theme: ThemeData(
        primaryColor: const Color(0xFF6B3F69),
        scaffoldBackgroundColor: const Color(0xFFDDC3C3),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFA376A2).withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const TotpHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TotpHomePage extends StatefulWidget {
  const TotpHomePage({super.key});

  @override
  State<TotpHomePage> createState() => _TotpHomePageState();
}

class _TotpHomePageState extends State<TotpHomePage> {
  final TextEditingController _controller = TextEditingController();
  String? _totpCode;
  int _remainingSeconds = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds = 30 - (DateTime.now().second % 30);
        if (_remainingSeconds == 30) {
          _generateTotp(); // Regenerate when interval resets
        }
      });
    });
  }

  void _generateTotp() {
    if (_controller.text.isNotEmpty) {
      try {
        final code = OTP.generateTOTPCodeString(
          _controller.text.trim(),
          DateTime.now().millisecondsSinceEpoch,
          interval: 30,
          length: 6,
          algorithm: Algorithm.SHA1,
          isGoogle: true, // Added for compatibility with Google Authenticator
        );
        setState(() => _totpCode = code);
      } catch (e) {
        setState(() => _totpCode = "Invalid Secret");
      }
    } else {
      setState(() => _totpCode = null);
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      setState(() {
        _controller.text = data.text ?? '';
      });
      _generateTotp();
    }
  }

  void _clearInput() {
    setState(() {
      _controller.clear();
      _totpCode = null;
    });
  }

  void _copyTotp() {
    if (_totpCode != null && _totpCode != "Invalid Secret") {
      Clipboard.setData(ClipboardData(text: _totpCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TOTP copied!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = [
      const Color(0xFF6B3F69),
      const Color(0xFF8D5F8C),
      const Color(0xFFA376A2),
      const Color(0xFFDDC3C3),
    ];

    final progressValue = _remainingSeconds / 30;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette[0],
        title: const Text("TOTP Generator"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Enter or paste secret key",
              ),
              onChanged: (_) => _generateTotp(),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette[1],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: _pasteFromClipboard,
                      child: const Text("Paste"),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette[2],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: _clearInput,
                      child: const Text("Clear"),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            if (_totpCode != null) ...[
              // Countdown timer and progress bar
              Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: progressValue,
                          backgroundColor: palette[3],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressValue > 0.2 ? palette[1] : Colors.red,
                          ),
                          strokeWidth: 4,
                        ),
                        Center(
                          child: Text(
                            _remainingSeconds.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: palette[0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Expires in $_remainingSeconds seconds",
                    style: TextStyle(
                      fontSize: 14,
                      color: palette[0],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text(
                "Your TOTP:",
                style: TextStyle(
                  fontSize: 18,
                  color: palette[0],
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                _totpCode!,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _totpCode == "Invalid Secret" ? Colors.red : palette[1],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette[0],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: _totpCode == "Invalid Secret" ? null : _copyTotp,
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy"),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}