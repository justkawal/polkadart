// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i3;

class VrfSignature {
  const VrfSignature({
    required this.output,
    required this.proof,
  });

  factory VrfSignature.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// VrfOutput
  final List<int> output;

  /// VrfProof
  final List<int> proof;

  static const $VrfSignatureCodec codec = $VrfSignatureCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, List<int>> toJson() => {
        'output': output.toList(),
        'proof': proof.toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is VrfSignature &&
          _i3.listsEqual(
            other.output,
            output,
          ) &&
          _i3.listsEqual(
            other.proof,
            proof,
          );

  @override
  int get hashCode => Object.hash(
        output,
        proof,
      );
}

class $VrfSignatureCodec with _i1.Codec<VrfSignature> {
  const $VrfSignatureCodec();

  @override
  void encodeTo(
    VrfSignature obj,
    _i1.Output output,
  ) {
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.output,
      output,
    );
    const _i1.U8ArrayCodec(64).encodeTo(
      obj.proof,
      output,
    );
  }

  @override
  VrfSignature decode(_i1.Input input) {
    return VrfSignature(
      output: const _i1.U8ArrayCodec(32).decode(input),
      proof: const _i1.U8ArrayCodec(64).decode(input),
    );
  }

  @override
  int sizeHint(VrfSignature obj) {
    int size = 0;
    size = size + const _i1.U8ArrayCodec(32).sizeHint(obj.output);
    size = size + const _i1.U8ArrayCodec(64).sizeHint(obj.proof);
    return size;
  }
}