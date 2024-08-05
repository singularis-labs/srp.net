

import 'dart:convert';
import 'dart:typed_data';

import 'package:srp_6a/src/srp_types/srp_integer.dart';
import 'package:crypto/crypto.dart';

abstract class ISrpHash {
  /// Computes the hash of the specified [String] or [SrpInteger] values.
  SrpInteger computeHash(List<Object?> values);

  /// Gets the hash size in bytes.
  int get hashSizeBytes;

  /// Gets the name of the algorithm.
  String get algorithmName;
}

class SrpHash implements ISrpHash {
  final Hash Function() hasherFactory;
  final String? _algorithmName;

  SrpHash(this.hasherFactory, [this._algorithmName]);

  Hash get hasher => hasherFactory();

  @override
  SrpInteger computeHash(List<Object?> values) {
    final combined = _combine(values.map((v) => getBytes(v)).toList());
    return computeHashFromBytes(combined);
  }

  @override
  int get hashSizeBytes => hasher.convert(Uint8List(0)).bytes.length;

  @override
  String get algorithmName => _algorithmName ?? hasher.runtimeType.toString();

  SrpInteger computeHashFromBytes(Uint8List data) {
    final hash = hasher.convert(data).bytes;
    return SrpInteger.fromByteArray(Uint8List.fromList(hash));
  }

  static Hash createHasher(String algorithm) {
    switch (algorithm.toLowerCase()) {
      case 'md5':
        return md5;
      case 'sha1':
        return sha1;
      case 'sha256':
        return sha256;
      case 'sha384':
        return sha384;
      case 'sha512':
        return sha512;
      default:
        throw ArgumentError('Unknown algorithm: $algorithm');
    }
  }

  static Hash createSha256() {
    return sha256;
  }

  static Uint8List get emptyBuffer => Uint8List(0);

  static Uint8List getBytes(Object? obj) {
    if (obj == null) {
      return emptyBuffer;
    }

    if (obj is String && obj.isNotEmpty) {
      return Uint8List.fromList(utf8.encode(obj));
    }

    if (obj is SrpInteger) {
      return obj.toByteArray();
    }

    return emptyBuffer;
  }

  static Uint8List _combine(List<Uint8List> arrays) {
    final totalLength = arrays.fold(0, (sum, a) => sum + a.length);
    final result = Uint8List(totalLength);
    var offset = 0;

    for (final array in arrays) {
      result.setRange(offset, offset + array.length, array);
      offset += array.length;
    }

    return result;
  }
}

class SrpHashGeneric<T extends Hash> extends SrpHash {
  SrpHashGeneric() : super(() => createHasher(T.toString()));

  static Hash createHasher(String algorithm) {
    switch (algorithm.toLowerCase()) {
      case 'md5':
        return md5;
      case 'sha1':
        return sha1;
      case 'sha256':
        return sha256;
      case 'sha384':
        return sha384;
      case 'sha512':
        return sha512;
      default:
        throw ArgumentError('Unknown algorithm: $algorithm');
    }
  }
}