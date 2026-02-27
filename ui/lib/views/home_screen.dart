import 'package:flutter/material.dart';
import '../services/stress_engine.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controlInput = TextEditingController();
  final _treatmentInput = TextEditingController();
  double? _originalEffect;
  double? _failureRate;
  bool _isRunning = false;
  String? _error;

  @override
  void dispose() {
    _controlInput.dispose();
    _treatmentInput.dispose();
    super.dispose();
  }

  List<double>? _parse(String text) {
    final parts = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return null;
    try {
      return parts.map(double.parse).toList();
    } catch (_) {
      return null;
    }
  }

  void _run() {
    final control = _parse(_controlInput.text);
    final treatment = _parse(_treatmentInput.text);

    if (control == null || treatment == null) {
      setState(() => _error = 'Enter comma-separated numbers in both fields.');
      return;
    }

    setState(() {
      _error = null;
      _isRunning = true;
    });

    // Run after frame so the loading state renders
    Future.microtask(() {
      final result = StressEngine().run(control, treatment);
      setState(() {
        _originalEffect = result.originalEffect;
        _failureRate = result.failureRate;
        _isRunning = false;
      });
    });
  }

  String _advisory(double rate) {
    if (rate > 0.5) return 'Claim is highly sensitive.';
    if (rate > 0.2) return 'Claim is moderately sensitive.';
    if (rate > 0.05) return 'Claim shows some sensitivity.';
    return 'Claim withstands perturbation.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Claim Stress Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controlInput,
              decoration: const InputDecoration(
                labelText: 'Control values',
                hintText: '1.2, 1.5, 1.1, 1.4, ...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _treatmentInput,
              decoration: const InputDecoration(
                labelText: 'Treatment values',
                hintText: '1.8, 2.1, 1.9, 2.0, ...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _isRunning ? null : _run,
              child: _isRunning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Stress Test'),
            ),
            if (_originalEffect != null && _failureRate != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Original Effect: ${_originalEffect!.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Failure Rate: ${(_failureRate! * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                _advisory(_failureRate!),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
