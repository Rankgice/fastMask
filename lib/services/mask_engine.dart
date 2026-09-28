import 'dart:math';

import '../models/mask_range.dart';
import '../models/mask_rule.dart';

class MaskEngine {
  const MaskEngine._();

  static List<MaskRange> addRange(
    Iterable<MaskRange> current,
    MaskRange incoming,
  ) {
    return _merge([...current, incoming]);
  }

  static List<MaskRange> _merge(Iterable<MaskRange> ranges) {
    final merged = <MaskRange>[];

    for (final range in normalize(ranges)) {
      if (merged.isEmpty || !merged.last.touchesOrOverlaps(range)) {
        merged.add(range);
        continue;
      }

      final previous = merged.removeLast();
      merged.add(
        MaskRange(
          start: min(previous.start, range.start),
          end: max(previous.end, range.end),
          seed: previous.seed,
        ),
      );
    }

    return merged;
  }

  static List<MaskRange> normalize(Iterable<MaskRange> ranges) {
    final valid = ranges.where((range) => range.length > 0).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return valid;
  }

  static String render(
    String source,
    Iterable<MaskRange> ranges,
    MaskRule rule,
  ) {
    final normalized = _merge(ranges);
    if (normalized.isEmpty) {
      return source;
    }

    final output = StringBuffer();
    var cursor = 0;

    for (final range in normalized) {
      if (range.start >= source.length) {
        break;
      }

      final start = range.start.clamp(cursor, source.length).toInt();
      final end = range.end.clamp(start, source.length).toInt();
      output.write(source.substring(cursor, start));

      final original = source.substring(start, end);
      output.write(rule.replacementFor(original, range.seed));
      cursor = end;
    }

    if (cursor < source.length) {
      output.write(source.substring(cursor));
    }

    return output.toString();
  }

  static MaskRange? rangeAt(int offset, Iterable<MaskRange> ranges) {
    for (final range in ranges) {
      if (range.contains(offset)) {
        return range;
      }
    }
    return null;
  }
}
