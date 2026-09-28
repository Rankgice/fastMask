class MaskRange {
  const MaskRange({required this.start, required this.end, required this.seed})
    : assert(start >= 0),
      assert(end >= start);

  final int start;
  final int end;
  final int seed;

  int get length => end - start;

  bool contains(int offset) => offset >= start && offset < end;

  bool touchesOrOverlaps(MaskRange other) {
    return start <= other.end && other.start <= end;
  }

  MaskRange copyWith({int? start, int? end, int? seed}) {
    return MaskRange(
      start: start ?? this.start,
      end: end ?? this.end,
      seed: seed ?? this.seed,
    );
  }

  Map<String, Object> toJson() => {'start': start, 'end': end, 'seed': seed};

  factory MaskRange.fromJson(Map<String, dynamic> json) {
    return MaskRange(
      start: json['start'] as int,
      end: json['end'] as int,
      seed: json['seed'] as int? ?? 0,
    );
  }
}
