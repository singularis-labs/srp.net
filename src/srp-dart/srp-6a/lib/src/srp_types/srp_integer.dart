import 'dart:typed_data';
import 'dart:math' as math;
// import 'package:srp_6a/src/types/big_integer.dart';
// import 'package:srp_6a/src/types/int64.dart';

class SrpInteger {
  BigInt _value;
  int? _hexLength;

  SrpInteger(String hex, {int? hexLength})
      : _hexLength = 1,
        _value = BigInt.zero {
    hex = _normalizeWhiteSpace(hex);
    _hexLength = hexLength;
    var sign = hex.startsWith("-") ? -1 : 1;
    hex = hex.replaceFirst(RegExp(r'^-+'), '');
    // print("Hex in constructor ${hex.toUpperCase()}");
    // append leading zero to make sure we get a positive BigInteger value
    // int iHex = int.parse(hex, radix: 16);
    var bigParse = BigInt.parse('0x${hex.toUpperCase()}');
    _value = BigInt.from(sign) * bigParse;
    // print("Hex in integer in constructor 2 $bigParse, $_value");
  }

  SrpInteger._internal()
      : _hexLength = 1,
        _value = BigInt.zero;

  SrpInteger._fromValues(this._value, this._hexLength);

  factory SrpInteger.fromInt(int integer) {
    return fromHex(integer.toRadixString(16));
  }

  int toInt() {
    return _value.toInt();
  }

  SrpInteger operator -(SrpInteger right) {
    return SrpInteger._fromValues(_value - right._value,
        math.max(_hexLength ?? 0, right._hexLength ?? 0));
  }

  SrpInteger operator +(SrpInteger right) {
    return SrpInteger._fromValues(_value + right._value,
        math.max(_hexLength ?? 0, right._hexLength ?? 0));
  }

  SrpInteger operator /(SrpInteger divisor) {
    return SrpInteger._fromValues(
      _value ~/ divisor._value,
        math.max(_hexLength ?? 0, divisor._hexLength ?? 0));
  }

  SrpInteger operator %(SrpInteger modulus) {
    return SrpInteger._fromValues(
        _value % modulus._value, modulus._hexLength ?? 0);
  }

  SrpInteger operator *(SrpInteger right) {
    return SrpInteger._fromValues(_value * right._value, null);
  }

  SrpInteger operator ^(SrpInteger right) {
    return SrpInteger._fromValues(_value ^ right._value,
        math.max(_hexLength ?? 0, right._hexLength ?? 0));
  }

  @override
  bool operator ==(Object other) {
    if (other is! SrpInteger) return false;
    if (identical(this, other)) return true;

    return _equals(other);
  }

  bool _equals(SrpInteger other) {
    return _value == other._value;
  }

  static String _normalizeWhiteSpace(String? hexNumber) {
    return (hexNumber ?? '').replaceAll(RegExp(r'[\s_]'), '');
  }

  static SrpInteger get zero => SrpInteger._internal();

  static int max(List<int?> values) =>
      values.map((v) => v ?? 0).reduce((a, b) => a > b ? a : b);

  SrpInteger pad(int newLength) {
    return SrpInteger._fromValues(_value, newLength);
  }

  static SrpInteger randomInteger(int bytes) {
    if (bytes <= 0) {
      throw ArgumentError(
          ["Integer size in bytes should be positive", "bytes"]);
    }

    final random = math.Random.secure();
    final randomBytes = Uint8List(bytes);
    for (int i = 0; i < bytes; i++) {
      randomBytes[i] = random.nextInt(256);
    }

    var result = fromByteArray(randomBytes);
    if (result._value < BigInt.zero) {
      result._value = BigInt.zero - result._value;
    }

    return result;
  }

  SrpInteger modPow(SrpInteger exponent, SrpInteger modulus) {    
    // var value = BigInt.modPow(_value, exponent._value, modulus._value);
    // value.modPow(exponent, modulus)
    var value = _value.modPow(exponent._value, modulus._value);

    if (value < BigInt.zero) {
      value = modulus._value + value;
    }

    return SrpInteger._fromValues(value, modulus._hexLength);
  }

  String toHex({int? hexLength}) {
    hexLength = _hexLength ?? hexLength;
    if (hexLength == null) {
      throw UnsupportedError("Hexadecimal length is not specified");
    }
    var sign = "";
    var value = _value;
    if (value < BigInt.zero) {
      sign = "-";
      value = BigInt.zero - value;
    }

    //return sign + value.toHexString().padLeft(hexLength, '0');
    return sign + value.toRadixString(16).padLeft(hexLength, '0');
  }

  Uint8List toByteArray() {
    // var array = _value.toByteArray().reversed;
    // array = array.skipWhile((value) => value == 0);
    Uint8List array = _serializeBigInt(_value);
    array = Uint8List.fromList(array.where((v) => v != 0).toList());

    if (_hexLength == null) {
      // no padding required
      return Uint8List.fromList(array.toList());
    }
    if ((_hexLength ?? 0) <= array.length * 2) {
      return Uint8List.fromList(array.toList());
    }

    var length = _hexLength! ~/ 2;
    var result = Uint8List(length);
    result.setRange(length - array.length, length, array);
    return result;
  }

  static Uint8List _serializeBigInt(BigInt bi) {
    Uint8List array = Uint8List((bi.bitLength / 8).ceil());
    for (int i = 0; i < array.length; i++) {
      array[i] = (bi >> (i * 8)).toUnsigned(8).toInt();
    }
    return array;
  }

  static BigInt _deserializeBigInt(Uint8List array) {
    var bi = BigInt.zero;
    for (var byte in array.reversed) {
      bi <<= 8;
      bi |= BigInt.from(byte);
    }
    return bi;
  }

  static SrpInteger fromByteArray(Uint8List bytes) {
    if (bytes.isEmpty) {
      return zero;
    }
    bytes = Uint8List.fromList(bytes.reversed.toList());

    // var value = BigInteger.fromByteArray(bytes);
    var value = _deserializeBigInt(bytes);
    if (value < BigInt.zero) {
      value = (BigInt.one << (bytes.length * 8)) + value;
    }

    return SrpInteger._fromValues(value, bytes.length * 2);
  }

  static SrpInteger fromHex(String hex) {
    if (hex.isEmpty) {
      hex = "0";
    }
    var hexLength =
        _normalizeWhiteSpace(hex).trim().replaceAll(' ', '-').length;
    return SrpInteger(hex, hexLength: hexLength);
  }

  String toHexString() {
    return _value.toRadixString(16);
  }

  @override
  String toString() {
    var hex = "0x${_value.toRadixString(16)}";
    if (hex.length > 16) {
      hex = "${hex.substring(0, 16)}...";
    }
    return "<SrpInteger: {$hex}>";
  }

  @override
  int get hashCode => _value.hashCode;

  int? get hexLength => _hexLength;
}
