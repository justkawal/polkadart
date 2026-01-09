part of metadata;

/// V16 uses the same OuterEnums structure as V15
///
/// The outer enum type IDs (RuntimeCall, RuntimeEvent, RuntimeError, RuntimeOrigin)
/// remain unchanged between V15 and V16.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L47-L66
typedef OuterEnumsV16 = OuterEnumsV15;

/// V16 uses the same CustomMetadata structure as V15
///
/// Custom metadata fields remain unchanged between V15 and V16.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L47-L66
typedef CustomMetadataV16 = CustomMetadataV15;

/// Deprecation information for metadata items (pallets, storage, constants, APIs).
///
/// V16 introduces deprecation tracking to allow runtime developers to mark
/// components as deprecated while maintaining backward compatibility.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L431-L472
sealed class ItemDeprecationInfo {
  const ItemDeprecationInfo();

  /// Codec instance for ItemDeprecationInfo
  static const $ItemDeprecationInfo codec = $ItemDeprecationInfo._();

  /// Check if this item is deprecated
  bool get isDeprecated;

  /// Get deprecation note if available
  String? get note;

  /// Get deprecation since version if available
  String? get since;

  Map<String, dynamic> toJson();
}

/// Item is not deprecated.
///
/// SCALE encoding: enum index 0, no additional data
class ItemNotDeprecated extends ItemDeprecationInfo {
  const ItemNotDeprecated();

  @override
  bool get isDeprecated => false;

  @override
  String? get note => null;

  @override
  String? get since => null;

  @override
  Map<String, dynamic> toJson() => {'type': 'NotDeprecated'};
}

/// Item is deprecated but without any note.
///
/// SCALE encoding: enum index 1, no additional data
class ItemDeprecatedWithoutNote extends ItemDeprecationInfo {
  const ItemDeprecatedWithoutNote();

  @override
  bool get isDeprecated => true;

  @override
  String? get note => null;

  @override
  String? get since => null;

  @override
  Map<String, dynamic> toJson() => {'type': 'DeprecatedWithoutNote'};
}

/// Item is deprecated with a note and optional since version.
///
/// SCALE encoding: enum index 2, followed by:
/// - note: String
/// - since: Option<String>
class ItemDeprecated extends ItemDeprecationInfo {
  /// Deprecation note explaining why the item is deprecated
  final String deprecationNote;

  /// Version since which the item has been deprecated
  final String? deprecationSince;

  const ItemDeprecated({required this.deprecationNote, this.deprecationSince});

  @override
  bool get isDeprecated => true;

  @override
  String? get note => deprecationNote;

  @override
  String? get since => deprecationSince;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'Deprecated',
    'note': deprecationNote,
    'since': deprecationSince,
  };
}

/// Codec for ItemDeprecationInfo
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L431-L472
class $ItemDeprecationInfo with Codec<ItemDeprecationInfo> {
  const $ItemDeprecationInfo._();

  @override
  ItemDeprecationInfo decode(Input input) {
    final index = U8Codec.codec.decode(input);

    switch (index) {
      case 0:
        return const ItemNotDeprecated();
      case 1:
        return const ItemDeprecatedWithoutNote();
      case 2:
        final note = StrCodec.codec.decode(input);
        final hasSince = BoolCodec.codec.decode(input);
        final since = hasSince ? StrCodec.codec.decode(input) : null;
        return ItemDeprecated(deprecationNote: note, deprecationSince: since);
      default:
        throw Exception('Unknown ItemDeprecationInfo variant: $index');
    }
  }

  @override
  void encodeTo(ItemDeprecationInfo value, Output output) {
    switch (value) {
      case ItemNotDeprecated():
        U8Codec.codec.encodeTo(0, output);
      case ItemDeprecatedWithoutNote():
        U8Codec.codec.encodeTo(1, output);
      case ItemDeprecated(:final deprecationNote, :final deprecationSince):
        U8Codec.codec.encodeTo(2, output);
        StrCodec.codec.encodeTo(deprecationNote, output);
        if (deprecationSince != null) {
          BoolCodec.codec.encodeTo(true, output);
          StrCodec.codec.encodeTo(deprecationSince, output);
        } else {
          BoolCodec.codec.encodeTo(false, output);
        }
    }
  }

  @override
  int sizeHint(ItemDeprecationInfo value) {
    switch (value) {
      case ItemNotDeprecated():
        return 1;
      case ItemDeprecatedWithoutNote():
        return 1;
      case ItemDeprecated(:final deprecationNote, :final deprecationSince):
        var size = 1; // variant index
        size += StrCodec.codec.sizeHint(deprecationNote);
        size += 1; // Option discriminator
        if (deprecationSince != null) {
          size += StrCodec.codec.sizeHint(deprecationSince);
        }
        return size;
    }
  }

  @override
  bool isSizeZero() => false;
}

/// Deprecation information for individual enum variants (calls, events, errors).
///
/// Note: This enum intentionally omits index 0 (NotDeprecated) since variants
/// not in the map are implicitly not deprecated.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L511-L537
sealed class VariantDeprecationInfo {
  const VariantDeprecationInfo();

  /// Codec instance for VariantDeprecationInfo
  static const $VariantDeprecationInfo codec = $VariantDeprecationInfo._();

  /// Always true since presence in map means deprecated
  bool get isDeprecated => true;

  /// Get deprecation note if available
  String? get note;

  /// Get deprecation since version if available
  String? get since;

  Map<String, dynamic> toJson();
}

/// Variant is deprecated but without any note.
///
/// SCALE encoding: enum index 1 (note: no index 0)
class VariantDeprecatedWithoutNote extends VariantDeprecationInfo {
  const VariantDeprecatedWithoutNote();

  @override
  String? get note => null;

  @override
  String? get since => null;

  @override
  Map<String, dynamic> toJson() => {'type': 'DeprecatedWithoutNote'};
}

/// Variant is deprecated with a note and optional since version.
///
/// SCALE encoding: enum index 2, followed by:
/// - note: String
/// - since: Option<String>
class VariantDeprecated extends VariantDeprecationInfo {
  /// Deprecation note
  final String _note;

  /// Version since which the variant has been deprecated
  final String? _since;

  const VariantDeprecated({required String note, String? since}) : _note = note, _since = since;

  @override
  String? get note => _note;

  @override
  String? get since => _since;

  @override
  Map<String, dynamic> toJson() => {'type': 'Deprecated', 'note': _note, 'since': _since};
}

/// Codec for VariantDeprecationInfo
///
/// Note: Uses custom codec indices starting at 1 (no index 0).
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L511-L537
class $VariantDeprecationInfo with Codec<VariantDeprecationInfo> {
  const $VariantDeprecationInfo._();

  @override
  VariantDeprecationInfo decode(Input input) {
    final index = U8Codec.codec.decode(input);

    switch (index) {
      case 1:
        return const VariantDeprecatedWithoutNote();
      case 2:
        final note = StrCodec.codec.decode(input);
        final hasSince = BoolCodec.codec.decode(input);
        final since = hasSince ? StrCodec.codec.decode(input) : null;
        return VariantDeprecated(note: note, since: since);
      default:
        throw Exception('Unknown VariantDeprecationInfo variant: $index');
    }
  }

  @override
  void encodeTo(VariantDeprecationInfo value, Output output) {
    switch (value) {
      case VariantDeprecatedWithoutNote():
        U8Codec.codec.encodeTo(1, output);
      case VariantDeprecated(:final _note, :final _since):
        U8Codec.codec.encodeTo(2, output);
        StrCodec.codec.encodeTo(_note, output);
        if (_since != null) {
          BoolCodec.codec.encodeTo(true, output);
          StrCodec.codec.encodeTo(_since, output);
        } else {
          BoolCodec.codec.encodeTo(false, output);
        }
    }
  }

  @override
  int sizeHint(VariantDeprecationInfo value) {
    switch (value) {
      case VariantDeprecatedWithoutNote():
        return 1;
      case VariantDeprecated(:final _note, :final _since):
        var size = 1;
        size += StrCodec.codec.sizeHint(_note);
        size += 1;
        if (_since != null) {
          size += StrCodec.codec.sizeHint(_since);
        }
        return size;
    }
  }

  @override
  bool isSizeZero() => false;
}

/// Deprecation information for enum types (calls, events, errors).
///
/// Maps variant indices to their deprecation status. Variants not in the map
/// are implicitly not deprecated.
///
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L473-L510
class EnumDeprecationInfo {
  /// Map of variant index to deprecation info
  final Map<int, VariantDeprecationInfo> deprecatedVariants;

  const EnumDeprecationInfo(this.deprecatedVariants);

  /// Empty deprecation info (no deprecated variants)
  static const EnumDeprecationInfo empty = EnumDeprecationInfo({});

  /// Codec instance for EnumDeprecationInfo
  static const $EnumDeprecationInfo codec = $EnumDeprecationInfo._();

  /// Check if a specific variant is deprecated
  bool isVariantDeprecated(int variantIndex) {
    return deprecatedVariants.containsKey(variantIndex);
  }

  /// Get deprecation info for a specific variant
  VariantDeprecationInfo? getVariantDeprecation(int variantIndex) {
    return deprecatedVariants[variantIndex];
  }

  Map<String, dynamic> toJson() => {
    'deprecatedVariants': deprecatedVariants.map((k, v) => MapEntry(k.toString(), v.toJson())),
  };
}

/// Codec for EnumDeprecationInfo
///
/// Encoded as BTreeMap<u8, VariantDeprecationInfo>
/// Reference: https://github.com/paritytech/frame-metadata/blob/main/frame-metadata/src/v16.rs#L473-L510
class $EnumDeprecationInfo with Codec<EnumDeprecationInfo> {
  const $EnumDeprecationInfo._();

  @override
  EnumDeprecationInfo decode(Input input) {
    final length = CompactCodec.codec.decode(input);
    final map = <int, VariantDeprecationInfo>{};

    for (var i = 0; i < length; i++) {
      final key = U8Codec.codec.decode(input);
      final value = VariantDeprecationInfo.codec.decode(input);
      map[key] = value;
    }

    return EnumDeprecationInfo(map);
  }

  @override
  void encodeTo(EnumDeprecationInfo value, Output output) {
    final entries = value.deprecatedVariants.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    CompactCodec.codec.encodeTo(entries.length, output);
    for (final entry in entries) {
      U8Codec.codec.encodeTo(entry.key, output);
      VariantDeprecationInfo.codec.encodeTo(entry.value, output);
    }
  }

  @override
  int sizeHint(EnumDeprecationInfo value) {
    var size = CompactCodec.codec.sizeHint(value.deprecatedVariants.length);
    for (final entry in value.deprecatedVariants.entries) {
      size += 1; // u8 key
      size += VariantDeprecationInfo.codec.sizeHint(entry.value);
    }
    return size;
  }

  @override
  bool isSizeZero() => false;
}
