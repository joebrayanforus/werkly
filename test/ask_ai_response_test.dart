import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/data/werkly_repository.dart';

void main() {
  const unavailable = 'The AI assistant is temporarily unavailable.';
  const noResponse = 'No response was generated.';

  test('returns the reply and remaining quota on success', () {
    final (reply, remaining) = parseAskAiResponse(
      200,
      {'reply': ' Sure, here is a tip. ', 'remainingHourlyRequests': 17},
      unavailableMessage: unavailable,
      noResponseMessage: noResponse,
    );

    expect(reply, 'Sure, here is a tip.');
    expect(remaining, 17);
  });

  test('tolerates a response with no quota field', () {
    final (reply, remaining) = parseAskAiResponse(
      200,
      {'reply': 'Hello'},
      unavailableMessage: unavailable,
      noResponseMessage: noResponse,
    );

    expect(reply, 'Hello');
    expect(remaining, isNull);
  });

  test('throws AiQuotaExceededException with the backend message on 429', () {
    expect(
      () => parseAskAiResponse(
        429,
        {
          'error': 'Free limit reached. Try again in one hour.',
          'retryAfterSeconds': 3600,
        },
        unavailableMessage: unavailable,
        noResponseMessage: noResponse,
      ),
      throwsA(
        isA<AiQuotaExceededException>()
            .having(
              (error) => error.message,
              'message',
              'Free limit reached. Try again in one hour.',
            )
            .having(
              (error) => error.retryAfterSeconds,
              'retryAfterSeconds',
              3600,
            ),
      ),
    );
  });

  test('falls back to the generic message on a malformed 429 body', () {
    expect(
      () => parseAskAiResponse(
        429,
        'not a map',
        unavailableMessage: unavailable,
        noResponseMessage: noResponse,
      ),
      throwsA(isA<Exception>().having((e) => e is AiQuotaExceededException, 'is quota exception', isFalse)),
    );
  });

  test('throws a generic exception for other non-2xx statuses', () {
    expect(
      () => parseAskAiResponse(
        502,
        {'error': 'ignored for non-429 failures'},
        unavailableMessage: unavailable,
        noResponseMessage: noResponse,
      ),
      throwsA(
        isA<Exception>()
            .having((e) => e is AiQuotaExceededException, 'is quota exception', isFalse)
            .having((e) => e.toString(), 'toString', contains(unavailable)),
      ),
    );
  });

  test('uses the backend error when a 2xx response has no reply', () {
    expect(
      () => parseAskAiResponse(
        200,
        {'error': 'Gemini returned nothing usable'},
        unavailableMessage: unavailable,
        noResponseMessage: noResponse,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('Gemini returned nothing usable'),
        ),
      ),
    );
  });
}
