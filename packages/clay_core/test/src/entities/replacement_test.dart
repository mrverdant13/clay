import 'package:clay_core/clay.dart';
import 'package:test/test.dart';

void main() {
  group('Replacement', () {
    test('can be instantiated', () {
      final replacement = Replacement(from: RegExp('from'), to: 'to');
      expect(replacement, isA<Replacement>());
    });

    test('fromJson with plain string pattern', () {
      final replacement = Replacement.fromJson(const {
        'from': r'^from$',
        'to': 'to',
      });
      expect(
        replacement,
        isA<Replacement>()
            .having(
              (r) => r.from,
              'from',
              isA<RegExp>().having((r) => r.pattern, 'pattern', r'^from$'),
            )
            .having((r) => r.to, 'to', 'to'),
      );
    });

    test('fromJson with object pattern and dotAll', () {
      final replacement = Replacement.fromJson(const {
        'from': {
          'pattern': r'@Dependencies\(\[(.*?)\]\)',
          'dotAll': true,
        },
        'to': r'{{#use_riverpod}}@Dependencies([${1}]){{/use_riverpod}}',
      });
      expect(
        replacement,
        isA<Replacement>()
            .having(
              (r) => r.from.pattern,
              'from.pattern',
              r'@Dependencies\(\[(.*?)\]\)',
            )
            .having((r) => r.from.isDotAll, 'from.isDotAll', isTrue)
            .having(
              (r) => r.to,
              'to',
              r'{{#use_riverpod}}@Dependencies([${1}]){{/use_riverpod}}',
            ),
      );
    });

    test('can be compared', () {
      final reference = Replacement(from: RegExp('from'), to: 'to');
      final same = Replacement(from: RegExp('from'), to: 'to');
      final other = Replacement(from: RegExp('from'), to: 'to2');
      expect(reference, same);
      expect(reference, isNot(other));
    });

    test('has consistent hash code', () {
      final reference = Replacement(from: RegExp('from'), to: 'to');
      final same = Replacement(from: RegExp('from'), to: 'to');
      final other = Replacement(from: RegExp('from'), to: 'to2');
      expect(reference.hashCode, same.hashCode);
      expect(reference.hashCode, isNot(other.hashCode));
    });
  });
}
