import 'dart:math';

import 'package:characters/characters.dart';

enum MaskLengthMode { preserve, fixed, proportional, randomRange }

enum MaskVisualStyle { glyph, solid }

enum MaskPatternPreset { asterisk, square, hash, custom }

class MaskRule {
  const MaskRule({
    this.lengthMode = MaskLengthMode.preserve,
    this.visualStyle = MaskVisualStyle.glyph,
    this.patternPreset = MaskPatternPreset.asterisk,
    this.token = '*',
    this.fixedText = '[已隐藏]',
    this.ratio = 1,
    this.minDelta = -2,
    this.maxDelta = 2,
    this.backgroundColor = const ColorValue(0xFF1F2933),
    this.foregroundColor = const ColorValue(0xFFFFFFFF),
  });

  final MaskLengthMode lengthMode;
  final MaskVisualStyle visualStyle;
  final MaskPatternPreset patternPreset;
  final String token;
  final String fixedText;
  final double ratio;
  final int minDelta;
  final int maxDelta;
  final ColorValue backgroundColor;
  final ColorValue foregroundColor;

  String get previewToken => token.isEmpty ? '*' : token;

  int generatedLength(String original, int seed) {
    final sourceLength = original.characters
        .where((char) => char != '\n' && char != '\r')
        .length;
    return switch (lengthMode) {
      MaskLengthMode.preserve => sourceLength,
      MaskLengthMode.fixed => fixedText.characters.length,
      MaskLengthMode.proportional => max(1, (sourceLength * ratio).round()),
      MaskLengthMode.randomRange => max(1, sourceLength + _randomDelta(seed)),
    };
  }

  String replacementFor(String original, int seed) {
    if (lengthMode == MaskLengthMode.fixed) {
      return fixedText;
    }

    final length = generatedLength(original, seed);
    final repeated = _repeatToLength(previewToken, length);

    if (lengthMode == MaskLengthMode.preserve) {
      return _preserveLineBreaks(original, repeated);
    }

    return repeated;
  }

  String _repeatToLength(String pattern, int length) {
    final patternCharacters = pattern.characters.toList();
    if (patternCharacters.isEmpty || length <= 0) {
      return '';
    }

    final output = StringBuffer();
    for (var index = 0; index < length; index++) {
      output.write(patternCharacters[index % patternCharacters.length]);
    }
    return output.toString();
  }

  int _randomDelta(int seed) {
    final lower = min(minDelta, maxDelta);
    final upper = max(minDelta, maxDelta);
    return lower + Random(seed).nextInt(upper - lower + 1);
  }

  String _preserveLineBreaks(String original, String replacement) {
    final chars = original.characters;
    final output = StringBuffer();
    final replacementCharacters = replacement.characters.toList();
    var replacementIndex = 0;

    for (final char in chars) {
      if (char == '\n' || char == '\r') {
        output.write(char);
      } else if (replacementIndex < replacementCharacters.length) {
        output.write(replacementCharacters[replacementIndex]);
        replacementIndex++;
      }
    }

    return output.toString();
  }

  MaskRule copyWith({
    MaskLengthMode? lengthMode,
    MaskVisualStyle? visualStyle,
    MaskPatternPreset? patternPreset,
    String? token,
    String? fixedText,
    double? ratio,
    int? minDelta,
    int? maxDelta,
    ColorValue? backgroundColor,
    ColorValue? foregroundColor,
  }) {
    return MaskRule(
      lengthMode: lengthMode ?? this.lengthMode,
      visualStyle: visualStyle ?? this.visualStyle,
      patternPreset: patternPreset ?? this.patternPreset,
      token: token ?? this.token,
      fixedText: fixedText ?? this.fixedText,
      ratio: ratio ?? this.ratio,
      minDelta: minDelta ?? this.minDelta,
      maxDelta: maxDelta ?? this.maxDelta,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
    );
  }

  Map<String, Object> toJson() => {
    'lengthMode': lengthMode.name,
    'visualStyle': visualStyle.name,
    'patternPreset': patternPreset.name,
    'token': token,
    'fixedText': fixedText,
    'ratio': ratio,
    'minDelta': minDelta,
    'maxDelta': maxDelta,
    'backgroundColor': backgroundColor.value,
    'foregroundColor': foregroundColor.value,
  };

  factory MaskRule.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, Object? name, T fallback) {
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => fallback,
      );
    }

    return MaskRule(
      lengthMode: enumValue(
        MaskLengthMode.values,
        json['lengthMode'],
        MaskLengthMode.preserve,
      ),
      visualStyle: enumValue(
        MaskVisualStyle.values,
        json['visualStyle'],
        MaskVisualStyle.glyph,
      ),
      patternPreset: enumValue(
        MaskPatternPreset.values,
        json['patternPreset'],
        MaskPatternPreset.asterisk,
      ),
      token: json['token'] as String? ?? '*',
      fixedText: json['fixedText'] as String? ?? '[已隐藏]',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 1,
      minDelta: json['minDelta'] as int? ?? -2,
      maxDelta: json['maxDelta'] as int? ?? 2,
      backgroundColor: ColorValue(
        json['backgroundColor'] as int? ?? 0xFF1F2933,
      ),
      foregroundColor: ColorValue(
        json['foregroundColor'] as int? ?? 0xFFFFFFFF,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MaskRule &&
            lengthMode == other.lengthMode &&
            visualStyle == other.visualStyle &&
            patternPreset == other.patternPreset &&
            token == other.token &&
            fixedText == other.fixedText &&
            ratio == other.ratio &&
            minDelta == other.minDelta &&
            maxDelta == other.maxDelta &&
            backgroundColor == other.backgroundColor &&
            foregroundColor == other.foregroundColor;
  }

  @override
  int get hashCode => Object.hash(
    lengthMode,
    visualStyle,
    patternPreset,
    token,
    fixedText,
    ratio,
    minDelta,
    maxDelta,
    backgroundColor,
    foregroundColor,
  );
}

class ColorValue {
  const ColorValue(this.value);

  final int value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ColorValue && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
