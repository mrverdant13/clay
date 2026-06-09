import 'package:clay_cli/src/features/preview/parse_preview_vars.dart';
import 'package:test/test.dart';

void main() {
  group('parsePreviewVars', () {
    test('parses booleans, numbers, and strings', () {
      expect(
        parsePreviewVars(
          'requirements_met=true,use_drift=false,count=3,name=app',
        ),
        {
          'requirements_met': true,
          'use_drift': false,
          'count': 3,
          'name': 'app',
        },
      );
    });

    test('returns empty map for null input', () {
      expect(parsePreviewVars(null), isEmpty);
    });

    test('returns empty map for blank input', () {
      expect(parsePreviewVars('   '), isEmpty);
    });

    test('strips surrounding quotes from string values', () {
      expect(parsePreviewVars('title="My App"'), {'title': 'My App'});
      expect(parsePreviewVars("title='My App'"), {'title': 'My App'});
    });

    test('throws for invalid pairs', () {
      expect(() => parsePreviewVars('not-a-pair'), throwsFormatException);
    });

    test('throws when the key is empty after trimming whitespace', () {
      expect(
        () => parsePreviewVars(' =value'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid --vars entry (expected key=value):  =value',
          ),
        ),
      );
    });
  });
}
