part of sr25519;

class Signature {
  r255.Element r = r255.Element.newElement();
  r255.Scalar s = r255.Scalar();

  Signature.from(this.r, this.s);

  Signature._();

  /// Signature.fromBytes returns a new Signature from the given bytes List<int>
  factory Signature.fromBytes(List<int> bytes) {
    if (bytes.length != 64) {
      throw Exception(
          'Invalid bytes. Expected bytes of length 64, got ${bytes.length}');
    }

    final sig = Signature._();
    sig.decode(bytes);
    return sig;
  }

  /// Signature.fromHex returns a new Signature from the given hex-encoded string
  factory Signature.fromHex(String s) {
    final sigHex = hex.decode(s);
    if (sigHex.length != 64) {
      throw Exception(
          'Invalid hex string. Expected 64 bytes, got ${sigHex.length}');
    }

    final sig = Signature._();
    sig.decode(sigHex);
    return sig;
  }

  /// Decode sets a Signature from bytes
  /// see: https://github.com/w3f/schnorrkel/blob/db61369a6e77f8074eb3247f9040ccde55697f20/src/sign.rs#L100
  void decode(List<int> bytes) {
    if (bytes.length != 64) {
      throw Exception('invalid bytes length');
    }
    if (bytes[63] & 128 == 0) {
      throw Exception('signature is not marked as a schnorrkel signature');
    }

    final cp = List<int>.from(bytes, growable: false);

    r = r255.Element.newElement();
    r.decode(Uint8List.fromList(cp.sublist(0, 32)));
    cp[63] &= 127;
    s = r255.Scalar();
    return s.decode(cp.sublist(32, 64));
  }

  /// Encode turns a signature into a byte array
  /// see: https://github.com/w3f/schnorrkel/blob/db61369a6e77f8074eb3247f9040ccde55697f20/src/sign.rs#L77
  List<int> encode() {
    final List<int> out = List<int>.filled(64, 0, growable: false);
    out
      ..setRange(0, 32, r.encode())
      ..setRange(32, 64, s.encode());
    out[63] |= 128;
    return out;
  }

  /// DecodeNotDistinguishedFromEd25519 sets a signature from bytes, not checking if the signature
  /// is explicitly marked as a schnorrkel signature
  void decodeNotDistinguishedFromEd25519(List<int> bytes) {
    if (bytes.length != 64) {
      throw Exception('invalid bytes length');
    }
    final cp = List<int>.from(bytes, growable: false);
    cp[63] |= 128;
    return decode(cp);
  }
}
