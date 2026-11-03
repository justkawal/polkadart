part of primitives;

class CompactBigIntCodec with Codec<BigInt> {
  const CompactBigIntCodec._();

  static const CompactBigIntCodec codec = CompactBigIntCodec._();

  @override
  void encodeTo(BigInt value, Output output) {
    if (value < BigInt.from(64)) {
      output.pushByte(value.toInt() << 2);
    } else if (value < BigInt.from(16384)) {
      output
        ..pushByte((value.toInt() & 0x3F) << 2 | 1)
        ..pushByte((value.toInt() >> 6).toUnsigned(8));
    } else if (value < BigInt.from(1073741824)) {
      output
        ..pushByte((value.toInt() & 0x3F) << 2 | 2)
        ..pushByte((value.toInt() >> 6).toUnsigned(8))
        ..pushByte((value.toInt() >> 14).toUnsigned(8))
        ..pushByte((value.toInt() >> 22).toUnsigned(8));
    } else {
      assertion(
        value.bitLength >= 30,
        'Previously checked anyting less than 2^30; qed',
      );
      final bytesNeeded = (value.bitLength + 7) >> 3;
      output.pushByte(((bytesNeeded - 4) << 2).toUnsigned(8) | 3);
      for (var i = 0; i < bytesNeeded; i++) {
        output.pushByte(value.toUnsigned(8).toInt());
        value >>= 8;
      }
      assertion(value == BigInt.zero, 'Value is not fully consumed; qed');
    }
  }

  @override
  BigInt decode(Input input) {
    var prefix = input.read();
    switch (prefix % 4) {
      case 0:
        {
          return BigInt.from(prefix >> 2);
        }
      case 1:
        {
          prefix >>= 2;
          prefix |= input.read() << 6;
          assertion(prefix > 0x3f && prefix <= 0x3fff, 'Out of range');
          return BigInt.from(prefix);
        }
      case 2:
        {
          prefix >>= 2;
          prefix |=
              (input.read() << 6) | (input.read() << 14) | (input.read() << 22);
          assertion(prefix > 0x3fff && prefix <= 0x3fffffff, 'Out of range');
          return BigInt.from(prefix);
        }
      default:
        {
          final bytesNeeded = (prefix >> 2) + 4;
          var value = BigInt.zero;
          for (var i = 0; i < bytesNeeded; i++) {
            value |= BigInt.from(input.read()) << (8 * i);
          }
          assertion(value > BigInt.from(0x3fffffff), 'Out of range');
          return value;
        }
    }
  }

  @override
  int sizeHint(BigInt value) {
    if (value <= BigInt.from(0x3F)) {
      return 1;
    } else if (value <= BigInt.from(0x3FFF)) {
      return 2;
    } else if (value <= BigInt.from(0x3FFFFFFF)) {
      return 4;
    } else {
      return ((value.bitLength + 7) >> 3) + 1;
    }
  }

  @override
  bool isSizeZero() {
    // Compact encoding always produces at least 1 byte
    return false;
  }
}

class CompactCodec with Codec<int> {
  const CompactCodec._();

  static CompactCodec codec = CompactCodec._();

  @override
  void encodeTo(int value, Output output) {
    if (value < 64) {
      output.pushByte(value.toInt() << 2);
    } else if (value < 16384) {
      output
        ..pushByte((value.toInt() & 0x3F) << 2 | 1)
        ..pushByte((value.toInt() >> 6).toUnsigned(8));
    } else if (value < 1073741824) {
      output
        ..pushByte((value.toInt() & 0x3F) << 2 | 2)
        ..pushByte((value.toInt() >> 6).toUnsigned(8))
        ..pushByte((value.toInt() >> 14).toUnsigned(8))
        ..pushByte((value.toInt() >> 22).toUnsigned(8));
    } else {
      assertion(
        value.bitLength >= 30,
        'Previously checked anyting less than 2^30; qed',
      );
      final bytesNeeded = (value.bitLength + 7) >> 3;
      output.pushByte(((bytesNeeded - 4) << 2).toUnsigned(8) | 3);
      for (var i = 0; i < bytesNeeded; i++) {
        output.pushByte(value.toUnsigned(8).toInt());
        // Not `>>= 8`: on JavaScript shifts truncate to 32 bits.
        value = value ~/ 256;
      }
      assertion(value == 0, 'Value is not fully consumed; qed');
    }
  }

  @override
  int decode(Input input) {
    var prefix = input.read();
    switch (prefix % 4) {
      case 0:
        {
          return prefix >> 2;
        }
      case 1:
        {
          prefix >>= 2;
          prefix |= input.read() << 6;
          assertion(prefix > 0x3f && prefix <= 0x3fff, 'Out of range');
          return prefix;
        }
      case 2:
        {
          prefix >>= 2;
          prefix |=
              (input.read() << 6) | (input.read() << 14) | (input.read() << 22);
          assertion(prefix > 0x3fff && prefix <= 0x3fffffff, 'Out of range');
          return prefix;
        }
      default:
        {
          final bytesNeeded = (prefix >> 2) + 4;
          var value = 0;
          var factor = 1;
          for (var i = 0; i < bytesNeeded; i++) {
            // Not `|= byte << (8 * i)`: on JavaScript shifts truncate to 32 bits.
            value += input.read() * factor;
            factor *= 256;
          }
          assertion(value > 0x3fffffff, 'Out of range');
          return value;
        }
    }
  }

  @override
  int sizeHint(int value) {
    if (value <= 0x3F) {
      return 1;
    } else if (value <= 0x3FFF) {
      return 2;
    } else if (value <= 0x3FFFFFFF) {
      return 4;
    } else {
      return ((value.bitLength + 7) >> 3) + 1;
    }
  }

  @override
  bool isSizeZero() {
    // Compact encoding always produces at least 1 byte
    return false;
  }
}
