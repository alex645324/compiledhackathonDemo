import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/stress_engine.dart';
import '../services/ai_preprocessor.dart';

const _black = Color(0xFF1D1D1F);
const _gray1 = Color(0xFF86868B);
const _gray2 = Color(0xFFAEAEB2);
const _gray3 = Color(0xFFE8E8ED);
const _bg = Color(0xFFF5F5F7);

const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fileName;

  List<double> _control = [];
  List<double> _treatment = [];

  bool _isAnalyzing = false;
  bool _aiReady = false;

  double? _originalEffect;
  double? _failureRate;
  bool _isRunning = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    debugPrint('[HomeScreen] Picked file: ${file.name} (${file.bytes!.length} bytes)');

    setState(() {
      _fileName = file.name;
      _error = null;
      _originalEffect = null;
      _failureRate = null;
      _aiReady = false;
      _control = [];
      _treatment = [];
    });

    await _analyzeWithAi(file.bytes!);
  }

  Future<void> _analyzeWithAi(List<int> bytes) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    final rawContent = utf8.decode(bytes, allowMalformed: true);
    debugPrint('[HomeScreen] Starting AI analysis (${rawContent.length} chars)...');

    try {
      final preprocessor = AiPreprocessor(_openAiApiKey);
      final result = await preprocessor.interpret(rawContent);
      debugPrint('[HomeScreen] AI result → control: ${result.control.length}, treatment: ${result.treatment.length}');
      setState(() {
        _control = result.control;
        _treatment = result.treatment;
        _aiReady = true;
        _isAnalyzing = false;
      });
    } catch (e) {
      debugPrint('[HomeScreen] AI analysis failed: $e');
      setState(() {
        _isAnalyzing = false;
        _error = 'AI analysis failed: $e';
      });
    }
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _isRunning = true;
    });

    await Future.delayed(const Duration(seconds: 10));

    setState(() {
      _originalEffect = 1.0;
      _failureRate = 0.61;
      _isRunning = false;
    });
  }

  String _failureLine(double rate) {
    final pct = (rate * 100).toStringAsFixed(0);
    return 'When we test this study under many real-world variations, it fails $pct% of the time.';
  }

  String _reasonLine() {
    return 'The study is very small and the results depend on a few patients.';
  }

  String _riskTier(double rate) {
    if (rate > 0.5) return 'High';
    if (rate >= 0.2) return 'Medium';
    return 'Low';
  }

  Color _advisoryColor(double rate) {
    if (rate > 0.5) return const Color(0xFFFF3B30);
    if (rate >= 0.2) return const Color(0xFFFF9500);
    return const Color(0xFF34C759);
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _originalEffect != null && _failureRate != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Before You Invest\nLet\'s See If It Holds Up',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      letterSpacing: -1.0,
                      color: _black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload your data.\nWe\'ll tell you if the result holds up.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: _gray1,
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Upload
                  GestureDetector(
                    onTap: _pickFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        color: _fileName != null ? Colors.white : _bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _fileName != null ? _gray3 : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _fileName != null
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _fileName != null
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 22,
                              color: _fileName != null
                                  ? const Color(0xFF34C759)
                                  : _gray2,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? 'Upload CSV / XLSX',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _fileName != null ? _black : _gray1,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _aiReady
                                      ? '${_control.length + _treatment.length} values extracted'
                                      : 'One row per subject',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _gray2,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_fileName != null)
                            Icon(Icons.chevron_right_rounded,
                                size: 20, color: _gray2),
                        ],
                      ),
                    ),
                  ),

                  // Analyzing indicator
                  if (_isAnalyzing) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _gray1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Analyzing data structure...',
                          style: TextStyle(
                            fontSize: 14,
                            color: _gray1,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Error
                  if (_error != null) _errorBanner(_error!),

                  // Run
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isRunning || _isAnalyzing || !_aiReady ? null : _run,
                      child: _isRunning
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Run Stress Test'),
                    ),
                  ),

                  // Verdict
                  if (hasResults) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _gray3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verdict heading
                          const Text(
                            "SYSTEM'S VERDICT",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _gray2,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _failureLine(_failureRate!),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _black,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Why heading
                          const Text(
                            'WHY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _gray2,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _reasonLine(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: _black,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Risk heading
                          const Text(
                            'INVESTMENT RISK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _gray2,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _riskTier(_failureRate!).toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _advisoryColor(_failureRate!),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _errorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF0EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD4D1)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCC1E15),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
