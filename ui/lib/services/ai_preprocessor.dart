import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiPreprocessor {
  final String apiKey;

  AiPreprocessor(this.apiKey);

  Future<({List<double> control, List<double> treatment})> interpret(
      String rawContent) async {
    debugPrint('[AiPreprocessor] Sending raw content (${rawContent.length} chars) to OpenAI');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a data analysis assistant. You receive raw tabular data. '
                    'Your job is to extract per-subject numeric outcome values for a control group and a treatment group.\n\n'
                    'Rules:\n'
                    '1. Identify which column splits subjects into control vs treatment.\n'
                    '2. Identify the primary numeric endpoint. If there are baseline and endpoint columns for the same measure (e.g. tumor_size_baseline and tumor_size_endpoint), compute the per-subject IMPROVEMENT as: baseline minus endpoint. A positive number means improvement.\n'
                    '3. If there is only one outcome column (no baseline), use those values directly.\n'
                    '4. Always orient values so HIGHER = BETTER for the treatment group.\n\n'
                    'Example: if baseline=28.3 and endpoint=31.2, improvement = 28.3 - 31.2 = -2.9 (got worse).\n'
                    'If baseline=27.8 and endpoint=22.1, improvement = 27.8 - 22.1 = 5.7 (got better).\n\n'
                    'Respond with JSON only: {"controlValues": [numbers], "treatmentValues": [numbers]}',
          },
          {
            'role': 'user',
            'content': rawContent,
          },
        ],
      }),
    );

    debugPrint('[AiPreprocessor] Response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('[AiPreprocessor] ERROR body: ${response.body}');
      throw Exception(
          'OpenAI API error (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    debugPrint('[AiPreprocessor] Raw AI response: $content');
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    final rawControl = parsed['controlValues'] as List<dynamic>?;
    final rawTreatment = parsed['treatmentValues'] as List<dynamic>?;

    if (rawControl == null || rawTreatment == null) {
      throw Exception('AI returned incomplete data.');
    }

    final control = rawControl.map((v) => (v as num).toDouble()).toList();
    final treatment = rawTreatment.map((v) => (v as num).toDouble()).toList();

    debugPrint('[AiPreprocessor] Extracted ${control.length} control, ${treatment.length} treatment values');

    return (control: control, treatment: treatment);
  }
}
