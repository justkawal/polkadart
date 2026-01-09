part of models;

/// Extrinsic preamble type
///
/// Defines the type of extrinsic based on the version byte encoding:
/// - v4: bare (0x04), signed (0x84)
/// - v5: bare (0x05), signed (0x85), general (0x45)
enum ExtrinsicType {
  /// Bare extrinsic (inherent) - no signature, no extensions
  /// v4: 0b0000_0100 (0x04), v5: 0b0000_0101 (0x05)
  bare,

  /// Signed extrinsic - has signature and extensions
  /// v4: 0b1000_0100 (0x84), v5: 0b1000_0101 (0x85)
  signed,

  /// General extrinsic (v5 only) - no signature, but has extensions
  /// v5: 0b0100_0101 (0x45)
  general,
}

/// Represents an unchecked extrinsic (transaction) in the runtime
///
/// Supports both extrinsic format v4 and v5:
/// - v4: Traditional signed/unsigned model
/// - v5: New bare/signed/general model with TransactionExtension support
class UncheckedExtrinsic {
  /// Extrinsic format version (4 or 5)
  final int version;

  /// Extrinsic type (bare, signed, or general)
  final ExtrinsicType type;

  /// Optional signature (present for signed extrinsics)
  final ExtrinsicSignature? signature;

  /// Optional extension data (present for general extrinsics in v5)
  /// This contains the extension version byte followed by extension data
  final Map<String, dynamic>? extensions;

  /// The actual call being made
  final RuntimeCall call;

  const UncheckedExtrinsic({
    required this.version,
    required this.type,
    this.signature,
    this.extensions,
    required this.call,
  });

  /// Create a bare/unsigned extrinsic
  factory UncheckedExtrinsic.bare({required int version, required RuntimeCall call}) {
    return UncheckedExtrinsic(version: version, type: ExtrinsicType.bare, call: call);
  }

  /// Create a signed extrinsic
  factory UncheckedExtrinsic.signed({
    required int version,
    required ExtrinsicSignature signature,
    required RuntimeCall call,
  }) {
    return UncheckedExtrinsic(
      version: version,
      type: ExtrinsicType.signed,
      signature: signature,
      call: call,
    );
  }

  /// Create a general extrinsic (v5 only)
  factory UncheckedExtrinsic.general({
    required Map<String, dynamic> extensions,
    required RuntimeCall call,
  }) {
    return UncheckedExtrinsic(
      version: 5,
      type: ExtrinsicType.general,
      extensions: extensions,
      call: call,
    );
  }

  /// Whether this is a signed extrinsic
  bool get isSigned => type == ExtrinsicType.signed;

  /// Whether this is a bare/inherent extrinsic
  bool get isBare => type == ExtrinsicType.bare;

  /// Whether this is a general extrinsic (v5 only)
  bool get isGeneral => type == ExtrinsicType.general;

  Map<String, dynamic> toJson() => {
    'version': version,
    'type': type.name,
    'isSigned': isSigned,
    if (signature != null) 'signature': signature!.toJson(),
    if (extensions != null) 'extensions': extensions,
    'call': call.toJson(),
  };
}
