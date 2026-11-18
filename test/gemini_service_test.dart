import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mathspark/services/gemini_service.dart';

/// Mock HTTP Client untuk menguji respons Gemini API
class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final httpRequest = request as http.Request;
    final response = await handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('GeminiService Tests', () {
    test('Mengembalikan pesan ramah jika GEMINI_API_KEY belum disetel', () async {
      final service = GeminiService(
        apiKey: '', // Empty key
      );

      final result = await service.sendSocraticChat([], 'Apa itu logika proposisi?');
      expect(result, contains('GEMINI_API_KEY'));
      expect(result, contains('belum dikonfigurasi'));
    });

    test('sendSocraticChat mengirimkan request dengan format REST yang tepat dan systemInstruction', () async {
      http.Request? capturedRequest;

      final mockClient = MockHttpClient((request) async {
        capturedRequest = request;
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Bagus sekali pertanyaanmu! Sebelum kita lanjut, tahukah kamu apa perbedaan proposisi dengan kalimat tanya biasa?'
                  }
                ],
                'role': 'model'
              },
              'finishReason': 'STOP'
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final service = GeminiService(
        client: mockClient,
        apiKey: 'test-api-key-123',
        model: 'gemini-3.5-flash-lite',
      );

      final history = [
        {'role': 'user', 'content': 'Halo kak!'},
        {'role': 'model', 'content': 'Halo! Siap belajar matematika hari ini?'},
      ];

      final responseText = await service.sendSocraticChat(
        history,
        'Bagaimana cara membuktikan tautologi p v ~p?',
      );

      expect(responseText, contains('Bagus sekali pertanyaanmu!'));
      expect(capturedRequest, isNotNull);

      // Verifikasi URL & model
      expect(capturedRequest!.url.toString(), contains('gemini-3.5-flash-lite:generateContent'));
      expect(capturedRequest!.url.queryParameters['key'], 'test-api-key-123');

      // Verifikasi body payload
      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body.containsKey('systemInstruction'), isTrue);

      final sysText = body['systemInstruction']['parts'][0]['text'] as String;
      expect(sysText, contains('Tutor AI Sokratik'));
      expect(sysText, contains('DILARANG KERAS'));
      expect(sysText, contains('PPLG'));

      final contents = body['contents'] as List;
      expect(contents.isNotEmpty, isTrue);

      // Pesan user terakhir harus ada
      final lastMsg = contents.last;
      expect(lastMsg['role'], 'user');
      expect(
        (lastMsg['parts'] as List).any((p) => p['text'].toString().contains('tautologi')),
        isTrue,
      );
    });

    test('evaluateQuizResult langsung mengembalikan ucapan selamat jika detailJawabanSalah kosong', () async {
      final service = GeminiService(apiKey: 'dummy-key');

      final result = await service.evaluateQuizResult('Logika Proposisi', []);
      expect(result, contains('Luar biasa!'));
      expect(result, contains('100%'));
      expect(result, contains('Logika Proposisi'));
    });

    test('evaluateQuizResult mengirimkan ringkasan soal salah dan mengembalikan evaluasi AI', () async {
      http.Request? capturedRequest;

      final mockClient = MockHttpClient((request) async {
        capturedRequest = request;
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': '### Evaluasi Kuis\n1. Pada soal negasi, perhatikan bahwa negasi membalik nilai kebenaran, mirip operator `!` di JavaScript atau PHP.'
                  }
                ],
                'role': 'model'
              },
              'finishReason': 'STOP'
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = GeminiService(
        client: mockClient,
        apiKey: 'test-api-key-456',
      );

      final detailJawabanSalah = [
        {
          'pertanyaan': 'Jika p bernilai Benar, maka nilai dari ~p adalah...',
          'opsiJawaban': ['Benar', 'Salah', 'Bisa Benar atau Salah', 'Tidak Terdefinisi'],
          'jawabanSiswa': 0, // Siswa menjawab 0 (Benar)
          'kunciJawaban': 1, // Kunci yang benar 1 (Salah)
        }
      ];

      final responseText = await service.evaluateQuizResult(
        'Logika Matematika SMK',
        detailJawabanSalah,
      );

      expect(responseText, contains('Evaluasi Kuis'));
      expect(responseText, contains('operator `!`'));
      expect(capturedRequest, isNotNull);

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      final userPrompt = body['contents'][0]['parts'][0]['text'] as String;

      expect(userPrompt, contains('Logika Matematika SMK'));
      expect(userPrompt, contains('Jika p bernilai Benar'));
      expect(userPrompt, contains('**Pilihan Siswa (Salah):** A. Benar'));
      expect(userPrompt, contains('**Kunci Jawaban Seharusnya:** B. Salah'));
    });

    test('Menangani TimeoutException dengan pesan ramah bahasa Indonesia', () async {
      final mockClient = MockHttpClient((request) async {
        throw TimeoutException('Request timed out');
      });

      final service = GeminiService(
        client: mockClient,
        apiKey: 'test-key',
      );

      final result = await service.sendSocraticChat([], 'Hitung turunan fungsi ini');
      expect(result, contains('Waktu permintaan habis (timeout)'));
    });

    test('Menangani SocketException dengan pesan ramah bahasa Indonesia', () async {
      final mockClient = MockHttpClient((request) async {
        throw const SocketException('No Internet connection');
      });

      final service = GeminiService(
        client: mockClient,
        apiKey: 'test-key',
      );

      final result = await service.sendSocraticChat([], 'Tolong bantu soal matriks');
      expect(result, contains('Gagal terhubung ke internet'));
    });

    test('Menangani HTTP 429 Rate Limit dengan pesan ramah', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('{"error": {"code": 429, "message": "Resource exhausted"}}', 429);
      });

      final service = GeminiService(
        client: mockClient,
        apiKey: 'test-key',
      );

      final result = await service.sendSocraticChat([], 'Halo!');
      expect(result, contains('Batas permintaan (rate limit)'));
    });

    test('Menangani HTTP 401 / 403 API Key Invalid dengan pesan ramah', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('{"error": {"code": 401, "message": "API key not valid"}}', 401);
      });

      final service = GeminiService(
        client: mockClient,
        apiKey: 'invalid-key',
      );

      final result = await service.sendSocraticChat([], 'Halo!');
      expect(result, contains('Autentikasi API Key Gemini gagal'));
    });
  });
}
