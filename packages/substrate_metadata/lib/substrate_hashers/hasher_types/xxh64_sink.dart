// Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.
// This code is part of hashlib 1.12.0
// https://pub.dev/packages/hashlib

part of substrate_hashers;

/// `true` when compiled to JavaScript (dart2js / dartdevc), where `int` is an
/// IEEE-754 double and bitwise operations only work on 32 bits.
///
/// It is a compile-time constant, so the unused implementation is tree-shaken.
const bool _isJS = identical(1, 1.0);

const int _mask32 = 0xFFFFFFFF;

/// Sink for the 64-bit xxHash.
///
/// On the Dart VM and on dart2wasm it uses native 64-bit integers
/// ([XXHash64NativeSink]). When compiled to JavaScript it uses
/// [XXHash64PortableSink], which emulates 64-bit arithmetic with two 32-bit
/// halves so the result is identical on every platform.
abstract class XXHash64Sink extends BlockHashSink {
  final int seed;

  @override
  final int hashLength = 8;

  // The constants are built from 32-bit halves because dart2js rejects
  // integer literals that cannot be represented exactly in JavaScript.
  static const int prime64_1 = 0x9E3779B1 << 32 | 0x85EBCA87;
  static const int prime64_2 = 0xC2B2AE3D << 32 | 0x27D4EB4F;
  static const int prime64_3 = 0x165667B1 << 32 | 0x9E3779F9;
  static const int prime64_4 = 0x85EBCA77 << 32 | 0xC2B2AE63;
  static const int prime64_5 = 0x27D4EB2F << 32 | 0x165667C5;

  /// Creates the implementation suited to the current platform.
  factory XXHash64Sink(int seed) => _isJS ? XXHash64PortableSink(seed) : XXHash64NativeSink(seed);

  XXHash64Sink._(this.seed) : super(32);

  @override
  void $update([List<int>? block, int offset = 0, bool last = false]);

  @override
  void $process(List<int> chunk, int start, int end) {
    messageLength += end - start;
    for (; start < end; start++, pos++) {
      if (pos == blockLength) {
        $update();
        pos = 0;
      }
      buffer[pos] = chunk[start];
    }
    // Fold a complete block right away: $finalize only processes the partial
    // tail, so skipping this breaks inputs whose length is a multiple of 32.
    if (pos == blockLength) {
      $update();
      pos = 0;
    }
  }
}

/// This implementation is derived from
/// https://github.com/easyaspi314/xxhash-clean/blob/master/xxhash64-ref.c
///
/// It relies on 64-bit integers and does not work when compiled to
/// JavaScript; use [XXHash64Sink] to get the right one for the platform.
class XXHash64NativeSink extends XXHash64Sink {
  static const int prime64_1 = XXHash64Sink.prime64_1;
  static const int prime64_2 = XXHash64Sink.prime64_2;
  static const int prime64_3 = XXHash64Sink.prime64_3;
  static const int prime64_4 = XXHash64Sink.prime64_4;
  static const int prime64_5 = XXHash64Sink.prime64_5;

  int _acc1 = 0;
  int _acc2 = 0;
  int _acc3 = 0;
  int _acc4 = 0;

  late final Uint64List qbuffer = buffer.buffer.asUint64List();

  XXHash64NativeSink(super.seed) : super._() {
    reset();
  }

  @override
  void reset() {
    super.reset();
    _acc1 = seed + prime64_1 + prime64_2;
    _acc2 = seed + prime64_2;
    _acc3 = seed + 0;
    _acc4 = seed - prime64_1;
  }

  @pragma('vm:prefer-inline')
  static int _rotl(int x, int n) => (x << n) | (x >>> (64 - n));

  @pragma('vm:prefer-inline')
  static int _accumulate(int x, int y) => _rotl((x + y * prime64_2), 31) * prime64_1;

  @override
  void $update([List<int>? block, int offset = 0, bool last = false]) {
    _acc1 = _accumulate(_acc1, qbuffer[0]);
    _acc2 = _accumulate(_acc2, qbuffer[1]);
    _acc3 = _accumulate(_acc3, qbuffer[2]);
    _acc4 = _accumulate(_acc4, qbuffer[3]);
  }

  @pragma('vm:prefer-inline')
  static int _merge(int h, int a) => (h ^ _accumulate(0, a)) * prime64_1 + prime64_4;

  @override
  Uint8List $finalize() {
    int i, t;
    int hash;

    if (messageLength < 32) {
      hash = seed + prime64_5;
    } else {
      // accumulate
      hash = _rotl(_acc1, 1);
      hash += _rotl(_acc2, 7);
      hash += _rotl(_acc3, 12);
      hash += _rotl(_acc4, 18);

      // merge round
      hash = _merge(hash, _acc1);
      hash = _merge(hash, _acc2);
      hash = _merge(hash, _acc3);
      hash = _merge(hash, _acc4);
    }

    hash += messageLength;

    // process the remaining data
    for (i = t = 0; t + 8 <= pos; ++i, t += 8) {
      hash ^= _accumulate(0, qbuffer[i]);
      hash = _rotl(hash, 27);
      hash *= prime64_1;
      hash += prime64_4;
    }
    for (i <<= 1; t + 4 <= pos; ++i, t += 4) {
      hash ^= sbuffer[i] * prime64_1;
      hash = _rotl(hash, 23);
      hash *= prime64_2;
      hash += prime64_3;
    }
    for (; t < pos; t++) {
      hash ^= buffer[t] * prime64_5;
      hash = _rotl(hash, 11);
      hash *= prime64_1;
    }

    // avalanche
    hash ^= hash >>> 33;
    hash *= prime64_2;
    hash ^= hash >>> 29;
    hash *= prime64_3;
    hash ^= hash >>> 32;

    return Uint8List.fromList([
      hash >>> 56,
      hash >>> 48,
      hash >>> 40,
      hash >>> 32,
      hash >>> 24,
      hash >>> 16,
      hash >>> 8,
      hash,
    ]);
  }
}

/// Same algorithm as [XXHash64NativeSink], computed on pairs of 32-bit
/// halves so it gives exact results on every platform, including JavaScript.
class XXHash64PortableSink extends XXHash64Sink {
  static final _prime1 = _U64(0x9E3779B1, 0x85EBCA87);
  static final _prime2 = _U64(0xC2B2AE3D, 0x27D4EB4F);
  static final _prime3 = _U64(0x165667B1, 0x9E3779F9);
  static final _prime4 = _U64(0x85EBCA77, 0xC2B2AE63);
  static final _prime5 = _U64(0x27D4EB2F, 0x165667C5);
  // 2^64 - prime64_1
  static final _negPrime1 = _U64(0x61C8864E, 0x7A143579);

  final _acc1 = _U64(0, 0);
  final _acc2 = _U64(0, 0);
  final _acc3 = _U64(0, 0);
  final _acc4 = _U64(0, 0);

  XXHash64PortableSink(super.seed) : super._() {
    reset();
  }

  @override
  void reset() {
    super.reset();
    final s = _U64.fromInt(seed);
    _acc1
      ..setFrom(s)
      ..add(_prime1)
      ..add(_prime2);
    _acc2
      ..setFrom(s)
      ..add(_prime2);
    _acc3.setFrom(s);
    _acc4
      ..setFrom(s)
      ..add(_negPrime1);
  }

  /// acc = rotl(acc + input * prime64_2, 31) * prime64_1
  static void _accumulate(_U64 acc, _U64 input) {
    final t = _U64.copy(input)..mul(_prime2);
    acc
      ..add(t)
      ..rotl(31)
      ..mul(_prime1);
  }

  /// hash = (hash ^ accumulate(0, a)) * prime64_1 + prime64_4
  static void _merge(_U64 hash, _U64 a) {
    final t = _U64(0, 0);
    _accumulate(t, a);
    hash
      ..xor(t)
      ..mul(_prime1)
      ..add(_prime4);
  }

  _U64 _readU64(int offset) =>
      _U64(bdata.getUint32(offset + 4, Endian.little), bdata.getUint32(offset, Endian.little));

  @override
  void $update([List<int>? block, int offset = 0, bool last = false]) {
    _accumulate(_acc1, _readU64(0));
    _accumulate(_acc2, _readU64(8));
    _accumulate(_acc3, _readU64(16));
    _accumulate(_acc4, _readU64(24));
  }

  @override
  Uint8List $finalize() {
    final _U64 hash;

    if (messageLength < 32) {
      hash = _U64.fromInt(seed)..add(_prime5);
    } else {
      // accumulate
      hash = _U64.copy(_acc1)..rotl(1);
      hash.add(_U64.copy(_acc2)..rotl(7));
      hash.add(_U64.copy(_acc3)..rotl(12));
      hash.add(_U64.copy(_acc4)..rotl(18));

      // merge round
      _merge(hash, _acc1);
      _merge(hash, _acc2);
      _merge(hash, _acc3);
      _merge(hash, _acc4);
    }

    hash.add(_U64.fromInt(messageLength));

    // process the remaining data
    int t = 0;
    for (; t + 8 <= pos; t += 8) {
      final k = _U64(0, 0);
      _accumulate(k, _readU64(t));
      hash
        ..xor(k)
        ..rotl(27)
        ..mul(_prime1)
        ..add(_prime4);
    }
    for (; t + 4 <= pos; t += 4) {
      hash
        ..xor(_U64(0, bdata.getUint32(t, Endian.little))..mul(_prime1))
        ..rotl(23)
        ..mul(_prime2)
        ..add(_prime3);
    }
    for (; t < pos; t++) {
      hash
        ..xor(_U64(0, buffer[t])..mul(_prime5))
        ..rotl(11)
        ..mul(_prime1);
    }

    // avalanche
    hash
      ..xorShiftRight(33)
      ..mul(_prime2)
      ..xorShiftRight(29)
      ..mul(_prime3)
      ..xorShiftRight(32);

    final hi = hash.hi;
    final lo = hash.lo;
    return Uint8List.fromList([
      hi >>> 24,
      hi >>> 16,
      hi >>> 8,
      hi,
      lo >>> 24,
      lo >>> 16,
      lo >>> 8,
      lo,
    ]);
  }
}

/// Mutable unsigned 64-bit integer stored as two unsigned 32-bit halves.
///
/// Every intermediate value stays below 2^53, so the arithmetic is exact
/// both on native integers and on JavaScript numbers.
class _U64 {
  int hi;
  int lo;

  _U64(this.hi, this.lo);

  _U64.copy(_U64 other) : hi = other.hi, lo = other.lo;

  /// Two's complement of [value]; on JavaScript [value] must fit in 53 bits.
  factory _U64.fromInt(int value) {
    final lo = value & _mask32;
    return _U64(((value - lo) ~/ 0x100000000) & _mask32, lo);
  }

  void setFrom(_U64 other) {
    hi = other.hi;
    lo = other.lo;
  }

  void add(_U64 other) {
    final l = lo + other.lo;
    lo = l & _mask32;
    hi = (hi + other.hi + (l > _mask32 ? 1 : 0)) & _mask32;
  }

  void xor(_U64 other) {
    hi = (hi ^ other.hi) & _mask32;
    lo = (lo ^ other.lo) & _mask32;
  }

  /// this = this * other (mod 2^64)
  void mul(_U64 other) {
    final a = lo;
    final b = other.lo;
    final a0 = a & 0xFFFF;
    final a1 = a >>> 16;
    final b0 = b & 0xFFFF;
    final b1 = b >>> 16;

    // Full 64-bit product of the low halves, in 16-bit limbs.
    final p00 = a0 * b0;
    final p01 = a0 * b1;
    final p10 = a1 * b0;
    final mid = (p00 >>> 16) + (p01 & 0xFFFF) + (p10 & 0xFFFF);
    final productLo = (((mid & 0xFFFF) << 16) | (p00 & 0xFFFF)) & _mask32;
    final productHi = (mid >>> 16) + (p01 >>> 16) + (p10 >>> 16) + a1 * b1;

    hi = (productHi + _mulLow32(hi, b) + _mulLow32(a, other.hi)) & _mask32;
    lo = productLo;
  }

  /// Low 32 bits of a * b; the result is below 2^33 and must be masked.
  static int _mulLow32(int a, int b) {
    final a0 = a & 0xFFFF;
    final b0 = b & 0xFFFF;
    final cross = (a0 * (b >>> 16) + (a >>> 16) * b0) & 0xFFFF;
    return ((cross << 16) & _mask32) + a0 * b0;
  }

  /// Rotates left by [n] bits, with 0 < n < 32.
  void rotl(int n) {
    final h = ((hi << n) | (lo >>> (32 - n))) & _mask32;
    lo = ((lo << n) | (hi >>> (32 - n))) & _mask32;
    hi = h;
  }

  /// this ^= this >>> n, with 0 < n < 64.
  void xorShiftRight(int n) {
    if (n < 32) {
      lo = (lo ^ (((lo >>> n) | (hi << (32 - n))) & _mask32)) & _mask32;
      hi = (hi ^ (hi >>> n)) & _mask32;
    } else {
      lo = (lo ^ (hi >>> (n - 32))) & _mask32;
    }
  }
}
