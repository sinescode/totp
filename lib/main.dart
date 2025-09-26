import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initial generation (if secret exists)
    _generateTotp();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final seconds = now.second;
      final rem = 30 - (seconds % 30);
      // If new interval (mod == 0) regenerate immediately
      if (seconds % 30 == 0) {
        _generateTotp();
      }
      setState(() {
        _remainingSeconds = rem == 0 ? 30 : rem;
      });
    });
  }

  void _generateTotp() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _totpCode = null);
      return;
    }

    try {
      final secret = base32Decode(text);
      final code = generateTOTP(secret, DateTime.now().millisecondsSinceEpoch,
          interval: 30, digits: 6);
      setState(() => _totpCode = code);
    } catch (e) {
      setState(() => _totpCode = "Invalid Secret");
    }
  }

  Future<void> _pasteFromClipboard() async {
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
                hintText: "Enter or paste secret key (Base32)",
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

/// ---------------------
/// TOTP + helpers (pure Dart)
/// ---------------------

/// Generate TOTP given a secret (raw bytes), timestamp in milliseconds.
String generateTOTP(Uint8List secret, int timestampMillis,
    {int interval = 30, int digits = 6}) {
  final counter = (timestampMillis / 1000 ~/ interval);
  final counterBytes = _intTo8Bytes(counter);
  final hmac = _hmacSha1(secret, counterBytes);
  // dynamic truncation
  final offset = hmac[hmac.length - 1] & 0x0f;
  final binary = ((hmac[offset] & 0x7f) << 24) |
      ((hmac[offset + 1] & 0xff) << 16) |
      ((hmac[offset + 2] & 0xff) << 8) |
      (hmac[offset + 3] & 0xff);
  final otp = binary % pow10(digits);
  return otp.toString().padLeft(digits, '0');
}

int pow10(int digits) {
  var v = 1;
  for (var i = 0; i < digits; i++) v *= 10;
  return v;
}

Uint8List _intTo8Bytes(int v) {
  final bytes = ByteData(8);
  bytes.setUint64(0, v, Endian.big);
  return bytes.buffer.asUint8List();
}

/// HMAC-SHA1 using our SHA1 implementation
Uint8List _hmacSha1(Uint8List key, Uint8List message) {
  const blockSize = 64;
  Uint8List keyPadded;
  if (key.length > blockSize) {
    keyPadded = _sha1(key);
    if (keyPadded.length < blockSize) {
      final tmp = Uint8List(blockSize);
      tmp.setRange(0, keyPadded.length, keyPadded);
      keyPadded = tmp;
    }
  } else if (key.length < blockSize) {
    final tmp = Uint8List(blockSize);
    tmp.setRange(0, key.length, key);
    keyPadded = tmp;
  } else {
    keyPadded = Uint8List.fromList(key);
  }

  final oKeyPad = Uint8List(blockSize);
  final iKeyPad = Uint8List(blockSize);
  for (var i = 0; i < blockSize; i++) {
    oKeyPad[i] = keyPadded[i] ^ 0x5c;
    iKeyPad[i] = keyPadded[i] ^ 0x36;
  }

  final inner = _sha1(Uint8List.fromList(iKeyPad + message));
  final finalHash = _sha1(Uint8List.fromList(oKeyPad + inner));
  return finalHash;
}

/// Pure-Dart SHA-1 implementation returning 20 bytes
Uint8List _sha1(List<int> data) {
  // preprocess
  final bytes = Uint8List.fromList(data);
  final ml = bytes.lengthInBytes * 8;
  // append 0x80 then pad zeros until length % 512 == 448
  final padded = BytesBuilder();
  padded.add(bytes);
  padded.addByte(0x80);
  // pad with zeros
  while (((padded.length + 8) * 8) % 512 != 0) {
    padded.addByte(0);
  }
  // append 64-bit big-endian length
  final lenBytes = ByteData(8)..setUint64(0, ml, Endian.big);
  padded.add(lenBytes.buffer.asUint8List());

  final chunked = padded.toBytes();
  // initial hash values
  int h0 = 0x67452301;
  int h1 = 0xEFCDAB89;
  int h2 = 0x98BADCFE;
  int h3 = 0x10325476;
  int h4 = 0xC3D2E1F0;

  // process each 512-bit chunk
  final chunks = chunked.length ~/ 64;
  final w = List<int>.filled(80, 0);
  for (var i = 0; i < chunks; i++) {
    final base = i * 64;
    // break chunk into sixteen 32-bit big-endian words w[0..15]
    for (var t = 0; t < 16; t++) {
      final j = base + t * 4;
      w[t] = ((chunked[j] & 0xff) << 24) |
          ((chunked[j + 1] & 0xff) << 16) |
          ((chunked[j + 2] & 0xff) << 8) |
          (chunked[j + 3] & 0xff);
    }
    // Extend the sixteen 32-bit words into eighty words
    for (var t = 16; t < 80; t++) {
      w[t] = _rotl32(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1);
    }

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;

    for (var t = 0; t < 80; t++) {
      int f, k;
      if (t < 20) {
        f = (b & c) | ((~b) & d);
        k = 0x5A827999;
      } else if (t < 40) {
        f = b ^ c ^ d;
        k = 0x6ED9EBA1;
      } else if (t < 60) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8F1BBCDC;
      } else {
        f = b ^ c ^ d;
        k = 0xCA62C1D6;
      }
      final temp =
          (_rotl32(a, 5) + f + e + k + (w[t] & 0xffffffff)) & 0xffffffff;
      e = d;
      d = c;
      c = _rotl32(b, 30);
      b = a;
      a = temp;
    }
    h0 = (h0 + a) & 0xffffffff;
    h1 = (h1 + b) & 0xffffffff;
    h2 = (h2 + c) & 0xffffffff;
    h3 = (h3 + d) & 0xffffffff;
    h4 = (h4 + e) & 0xffffffff;
  }

  final out = ByteData(20);
  out.setUint32(0, h0, Endian.big);
  out.setUint32(4, h1, Endian.big);
  out.setUint32(8, h2, Endian.big);
  out.setUint32(12, h3, Endian.big);
  out.setUint32(16, h4, Endian.big);
  return out.buffer.asUint8List();
}

int _rotl32(int value, int bits) {
  return ((value << bits) | ((value & 0xffffffff) >> (32 - bits))) & 0xffffffff;
}

/// Base32 decode supporting spaces and lowercase/uppercase.
/// Throws FormatException on invalid input.
Uint8List base32Decode(String input) {
  final normalized = input.replaceAll(RegExp(r'[\s=]+'), '').toUpperCase();
  if (normalized.isEmpty) return Uint8List(0);
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final buffer = <int>[];
  int bits = 0;
  int value = 0;
  for (var i = 0; i < normalized.length; i++) {
    final ch = normalized[i];
    final idx = alphabet.indexOf(ch);
    if (idx < 0) {
      throw FormatException('Invalid Base32 character: $ch');
    }
    value = (value << 5) | idx;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      buffer.add((value >> bits) & 0xFF);
    }
  }
  return Uint8List.fromList(buffer);
}
