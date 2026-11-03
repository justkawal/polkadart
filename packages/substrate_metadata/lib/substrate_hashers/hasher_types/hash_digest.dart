// Copyright (c) 2023, Sudipto Chandra
// All rights reserved. Check LICENSE file for details.
// This code is part of hashlib 1.12.0
// https://pub.dev/packages/hashlib

part of substrate_hashers;

/* import 'dart:convert' as cvt;
import 'dart:typed_data';

import 'package:hashlib_codecs/hashlib_codecs.dart'; */

class HashDigest extends Object {
  final Uint8List bytes;

  const HashDigest(this.bytes);

  /// Returns the byte buffer associated with this digest.
  ByteBuffer get buffer => bytes.buffer;

  /// The message digest as a string of hexadecimal digits.
  @override
  String toString() => hex();

  /// The message digest as a binary string.
  String binary() => toBinary(bytes);

  /// The message digest as a octal string.
  String octal() => toOctal(bytes);

  /// The message digest as a hexadecimal string.
  ///
  /// Parameters:
  /// - If [upper] is true, the string will be in uppercase alphabets.
  String hex([bool upper = false]) => toHex(bytes, upper: upper);

  /// The message digest as a Base-32 string.
  ///
  /// If [upper] is true, the output will have uppercase alphabets.
  /// If [padding] is true, the output will have `=` padding at the end.
  String base32({bool upper = true, bool padding = true}) =>
      toBase32(bytes, lower: !upper, padding: padding);

  /// The message digest as a Base-64 string with no padding.
  ///
  /// If [urlSafe] is true, the output will have URL-safe base64 alphabets.
  /// If [padding] is true, the output will have `=` padding at the end.
  String base64({bool urlSafe = false, bool padding = true}) =>
      toBase64(bytes, padding: padding, url: urlSafe);

  /// The message digest as a BigInt.
  ///
  /// If [endian] is [Endian.little], it will treat the digest bytes as a little
  /// endian number; Otherwise, if [endian] is [Endian.big], it will treat the
  /// digest bytes as a big endian number.
  BigInt bigInt({Endian endian = Endian.little}) => toBigInt(bytes, msbFirst: endian == Endian.big);

  /// Gets 64-bit unsiged integer from the message digest.
  ///
  /// If [endian] is [Endian.little], it will treat the digest bytes as a little
  /// endian number; Otherwise, if [endian] is [Endian.big], it will treat the
  /// digest bytes as a big endian number.
  int number([Endian endian = Endian.big]) =>
      toBigInt(bytes, msbFirst: endian == Endian.big).toUnsigned(64).toInt();

  /// The message digest as a string of ASCII alphabets.
  String ascii() => cvt.ascii.decode(bytes);

  /// The message digest as a string of UTF-8 alphabets.
  String utf8() => cvt.utf8.decode(bytes);

  /// Returns the digest in the given [encoding]
  String to(cvt.Encoding encoding) => encoding.decode(bytes);

  @override
  int get hashCode => bytes.hashCode;

  @override
  bool operator ==(other) => isEqual(other);

  /// Checks if the message digest equals to [other].
  ///
  /// Here, the [other] can be a one of the following:
  /// - Another [HashDigest] object.
  /// - An [Iterable] containing an array of bytes
  /// - Any [ByteBuffer] or [TypedData] that will be converted to [Uint8List]
  /// - A [String], which will be treated as a hexadecimal encoded byte array
  ///
  /// This function will return True if all bytes in the [other] matches with
  /// the [bytes] of this object. If the length does not match, or the type of
  /// [other] is not supported, it returns False immediately.
  bool isEqual(dynamic other) {
    if (other is HashDigest) {
      return isEqual(other.bytes);
    } else if (other is ByteBuffer) {
      return isEqual(buffer.asUint8List());
    } else if (other is TypedData && other is! Uint8List) {
      return isEqual(other.buffer.asUint8List());
    } else if (other is String) {
      return isEqual(fromHex(other));
    } else if (other is Iterable<int>) {
      if (other is List<int>) {
        if (other.length != bytes.length) {
          return false;
        }
      }
      int i = 0;
      for (int x in other) {
        if (i >= bytes.length || x != bytes[i++]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
