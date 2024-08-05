import 'dart:typed_data';
import 'dart:math' as math;

import 'package:tuple/tuple.dart';

import 'types.dart';

class BigInteger implements Comparable<BigInteger> {
  final List<UInt32> data;
  final Int16 sign;

  BigInteger._internal(this.sign, this.data);

  BigInteger(int sign, List<int> data)
      : this._internal(Int16(sign), UInt32.fromIntList(data));

  static const List<int> _one = [1];

  factory BigInteger.fromInt(int value) {
    if (value == 0) {
      return BigInteger._internal(Int16(0), []);
    } else if (value > 0) {
      return BigInteger._internal(Int16(1), [UInt32(value)]);
    } else {
      return BigInteger._internal(Int16(1), [UInt32(-value)]);
    }
  }

  factory BigInteger.fromLong(Int64 value) {
    if (value.value == 0) {
      return BigInteger._internal(Int16(0), []);
    } else if (value.value > 0) {
      var s = Int16(1);
      UInt32 low = UInt32(value.value);
      UInt32 high = UInt32(value.value) >> 32;

      var d = List<UInt32>.filled(high != UInt32(0) ? 2 : 1, UInt32(0),
          growable: false);
      d[0] = low;
      if (high != UInt32(0)) {
        d[1] = high;
      }
      return BigInteger._internal(s, d);
    } else {
      var s = Int16(-1);
      value = Int64(-value.value);
      UInt32 low = UInt32(value.value);
      UInt32 high = UInt32((UInt64(value.value) >> 32).value);
      var d = List<UInt32>.filled(high != UInt32(0) ? 2 : 1, UInt32(0),
          growable: false);
      d[0] = low;
      if (high != UInt32(0)) {
        d[1] = high;
      }
      return BigInteger._internal(s, d);
    }
  }

  static bool _negative(Uint8List v) {
    return (v[7] & 0x80) != 0;
  }

  static int _exponent(Uint8List v) {
    return ((v[7] & 0x7F) << 4) | ((v[6] & 0xF0) >> 4);
  }

  static int _mantissa(Uint8List v) {
    int i1 = v[0] | (v[1] << 8) | (v[2] << 16) | (v[3] << 24);
    int i2 = v[4] | (v[5] << 8) | ((v[6] & 0xF) << 16);
    return i1 | (i2 << 32);
  }

  static const _bias = 1075;

  factory BigInteger.fromDouble(double value) {
    if (value == double.infinity) {
      throw UnsupportedError("Value cannot be infinity");
    }

    Uint8List bytes = Uint8List(8);
    var byteData = ByteData.sublistView(bytes);
    byteData.setFloat64(0, value);
    UInt64 mantissa = UInt64(_mantissa(bytes));

    if (mantissa == UInt64(0)) {
      // 1.0 * 2**exp, we have a power of 2
      int exponent = _exponent(bytes);
      if (exponent == 0) {
        return BigInteger(0, []);
      }

      BigInteger res = _negative(bytes) ? minusOne : one;
      res = res << (exponent - 0x3ff);
      return BigInteger._internal(res.sign, res.data);
    } else {
      // 1.mantissa * 2**exp
      int exponent = _exponent(bytes);
      mantissa |= UInt64(0x10000000000000);
      BigInteger res = BigInteger.fromLong(Int64(mantissa.value));
      res = exponent > _bias
          ? res << (exponent - _bias)
          : res >> (_bias - exponent);
      var s = _negative(bytes) ? Int16(-1) : Int16(1);
      return BigInteger._internal(s, res.data);
    }
  }

  static const Int32 decimalScaleFactorMask = Int32(0x00FF0000);
  static const Int32 decimalSignMask = Int32(0x80000000);

  factory BigInteger.fromDecimal(double value) {
    return BigInteger.fromDouble(value);
  }

  factory BigInteger.fromByteArray(Uint8List value) {
    if (value.isEmpty) {
      throw ArgumentError.notNull("value");
    }

    int len = value.length;
    if (len == 0 || (len == 1 && value[0] == 0)) {
      return zero;
    }

    var sign = (value[len-1] & 0x80) != 0 ? -1 : 1;
    if(sign == 1){
      while (value [len - 1] == 0) {
					if (--len == 0) {						
						return zero;
					}
				}

        int fullWords, size;
				fullWords = size = len ~/ 4;
				if ((len & 0x3) != 0) {
				  ++size;
				}

				List<UInt32> data = List.filled(size, UInt32(0), growable: false);
        int j = 0;
        for (int i = 0; i < fullWords; ++i) {
					data [i] =	UInt32(value[j++]) |
								UInt32(value [j++] << 8) |
								UInt32(value [j++] << 16) |
								UInt32(value [j++] << 24);
				}
        size = len & 0x3;
        if (size > 0) {
					int idx = data.length - 1;
					for (int i = 0; i < size; ++i) {
					  data [idx] |= UInt32(value [j++] << (i * 8));
					}
				}
        return BigInteger._internal(Int16(sign), data);
    } else {
      int full_words, size;
				full_words = size = len ~/ 4;
				if ((len & 0x3) != 0) {
				  ++size;
				}
        List<UInt32> data = List.filled(size, UInt32(0), growable: false);

        UInt32 word = UInt32(1);
        UInt32 borrow = UInt32(1);
        UInt64 sub = UInt64(0);
        int j = 0;
        for (int i = 0; i < full_words; ++i) {
					word =	UInt32(value [j++]) |
							UInt32(value [j++] << 8) |
							UInt32(value [j++] << 16) |
							UInt32(value [j++] << 24);

					sub = UInt64(word.value - borrow.value);
					word = UInt32(sub.value);
					borrow = UInt32((sub.value >> 32) & 0x1);
					data [i] = ~word;
				}
				size = len & 0x3;
        if (size > 0) {
					word = UInt32(0);
					UInt32 storeMask = UInt32(0);

					for (int i = 0; i < size; ++i) {
						word |= UInt32(value [j++] << (i * 8));
						storeMask = (storeMask << 8) | UInt32(0xFF);
					}
					
          sub = UInt64(word.value - borrow.value);
					word = UInt32(sub.value);
					borrow = UInt32((sub.value >> 32) & 0x1);
          var negWordStoreMask = ~word.value & storeMask.value;

					if ( negWordStoreMask == 0 ) {
					  data = _resize (data, data.length - 1);
					} else {
					  data [data.length - 1] = UInt32(negWordStoreMask);
					}

				}
        if (borrow.value != 0) {
          //FIXME I believe this can't happen, can someone write a test for it?
					throw Exception ("non zero final carry");
        }
        return BigInteger._internal(Int16(sign), data);
    }
    
  }

  bool get isEven => sign == Int16(0) || (data[0].value & 0x1) == 0;
  bool get isOne =>
      sign == Int16(1) && data.length == 1 && data[0] == UInt32(1);

  /* static int _populationCountInt32(UInt32 x) {
    // x = x & 0xFFFFFFFF;
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0F0F0F0F;
    x = x + (x >> 8);
    x = x + (x >> 16);
    return x & 0x0000003F;
  } */

  static Int32 _populationCountInt32(UInt32 x) {
    // x = x & 0xFFFFFFFF;
    x = x - ((x >> 1) & UInt32(0x55555555));
    x = (x & UInt32(0x33333333)) + ((x >> 2) & UInt32(0x33333333));
    x = (x + (x >> 4)) & UInt32(0x0F0F0F0F);
    x = x + (x >> 8);
    x = x + (x >> 16);
    return Int32((x & UInt32(0x0000003F)).value);
  }

  static Int32 _populationCountInt64(UInt64 x) {
    // x = x & 0xFFFFFFFFFFFFFFFF;
    x = x - ((x >> 1) & UInt64(0x5555555555555555));
    x = (x & UInt64(0x3333333333333333)) +
        ((x >> 2) & UInt64(0x3333333333333333));
    x = (x + (x >> 4)) & UInt64(0x0f0f0f0f0f0f0f0f);

    return Int32((((x * UInt64(0x0101010101010101)) >> 56)).value);
  }

  static Int32 _leadingZeroCountInt32(UInt32 value) {
    // value = value & 0xFFFFFFFF;

    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;

    return Int32(32) - _populationCountInt32(value);
  }

  static Int32 _leadingZeroCountInt64(UInt64 value) {
    // value = value & 0xFFFFFFFFFFFFFFFF;

    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    value |= value >> 32;

    return Int32(64) - _populationCountInt64(value);
  }

  static double _buildDouble(int sign, int mantissa, int exponent) {
    mantissa = mantissa & 0xFFFFFFFFFFFFFFFF;

    const int exponentBias = 1023;
    const int mantissaLength = 52;
    const int exponentLength = 11;
    const int maxExponent = 2046;
    const int mantissaMask = 0xfffffffffffff;
    const int exponentMask = 0x7ff;
    const int negativeMark = 0x8000000000000000;

    if (sign == 0 || mantissa == 0) {
      return 0.0;
    } else {
      exponent = exponent + exponentBias + mantissaLength;
      int offset =
          _leadingZeroCountInt64(UInt64(mantissa)).value - exponentLength;

      if (exponent - offset > maxExponent) {
        return sign > 0 ? double.infinity : double.negativeInfinity;
      } else {
        if (offset < 0) {
          mantissa = mantissa >> -offset;
          exponent = exponent + (-offset);
          exponent += offset;
        } else if (offset >= exponent) {
          mantissa = mantissa << exponent - 1;
          exponent = 0;
        } else {
          mantissa = mantissa << offset;
          exponent = exponent - offset;
        }
        mantissa = mantissa & mantissaMask;
        if ((exponent & exponentMask) == exponent) {
          int bits = mantissa | (exponent << mantissaLength);
          if (sign < 0) {
            bits = bits | negativeMark;
          }
          return _int64BitsToDouble(bits);
        } else {
          return sign > 0 ? double.infinity : double.negativeInfinity;
        }
      }
    }
  }

  static double _int64BitsToDouble(int bits) {
    var byteData = ByteData(8);
    byteData.setInt64(0, bits);
    return byteData.getFloat64(0);
  }

  bool get isPowerOfTwo {
    bool foundBit = false;
    if (sign.value != 1) {
      return false;
    }
    for (var i = 0; i < data.length; ++i) {
      int p = _populationCountInt32(data[i]).value;
      if (p > 0) {
        if (p > 1 || foundBit) {
          return false;
        }
        foundBit = true;
      }
    }
    return foundBit;
  }

  bool get isZero => sign == Int16(0);

  static BigInteger get minusOne => BigInteger(-1, _one);
  static BigInteger get one => BigInteger(1, _one);
  static BigInteger get zero => BigInteger(0, []);

  int toInt() {
    if (data.isEmpty) {
      return 0;
    }

    if (data.length > 1) {
      throw RangeError("Overflow: BigInteger value cannot fit in an int.");
    }

    UInt32 value = data[0];

    if (sign == Int16(1)) {
      if (value > UInt32(0x7FFFFFFF)) {
        throw RangeError("Overflow: BigInteger value cannot fit in an int.");
      }
      return value.value;
    } else if (sign == Int16(-1)) {
      if (value > UInt32(0x80000000)) {
        throw RangeError('Overflow: BigInteger value cannot fit in an int.');
      }
      return -value.value;
    }

    return 0;
  }

  int toLong() {
    if (data.isEmpty) {
      return 0;
    }

    if (data.length > 1) {
      throw RangeError("Overflow: BigInteger value cannot fit in an int.");
    }

    UInt64 value = UInt64(data[0].value);

    if (sign == Int16(1)) {
      if (value > UInt64(0x7FFFFFFFFFFFFFFF)) {
        throw RangeError("Overflow: BigInteger value cannot fit in an int64.");
      }
      return value.value;
    } else if (sign == Int16(-1)) {
      if (value > UInt64(0x8000000000000000)) {
        throw RangeError('Overflow: BigInteger value cannot fit in an int64.');
      }
      return -value.value;
    }

    return 0;
  }

  double toDouble() {
    if (data.isEmpty) {
      return 0.0;
    }
    switch (data.length) {
      case 1:
        return _buildDouble(sign.value, data[0].value, 0);
      case 2:
        return _buildDouble(
            sign.value,
            (UInt64(data[1].value) << 32).value | UInt64(data[0].value).value,
            0);
      default:
        var index = data.length - 1;
        var word = data[index];
        var mantissa = (word << 32) | data[index - 1];
        int missing = (_leadingZeroCountInt32(word) - Int32(11))
            .value; // 11 = bits in exponent
        if (missing > 0) {
          // add the missing bits from the next word
          mantissa =
              (mantissa << missing) | (data[index - 2] >> (32 - missing));
        } else {
          mantissa = mantissa >> -missing;
        }
        return _buildDouble(
            sign.value, mantissa.value, ((data.length - 2) * 32) - missing);
    }
  }

  BigInteger operator +(BigInteger right) {
    if (sign.value == 0) {
      return right;
    }

    if (right.sign.value == 0) {
      return this;
    }

    if (sign.value == right.sign.value) {
      return BigInteger._internal(sign, _coreAddList(data, right.data));
    }
    Int32 r = _coreCompare(data, right.data);
    if (r.value == 0) {
      return zero;
    }
    if (r.value > 0) {
      // left > right
      return BigInteger._internal(sign, _coreSubList(data, right.data));
    }

    return BigInteger._internal(sign, _coreSubList(right.data, data));
  }

  BigInteger operator -(BigInteger right) {
    if (right.sign.value == 0) {
      return this;
    }

    if (sign.value == 0) {
      return BigInteger._internal(Int16(-right.sign.value), right.data);
    }

    if (sign.value == right.sign.value) {
      Int32 r = _coreCompare(data, right.data);

      if (r.value == 0) {
        return zero;
      }
      if (r.value > 0) {
        return BigInteger._internal(sign, _coreSubList(data, right.data));
      }

      return BigInteger._internal(
          Int16(-right.sign.value), _coreSubList(right.data, data));
    }

    return BigInteger._internal(sign, _coreAddList(data, right.data));
  }

  BigInteger operator *(BigInteger right) {
    if (sign.value == 0 || right.sign.value == 0) {
      return zero;
    }

    if (data[0].value == 1 && data.length == 1) {
      if (sign.value == 1) {
        return right;
      }
      return BigInteger._internal(Int16(-right.sign.value), right.data);
    }

    if (right.data[0].value == 1 && right.data.length == 1) {
      if (right.sign.value == 1) {
        return this;
      }
      return BigInteger._internal(Int16(-sign.value), data);
    }

    List<UInt32> a = data;
    List<UInt32> b = right.data;

    List<UInt32> res =
        List.filled(a.length + b.length, UInt32(0), growable: false);

    for (int i = 0; i < a.length; ++i) {
      UInt32 ai = a[i];
      int k = i;

      UInt64 carry = UInt64(0);
      for (int j = 0; j < b.length; ++j) {
        carry = carry +
            UInt64(ai.value) * UInt64(b[j].value) +
            UInt64(res[k].value);
        res[k++] = UInt32(carry.value);
        carry >>= 32;
      }

      while (carry != UInt64(0)) {
        carry += UInt64(res[k].value);
        res[k++] = UInt32(carry.value);
        carry >>= 32;
      }
    }

    int m = 0;

    for (m = res.length - 1; m >= 0 && res[m] == UInt32(0); --m) {}
    if (m < res.length - 1) {
      res = _resize(res, m + 1);
    }

    return BigInteger._internal(Int16(sign.value * right.sign.value), res);
  }

  BigInteger operator /(BigInteger divisor) {
    if (divisor.sign.value == 0) {
      throw UnsupportedError("Divide by Zero Error");
    }

    if (sign.value == 0) {
      return this;
    }

    var divResult = divModUnsigned(data, divisor.data);
    List<UInt32> quotient = divResult.item1;
    // List<UInt32> remainder_value = divResult.item2;

    int i;
    for (i = quotient.length - 1; i >= 0 && quotient[i] == UInt32(0); --i) {}
    if (i == -1) {
      return zero;
    }

    if (i < quotient.length - 1) {
      quotient = _resize(quotient, i + 1);
    }

    return BigInteger._internal(
        Int16(sign.value * divisor.sign.value), quotient);
  }

  BigInteger operator %(BigInteger divisor) {
    if (divisor.sign.value == 0) {
      throw UnsupportedError("Divide by Zero Error");
    }

    if (sign.value == 0) {
      return this;
    }

    var divResult = divModUnsigned(data, divisor.data);
    // List<UInt32> quotient = divResult.item1;
    List<UInt32> remainderValue = divResult.item2;

    int i;
    for (i = remainderValue.length - 1;
        i >= 0 && remainderValue[i] == UInt32(0);
        --i) {}
    if (i == -1) {
      return zero;
    }

    if (i < remainderValue.length - 1) {
      remainderValue = _resize(remainderValue, i + 1);
    }

    return BigInteger._internal(sign, remainderValue);
  }

  BigInteger increment() {
    if (data.isEmpty) {
      return one;
    }

    if (data.length == 1) {
      if (sign.value == -1 && data[0] == UInt32(1)) {
        return zero;
      }
      if (sign.value == 0) {
        return BigInteger(1, _one);
      }
    }

    List<UInt32> d;

    if (sign.value == -1) {
      d = _coreSub(data, 1);
    } else {
      d = _coreAdd(data, 1);
    }

    return BigInteger._internal(sign, d);
  }

  BigInteger decrement() {
    if (data.isEmpty) {
      return minusOne;
    }

    print("In decrement: ${data.length}");

    if (data.length == 1) {
      if (sign.value == 1 && data[0] == UInt32(1)) {
        return zero;
      }
      if (sign.value == 0) {
        return BigInteger(-1, _one);
      }
    }

    List<UInt32> d;

    print("In decrement: ${sign.value}");

    if (sign.value == -1) {
      d = _coreAdd(data, 1);
    } else {
      d = _coreSub(data, 1);
    }

    return BigInteger._internal(sign, d);
  }

  BigInteger operator &(BigInteger right) {
    if (sign.value == 0) {
      return this;
    }

    if (right.sign.value == 0) {
      return right;
    }

    List<UInt32> a = data;
    List<UInt32> b = right.data;
    int ls = sign.value;
    int rs = right.sign.value;

    bool negRes = (ls == rs) && (ls == -1);

    List<UInt32> result =
        List.filled(math.max(a.length, b.length), UInt32(0), growable: false);
    UInt64 ac = UInt64(1);
    UInt64 bc = UInt64(1);
    UInt64 borrow = UInt64(1);

    int i;

    for (i = 0; i < result.length; ++i) {
      UInt32 va = UInt32(0);
      if (i < a.length) {
        va = a[i];
      }

      if (ls == -1) {
        ac = UInt64(~va.value & UInt32.mask) + ac;
        va = UInt32(ac.value & UInt32.mask);
        ac = UInt64((ac.value >> 32) & UInt32.mask);
      }

      UInt32 vb = UInt32(0);
      if (i < b.length) {
        vb = b[i];
      }

      if (rs == -1) {
        bc = UInt64((~vb.value & UInt32.mask) + bc.value);
        vb = UInt32(bc.value & UInt32.mask);
        bc = UInt64((bc.value >> 32) & UInt32.mask);
      }

      UInt32 word = UInt32(va.value & vb.value);

      if (negRes) {
        borrow = UInt64(word.value - borrow.value);
        word = UInt32(~(borrow.value) & UInt32.mask);
        borrow = UInt64((borrow.value >> 32) & 0x1);
      }
      result[i] = word;
    }
    for (i = result.length - 1; i >= 0 && result[i] == UInt32(0); --i) {}
    if (i == -1) {
      return zero;
    }
    if (i < result.length - 1) {
      result = _resize(result, i + 1);
    }

    // return BigInteger(negRes ? -1 : 1, UInt32.toIntList(result));
    return BigInteger._internal(negRes ? Int16(-1) : Int16(1), result);
  }

  BigInteger operator |(BigInteger right) {
    if (sign.value == 0) {
      return right;
    }

    if (right.sign.value == 0) {
      return this;
    }

    List<UInt32> a = data;
    List<UInt32> b = right.data;

    int ls = sign.value;
    int rs = right.sign.value;

    bool negRes = (ls == -1) || (rs == -1);

    List<UInt32> result =
        List.filled(math.max(a.length, b.length), UInt32(0), growable: false);
    UInt64 ac = UInt64(1);
    UInt64 bc = UInt64(1);
    UInt64 borrow = UInt64(1);

    int i;

    for (i = 0; i < result.length; ++i) {
      UInt32 va = UInt32(0);
      if (i < a.length) {
        va = a[i];
      }
      if (ls == -1) {
        ac = UInt64((~va.value & UInt32.mask)) + ac;
        va = UInt32(ac.value & UInt32.mask);
        ac = UInt64(ac.value >> 32 & UInt32.mask);
      }

      UInt32 vb = UInt32(0);
      if (i < b.length) {
        vb = b[i];
      }
      if (rs == -1) {
        bc = UInt64((~vb.value & UInt32.mask)) + bc;
        vb = UInt32(bc.value & UInt32.mask);
        bc = UInt64(bc.value >> 32 & UInt32.mask);
      }

      UInt32 word = UInt32(va.value | vb.value);

      if (negRes) {
        borrow = UInt64(word.value - borrow.value);
        word = UInt32(~(borrow.value) & UInt32.mask);
        borrow = UInt64((borrow.value >> 32) & 0x1);
      }

      result[i] = word;
    }

    for (i = result.length - 1; i >= 0 && result[i] == UInt32(0); --i) {}
    if (i == -1) {
      return zero;
    }

    if (i < result.length - 1) {
      result = _resize(result, i + 1);
    }

    return BigInteger._internal(negRes ? Int16(-1) : Int16(1), result);
  }

  BigInteger operator ^(BigInteger right) {
    if (sign.value == 0) {
      return right;
    }

    if (right.sign.value == 0) {
      return this;
    }

    List<UInt32> a = data;
    List<UInt32> b = right.data;

    int ls = sign.value;
    int rs = right.sign.value;

    bool negRes = (ls == -1) ^ (rs == -1);

    List<UInt32> result =
        List.filled(math.max(a.length, b.length), UInt32(0), growable: false);
    UInt64 ac = UInt64(1);
    UInt64 bc = UInt64(1);
    UInt64 borrow = UInt64(1);

    int i;

    for (i = 0; i < result.length; ++i) {
      UInt32 va = UInt32(0);
      if (i < a.length) {
        va = a[i];
      }
      if (ls == -1) {
        ac = UInt64((~va.value & UInt32.mask)) + ac;
        va = UInt32(ac.value & UInt32.mask);
        ac = UInt64(ac.value >> 32 & UInt32.mask);
      }

      UInt32 vb = UInt32(0);
      if (i < b.length) {
        vb = b[i];
      }
      if (rs == -1) {
        bc = UInt64((~vb.value & UInt32.mask)) + bc;
        vb = UInt32(bc.value & UInt32.mask);
        bc = UInt64(bc.value >> 32 & UInt32.mask);
      }

      UInt32 word = UInt32(va.value ^ vb.value);

      if (negRes) {
        borrow = UInt64(word.value - borrow.value);
        word = UInt32(~(borrow.value) & UInt32.mask);
        borrow = UInt64((borrow.value >> 32) & 0x1);
      }

      result[i] = word;
    }

    for (i = result.length - 1; i >= 0 && result[i] == UInt32(0); --i) {}
    if (i == -1) {
      return zero;
    }

    if (i < result.length - 1) {
      result = _resize(result, i + 1);
    }

    return BigInteger._internal(negRes ? Int16(-1) : Int16(1), result);
  }

  BigInteger operator ~() {
    if (data.isEmpty) {
      return BigInteger(-1, _one);
    }

    bool negRes = sign.value == 1;

    List<UInt32> result = List.filled(data.length, UInt32(0), growable: false);
    UInt64 carry = UInt64(1);
    UInt64 borrow = UInt64(1);

    int i;
    for (i = 0; i < result.length; ++i) {
      UInt32 word = data[i];
      if (sign.value == -1) {
        carry = UInt64((~word.value & UInt32.mask) + carry.value);
        word = UInt32(carry.value);
        carry = UInt64((carry.value >> 32) & UInt32.mask);
      }

      word = UInt32((~word.value) & UInt32.mask);

      if (negRes) {
        borrow = UInt64((word.value - borrow.value) & UInt32.mask);
        word = UInt32(~borrow.value & UInt32.mask);
        borrow = UInt64((borrow.value >> 32) & 0x1);
      }

      result[i] = word;
    }

    for (i = result.length - 1; i >= 0 && result[i] == UInt32(0); --i) {}
    if (i == -1) {
      return zero;
    }

    if (i < result.length - 1) {
      result = _resize(result, i + 1);
    }

    return BigInteger._internal(negRes ? Int16(-1) : Int16(1), result);
  }

  static int _bitScanBackward(UInt32 word) {
    for (int i = 31; i >= 0; --i) {
      UInt32 mask = UInt32(1 << i);
      if ((word & mask) == mask) {
        return i;
      }
    }
    return 0;
  }

  BigInteger operator <<(int shift) {
    if (shift == 0 || data.isEmpty) {
      return this;
    }

    if (shift < 0) {
      return this >> ~shift;
    }

    int topMostIdx = _bitScanBackward(data[data.length - 1]);
    int bits = shift - (31 - topMostIdx);
    int extraWords = (bits >> 5) + ((bits & 0x1F) != 0 ? 1 : 0);

    List<UInt32> res =
        List.filled(data.length + extraWords, UInt32(0), growable: false);

    int idxShift = shift >> 5;
    int bitShift = shift & 0x1F;
    int carryShift = 32 - bitShift;

    if (carryShift == 32) {
      for (int i = 0; i < data.length; ++i) {
        UInt32 word = data[i];
        res[i + idxShift] |= UInt32(word.value << bitShift);
      }
    } else {
      for (int i = 0; i < data.length; ++i) {
        UInt32 word = data[i];
        res[i + idxShift] |= UInt32(word.value << bitShift);
        if (i + idxShift + 1 < res.length) {
          res[i + idxShift + 1] = UInt32(word.value >> carryShift);
        }
      }
    }

    return BigInteger._internal(sign, res);
  }

  BigInteger operator >>(int shift) {
    // print("In operator >> First: $shift");
    if (shift == 0 || data.isEmpty) {
      return this;
    }

    if (shift < 0) {
      return this << -shift;
    }
    int topMostIdx = _bitScanBackward(data[data.length - 1]);
    int idxShift = shift >> 5;
    int bitShift = shift & 0x1F;

    int extraWords = idxShift;

    if (bitShift > topMostIdx) {
      ++extraWords;
    }

    int size = data.length - extraWords;
    if (size <= 0) {
      if (sign.value == 1) {
        return zero;
      }
      return minusOne;
    }

    List<UInt32> res = List.filled(size, UInt32(0), growable: false);
    int carryShift = 32 - bitShift;

    if (carryShift == 32) {
      for (int i = data.length - 1; i >= idxShift; --i) {
        UInt32 word = data[i];
        if (i - idxShift < res.length) {
          res[i - idxShift] |= UInt32(word.value >> bitShift);
        }
      }
    } else {
      for (int i = data.length - 1; i >= idxShift; --i) {
        UInt32 word = data[i];
        if (i - idxShift < res.length) {
          res[i - idxShift] |= UInt32(word.value >> bitShift);
        }
        if (i - idxShift - 1 >= 0) {
          res[i - idxShift - 1] = UInt32(word.value << carryShift);
        }
      }
    }

    // Round down instead of toward zero.    
    if (sign.value == -1) {
      for (int i = 0; i < idxShift; i++) {
        if (data[i] != UInt32(0)) {
          var tmp = BigInteger._internal(sign, res);
          tmp = tmp.decrement();
          return tmp;
        }
      }
      if (bitShift > 0 && (data[idxShift] << carryShift) != UInt32(0)) {
        var tmp = BigInteger._internal(sign, res);
        tmp = tmp.decrement();
        return tmp;
      }
    }

    var bigRes = BigInteger._internal(sign, res);
    // print("In operator Last >>: ${res.length}, ${sign.value}");
    return bigRes;
  }

  bool operator <(BigInteger right) {
    return compareTo(right) < 0;
  }

  bool lessThanLong(Int64 value) {
    return compareToLong(value) < 0;
  }

  bool operator <=(BigInteger right) {
    return compareTo(right) <= 0;
  }

  bool lessThanOrEqualToLong(Int64 value) {
    return compareToLong(value) <= 0;
  }

  bool operator >(BigInteger right) {
    return compareTo(right) > 0;
  }

  bool greaterThanLong(Int64 value) {
    return compareToLong(value) > 0;
  }

  bool operator >=(BigInteger right) {
    return compareTo(right) >= 0;
  }

  bool greaterThanOrEqualToLong(Int64 value) {
    return compareToLong(value) >= 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BigInteger && equals(other);
  }

  bool equalsToLong(Int64 value) {
    return compareToLong(value) == 0;
  }

  bool equals(BigInteger other) {
    if (sign.value != other.sign.value) {
      return false;
    }
    int alen = data.isNotEmpty ? data.length : 0;
    int blen = other.data.isNotEmpty ? other.data.length : 0;

    if (alen != blen) {
      return false;
    }

    for (int i = 0; i < alen; i++) {
      if (data[i] != other.data[i]) {
        return false;
      }
    }

    return true;
  }

  static BigInteger min(BigInteger left, BigInteger right) {
    int ls = left.sign.value;
    int rs = right.sign.value;
    if (ls < rs) {
      return left;
    }

    if (rs < ls) {
      return right;
    }

    Int32 r = _coreCompare(left.data, right.data);
    if (ls == -1) {
      r = Int32(-r.value);
    }

    if (r.value <= 0) {
      return left;
    }

    return right;
  }

  static BigInteger max(BigInteger left, BigInteger right) {
    int ls = left.sign.value;
    int rs = right.sign.value;
    if (ls > rs) {
      return left;
    }

    if (rs > ls) {
      return right;
    }

    Int32 r = _coreCompare(left.data, right.data);

    if (ls == -1) {
      r = Int32(-r.value);
    }

    if (r.value >= 0) {
      return left;
    }

    return right;
  }

  static BigInteger abs(BigInteger value) {
    return BigInteger._internal(Int16(value.sign.value.abs()), value.data);
  }

  static Tuple2<BigInteger, BigInteger> divRem(
      BigInteger dividend, BigInteger divisor) {
    if (divisor.sign.value == 0) {
      throw UnsupportedError("Divide by zero");
    }

    if (dividend.sign.value == 0) {
      return Tuple2(dividend, dividend);
    }

    var result = divModUnsigned(dividend.data, divisor.data);
    List<UInt32> quotientValue = result.item1;
    List<UInt32> remainderValue = result.item2;

    BigInteger remainder;
    BigInteger quotient;

    int i;
    for (i = remainderValue.length - 1;
        i >= 0 && remainderValue[i] == UInt32(0);
        --i) {}
    if (i == -1) {
      remainder = zero;
    } else {
      if (i < remainderValue.length - 1) {
        remainderValue = _resize(remainderValue, i + 1);
      }
      remainder = BigInteger._internal(dividend.sign, remainderValue);
    }

    for (i = quotientValue.length - 1;
        i >= 0 && quotientValue[i] == UInt32(0);
        --i) {}

    if (i == -1) {
      quotient = zero;
      return Tuple2(quotient, remainder);
    }

    if (i < quotientValue.length - 1) {
      quotientValue = _resize(quotientValue, i + 1);
    }

    quotient = BigInteger._internal(dividend.sign, quotientValue);

    return Tuple2(quotient, remainder);
  }

  // Pow, ModPow, GCD
  static BigInteger pow(BigInteger value, int exponent) {
    if (exponent < 0) {
      throw ArgumentError("exp must be >= o", "exponent");
    }

    if (exponent == 0) {
      return one;
    }
    if (exponent == 1) {
      return value;
    }

    BigInteger result = one;
    while (exponent != 0) {
      if ((exponent & 1) != 0) {
        result = result * value;
      }
      if (exponent == 1) {
        break;
      }

      value = value * value;
      exponent >>= 1;
    }
    return result;
  }

  static BigInteger modPow(
      BigInteger value, BigInteger exponent, BigInteger modulus) {
    if (exponent.sign.value == -1) {
      throw ArgumentError("power must be >= o", "exponent");
    }
    if (modulus.sign.value == 0) {
      throw UnsupportedError("Division by zero");
    }
    BigInteger result = one % modulus;
    print("One...Three...One...One...One");
    print("One...Three...One...One...Two, $value, $exponent, $modulus");
    while (exponent.sign != Int16(0)) {
      print("In ModPow While:");
      
      if (!exponent.isEven) {
        print("In ModPow While Not Even result * value:");
        result = result * value;
        print("In ModPow While Not Even result % value:");
        result = result % modulus;
      }
      // sign == Int16(1) && data.length == 1 && data[0] == UInt32(1)
      if (exponent.isOne) {
        break;
      }
      
      // print("One...Three...One...One...Two, ${exponent.sign.value}, ${exponent.data.length}, ${exponent.data[0].value}, $value, $exponent, $modulus");
      value = value * value;
      print("In ModPow While After value * value:");
      value = value % modulus;
      print("In ModPow While After value % modulus:");
      exponent = exponent >> 1;
    }

    print("In ModPow: $result");
    return result;
  }

  static BigInteger greatestCommonDivisor(BigInteger left, BigInteger right) {
    if (left.sign.value != 0 &&
        left.data.length == 1 &&
        left.data[0] == UInt32(1)) {
      return one;
    }
    if (right.sign.value != 0 &&
        right.data.length == 1 &&
        right.data[0] == UInt32(1)) {
      return one;
    }

    if (left.isZero) {
      return abs(right);
    }

    if (right.isZero) {
      return abs(left);
    }

    BigInteger x = BigInteger._internal(Int16(1), left.data);
    BigInteger y = BigInteger._internal(Int16(1), right.data);

    BigInteger g = y;
    while (x.data.length > 1) {
      g = x;
      x = y % x;
      y = g;
    }
    if (x.isZero) return g;
    //
    // Now we can just do it with single precision. I am using the binary gcd method,
    // as it should be faster.
    //

    UInt32 yy = x.data[0];
    BigInteger bYY = BigInteger.fromInt(yy.value);
    BigInteger bXX = (y % bYY);
    UInt32 xx = UInt32(bXX.toInt());

    int t = 0;

    while (((xx | yy) & UInt32(1)) == UInt32(0)) {
      xx >>= 1;
      yy >>= 1;
      t++;
    }
    while (xx != UInt32(0)) {
      while ((xx & UInt32(1)) == UInt32(0)) {
        xx >>= 1;
      }
      while ((yy & UInt32(1)) == UInt32(0)) {
        yy >>= 1;
      }
      if (xx >= yy) {
        xx = (xx - yy) >> 1;
      } else {
        yy = (yy - xx) >> 1;
      }
    }

    return BigInteger.fromInt(yy.value << t);
  }

  static Exception getFormatException() {
    return FormatException("Input string was not in the correct format");
  }

  static bool _jumpOverWhite(Ref<int> pos, String s, bool reportError,
      bool tryParse, Ref<Exception?> exc) {
    while (pos.value < s.length && s[pos.value].trim().isEmpty) {
      pos.value++;
    }

    if (reportError && pos.value >= s.length) {
      if (!tryParse) {
        exc.value = getFormatException();
      }
      return false;
    }

    return true;
  }

  static bool _findExponent(Ref<int> pos, String s, Ref<int> exponent,
      bool tryParse, Ref<Exception?> exc) {
    exponent.value = 0;
    if (pos.value >= s.length || (s[pos.value] != 'e' && s[pos.value] != 'E')) {
      exc.value = null;
      return false;
    }

    var i = pos.value + 1;
    if (i == s.length) {
      exc.value = tryParse ? null : getFormatException();
      return true;
    }

    bool negative = false;
    if (s[i] == '-') {
      negative = true;
      if (++i == s.length) {
        exc.value = tryParse ? null : getFormatException();
        return true;
      }
    }

    if (s[i] == '+' && ++i == s.length) {
      exc.value = tryParse ? null : getFormatException();
      return true;
    }

    int exp = 0; // temp int value
    for (; i < s.length; i++) {
      if (!_isDigit(s[i])) {
        exc.value = tryParse ? null : getFormatException();
        return true;
      }

      // Reduce the risk of throwing an overflow exception
      exp = exp * 10 - (s.codeUnitAt(i) - '0'.codeUnitAt(0));
      if (exp < -2147483648 || exp > 2147483647) {
        exc.value =
            tryParse ? null : Exception("Value too large or too small.");
        return true;
      }
    }

    // exp value saved as negative
    if (!negative) exp = -exp;

    exc.value = null;
    exponent.value = exp;
    pos.value = i;
    return true;
  }

  static bool _isDigit(String s) {
    if (s.length != 1) return false;
    return int.tryParse(s) != null;
  }

  static bool _findOther(Ref<int> pos, String s, String other) {
    if ((pos.value + other.length) <= s.length &&
        s.substring(pos.value, pos.value + other.length) == other) {
      pos.value += other.length;
      return true;
    }

    return false;
  }

  static bool _validDigit(String e, bool allowHex) {
    if (e.length != 1) return false;
    if (allowHex) {
      return _isDigit(e) ||
          (e.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
              e.codeUnitAt(0) <= 'F'.codeUnitAt(0)) ||
          (e.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
              e.codeUnitAt(0) <= 'f'.codeUnitAt(0));
    }

    return _isDigit(e);
  }

  static bool _processTrailingWhitespace(
      bool tryParse, String s, int position, Ref<Exception> exc) {
    int len = s.length;
    for (int i = position; i < len; i++) {
      String c = s[i];

      if (c != '\u0000' && !_isWhitespace(c)) {
        if (!tryParse) {
          exc.value = getFormatException();
        }
        return false;
      }
    }
    return true;
  }

  static bool _isWhitespace(String c) {
    return c.trim().isEmpty;
  }

  static BigInteger parse(String value, {bool hex = false}) {    
    Ref<Exception?> exc = Ref(null);
    Ref<BigInteger> result = Ref(BigInteger.zero);
    if (!_parse(value, false, result, exc, hex)) {
      throw exc.value!;
    }
    return result.value;
  }

  static bool tryParse(String value, Ref<BigInteger> result,
      {bool hex = false}) {
    Ref<Exception?> exc = Ref(null);
    return _parse(value, true, result, exc, hex);
  }

  static bool _parse(String s, bool tryParse, Ref<BigInteger> result,
      Ref<Exception?> exc, bool hex) {
    result.value = BigInteger.zero;
    exc.value = null;

    if (s.isEmpty) {
      if (!tryParse) {
        exc.value = getFormatException();
      }
      return false;
    }

    Ref<int> pos = Ref(0);

    if (!_jumpOverWhite(pos, s, true, tryParse, exc)) return false;

    bool negative = false;
    if (s[pos.value] == '-') {
      negative = true;
      pos.value++;
    }

    if (s.startsWith('0x') || s.startsWith('0X')) {
      hex = true;
      pos.value += 2;
    }

    BigInteger number = BigInteger.zero;
    bool firstHexDigit = true;

    while (pos.value < s.length) {
      if (!_validDigit(s[pos.value], hex)) break;

      int digitValue;
      if (_isDigit(s[pos.value])) {
        digitValue = s.codeUnitAt(pos.value) - '0'.codeUnitAt(0);
      } else if (hex &&
          s.codeUnitAt(pos.value) >= 'a'.codeUnitAt(0) &&
          s.codeUnitAt(pos.value) <= 'f'.codeUnitAt(0)) {
        digitValue = 10 + s.codeUnitAt(pos.value) - 'a'.codeUnitAt(0);
      } else if (hex &&
          s.codeUnitAt(pos.value) >= 'A'.codeUnitAt(0) &&
          s.codeUnitAt(pos.value) <= 'F'.codeUnitAt(0)) {
        digitValue = 10 + s.codeUnitAt(pos.value) - 'A'.codeUnitAt(0);
      } else {
        break;
      }

      // if (firstHexDigit && digitValue >= 8) negative = true;
      // Correct handling for negative flag
      if (hex && firstHexDigit && digitValue >= 8 && !negative) negative = true;

      // print("Value in BigInteger.parse: $digitValue");

      int base = hex ? 16 : 10;
      number =
          number * BigInteger.fromInt(base) + BigInteger.fromInt(digitValue);          
      firstHexDigit = false;
      pos.value++;

    }
    // print("Value in BigInteger.parse 1: $s, $number, $negative");
    if (negative && !hex) {
      BigInteger mask = (BigInteger.fromInt(1) << (4 * number.data.length)) -
          BigInteger.fromInt(1);
      number = (number ^ mask) + BigInteger.fromInt(1);
      // print("Value in BigInteger.parse 2: $s, $number");
    }

    result.value = number;
    // print("Value in BigInteger.parse 3: $s, $number");

    return true;
  }

  static double log(BigInteger value, double baseValue) {
    if (value.sign.value == -1 ||
        baseValue == 1.0 ||
        baseValue == -1.0 ||
        baseValue == double.negativeInfinity ||
        baseValue.isNaN) {
      return double.nan;
    }

    if (baseValue == 0.0 || baseValue == double.infinity) {
      return value.isOne ? 0 : double.nan;
    }

    if (value.data.isEmpty) {
      return double.negativeInfinity;
    }

    int length = value.data.length - 1;
    int bitCount = -1;
    for (int curBit = 31; curBit >= 0; curBit--) {
      if ((value.data[length].value & (1 << curBit)) != 0) {
        bitCount = curBit + length * 32;
        break;
      }
    }

    int bitlen = bitCount;
    double c = 0, d = 1;

    BigInteger testBit = BigInteger.one;
    int tempBitlen = bitlen;
    while (tempBitlen > 0x7FFFFFFF) {
      testBit = testBit << 0x7FFFFFFF;
      tempBitlen -= 0x7FFFFFFF;
    }
    testBit = testBit << tempBitlen;

    for (int curbit = bitlen; curbit >= 0; --curbit) {
      if ((value & testBit).sign != Int16(0)) {
        c += d;
      }
      d *= 0.5;
      testBit = testBit >> 1;
    }
    return (math.log(c) + math.log(2) * bitlen) / math.log(baseValue);
  }

  static double logE(BigInteger value) {
    return log(value, math.e);
  }

  static double log10(BigInteger value) {
    return log(value, 10);
  }

  int longCompare(UInt32 low, UInt32 high) {
    UInt32 h = UInt32(0);

    if (data.length > 1) {
      h = data[1];
    }

    if (h > high) {
      return 1;
    }

    if (h < high) {
      return -1;
    }

    UInt32 l = data[0];

    if (l > low) {
      return 1;
    }
    if (l < low) {
      return -1;
    }

    return 0;
  }

  int compareToLong(Int64 other) {
    Int16 ls = sign;
    Int16 rs = Int16(other.value.sign);

    if (ls != rs) {
      return ls > rs ? 1 : -1;
    }

    if (ls == Int16(0)) {
      return 0;
    }

    if (data.length > 2) {
      return sign.value;
    }

    if (other.value < 0) {
      other = Int64(-other.value);
    }

    UInt32 low = UInt32(other.value);
    UInt32 high = UInt32((UInt64(other.value) >> 32).value);

    int r = longCompare(low, high);
    if (ls == Int16(-1)) {
      r = -r;
    }

    return r;
  }

  @override
  int compareTo(BigInteger other) {
    int ls = sign.value;
    int rs = other.sign.value;

    if (ls != rs) {
      return ls > rs ? 1 : -1;
    }
    Int32 r = _coreCompare(data, other.data);
    if (ls < 0) {
      r = Int32(-r.value);
    }

    return r.value;
  }

  static int _topByte(UInt32 x) {
    if ((x & UInt32(0xFFFF0000)) != UInt32(0)) {
      if ((x & UInt32(0xFF000000)) != UInt32(0)) {
        return 4;
      }
      return 3;
    }
    if ((x & UInt32(0xFF00)) != UInt32(0)) {
      return 2;
    }
    return 1;
  }

  static int _firstNonFFByte(UInt32 word) {
    if ((word & UInt32(0xFF000000)) != UInt32(0xFF000000)) {
      return 4;
    } else if ((word & UInt32(0xFF0000)) != UInt32(0xFF0000)) {
      return 3;
    } else if ((word & UInt32(0xFF00)) != UInt32(0xFF00)) {
      return 2;
    }
    return 1;
  }

  Uint8List toByteArray() {
    if (sign == Int16(0)) {
      return Uint8List(1);
    }

    // number of bytes not counting upper word
    int bytes = (data.length - 1) * 4;
    bool needExtraZero = false;

    UInt32 topWord = data[data.length - 1];
    int extra;

    // if the topmost bit is set we need an extra
    if (sign == Int16(1)) {
      extra = _topByte(topWord);
      UInt32 mask = UInt32(0x80) << ((extra - 1) * 8);
      if ((topWord & mask) != UInt32(0)) {
        needExtraZero = true;
      }
    } else {
      extra = _topByte(topWord);
    }

    Uint8List res = Uint8List(bytes + extra + (needExtraZero ? 1 : 0));
    if (sign == Int16(1)) {
      int j = 0;
      int end = data.length - 1;
      for (int i = 0; i < end; ++i) {
        UInt32 word = data[i];

        res[j++] = word.value & 0xFF;
        res[j++] = (word.value >> 8) & 0xFF;
        res[j++] = (word.value >> 16) & 0xFF;
        res[j++] = (word.value >> 24) & 0xFF;
      }
      while (extra-- > 0) {
        res[j++] = topWord.value & 0xFF;
        topWord >>= 8;
      }
    } else {
      int j = 0;
      int end = data.length - 1;

      UInt32 carry = UInt32(1), word;
      UInt64 add;
      for (int i = 0; i < end; ++i) {
        word = data[i];
        add = UInt64(~word.value) + UInt64(carry.value);
        word = UInt32(add.value);
        carry = UInt32(add.value >> 32);

        res[j++] = word.value & 0xFF;
        res[j++] = (word.value >> 8) & 0xFF;
        res[j++] = (word.value >> 16) & 0xFF;
        res[j++] = (word.value >> 24) & 0xFF;
      }

      add = UInt64(~topWord.value) + UInt64(carry.value);
      word = UInt32(add.value);
      carry = UInt32(add.value >> 32);
      if (carry == UInt32(0)) {
        int ex = _firstNonFFByte(word);
        bool needExtra = (word.value & (1 << (ex * 8 - 1))) == 0;
        int to = ex + (needExtra ? 1 : 0);

        if (to != extra) {
          res = _resizeToByteArray(res, bytes + to);
        }

        while (ex-- > 0) {
          res[j++] = word.value & 0xFF;
          word >>= 8;
        }
        if (needExtra) {
          res[j++] = 0xFF;
        }
      } else {
        res = _resizeToByteArray(res, bytes + 5);
        res[j++] = word.value & 0xFF;
        res[j++] = (word.value >> 8) & 0xFF;
        res[j++] = (word.value >> 16) & 0xFF;
        res[j++] = (word.value >> 24) & 0xFF;
        res[j++] = 0xFF;
      }
    }

    return res;
  }

  Uint8List _resizeToByteArray(Uint8List v, int len) {
    Uint8List res = Uint8List(len);
    int copyLength = math.min(v.length, len);
    for (int i = 0; i < copyLength; i++) {
      res[i] = v[i];
    }
    return res;
  }

  static List<UInt32> _resize(List<UInt32> v, int len) {
    List<UInt32> res = List<UInt32>.filled(len, UInt32(0), growable: false);
    int lengthToCopy = v.length < len ? v.length : len;
    for (int i = 0; i < lengthToCopy; i++) {
      res[i] = v[i];
    }
    return res;
  }

  static List<UInt32> _coreAddList(List<UInt32> a, List<UInt32> b) {
    if (a.length < b.length) {
      List<UInt32> tmp = a;
      a = b;
      b = tmp;
    }

    int bl = a.length;
    int sl = b.length;

    List<UInt32> res = List<UInt32>.filled(bl, UInt32(0), growable: false);

    UInt64 sum = UInt64(0);

    int i = 0;
    for (; i < sl; i++) {
      sum = sum + UInt64(a[i].value) + UInt64(b[i].value);
      res[i] = UInt32(sum.value);
      sum >>= 32;
    }

    for (; i < bl; i++) {
      sum = sum + UInt64(a[i].value);
      res[i] = UInt32(sum.value);
      sum >>= 32;
    }

    if (sum != UInt64(0)) {
      res = _resize(res, bl + 1);
      res[i] = UInt32(sum.value);
    }

    return res;
  }

  static List<UInt32> _coreSubList(List<UInt32> a, List<UInt32> b) {
    int al = a.length;
    int bl = b.length;

    List<UInt32> res = List<UInt32>.filled(al, UInt32(0), growable: false);

    UInt64 borrow = UInt64(0);
    int i = 0;

    for (i = 0; i < bl; ++i) {
      borrow = UInt64(a[i].value) - UInt64(b[i].value) - borrow;
      res[i] = UInt32(borrow.value);
      borrow = (borrow >> 32) & UInt64(0x1);
    }

    for (; i < bl; i++) {
      borrow = UInt64(a[i].value) - borrow;
      res[i] = UInt32(borrow.value);
      borrow = (borrow >> 32) & UInt64(0x1);
    }

    //remove extra zeroes.
    for (i = bl - 1; i >= 0 && res[i] == UInt32(0); --i) {}
    if (i < bl - 1) {
      res = _resize(res, i + 1);
    }

    return res;
  }

  static List<UInt32> _coreAdd(List<UInt32> a, int b) {
    int len = a.length;
    List<UInt32> res = List<UInt32>.filled(len, UInt32(0), growable: false);

    UInt64 sum = UInt64(b);
    int i = 0;

    for (i = 0; i < len; i++) {
      sum = sum + UInt64(a[i].value);
      res[i] = UInt32(sum.value);
      sum >>= 32;
    }

    if (sum != UInt64(0)) {
      res = _resize(res, len + 1);
      res[i] = UInt32(sum.value);
    }

    return res;
  }

  static List<UInt32> _coreSub(List<UInt32> a, int b) {
    int len = a.length;
    List<UInt32> res = List<UInt32>.filled(len, UInt32(0), growable: false);
    UInt64 borrow = UInt64(b);
    int i = 0;
    for (i = 0; i < len; i++) {
      borrow = UInt64(a[i].value) - borrow;
      res[i] = UInt32(borrow.value);
      borrow = (borrow >> 32) & UInt64(0x1);
    }

    //remove extra zeroes.
    for (i = len - 1; i >= 0 && res[i] == UInt32(0); --i) {}
    if (i < len - 1) {
      res = _resize(res, i + 1);
    }

    return res;
  }

  static Int32 _coreCompare(List<UInt32> a, List<UInt32> b) {
    int al = a.isNotEmpty ? a.length : 0;
    int bl = b.isNotEmpty ? b.length : 0;

    if (al > bl) {
      return Int32(1);
    } else if (al < bl) {
      return Int32(-1);
    }

    for (int i = al - 1; i >= 0; --i) {
      if (a[i] > b[i]) {
        return Int32(1);
      } else if (a[i] < b[i]) {
        return Int32(-1);
      }
    }

    return Int32(0);
  }

  static int _getNormalizedShift(UInt32 value) {
    int shift = 0;

    if ((value.value & 0xFFFF0000) == 0) {
      value <<= 16;
      shift += 16;
    }
    if ((value.value & 0xFF000000) == 0) {
      value <<= 8;
      shift += 8;
    }
    if ((value.value & 0xF0000000) == 0) {
      value <<= 4;
      shift += 4;
    }
    if ((value.value & 0xC0000000) == 0) {
      value <<= 2;
      shift += 2;
    }
    if ((value.value & 0x80000000) == 0) {
      value <<= 1;
      shift += 1;
    }

    return shift;
  }

  static void _normalize(List<UInt32> u, int l, List<UInt32> un, int shift) {
    UInt32 carry = UInt32(0);
    int i;
    if (shift > 0) {
      int rshift = 32 - shift;
      for (i = 0; i < l; i++) {
        UInt32 ui = u[i];
        un[i] = (ui << shift) | carry;
        carry = ui >> rshift;
      }
    } else {
      for (i = 0; i < l; i++) {
        un[i] = u[i];
      }
    }

    while (i < un.length) {
      un[i++] = UInt32(0);
    }

    if (carry != UInt32(0)) {
      un[l] = carry;
    }
  }

  static List<UInt32> _unnormalize(List<UInt32> un, int shift) {
    int length = un.length;
    List<UInt32> r = List.filled(length, UInt32(0), growable: false);

    if (shift > 0) {
      int lshift = 32 - shift;
      UInt32 carry = UInt32(0);
      for (int i = length - 1; i >= 0; i--) {
        UInt32 uni = un[i];
        r[i] = (uni >> shift) | carry;
        carry = (uni << lshift);
      }
    } else {
      for (int i = 0; i < length; i++) {
        r[i] = un[i];
      }
    }

    return r;
  }

  static const UInt64 _base = UInt64(0x100000000);

  static Tuple2<List<UInt32>, List<UInt32>> divModUnsigned(
      List<UInt32> u, List<UInt32> v) {
    int m = u.length;
    int n = v.length;

    if (n <= 1) {
      UInt64 rem = UInt64(0);
      UInt32 v0 = v[0];

      List<UInt32> q = List.filled(m, UInt32(0), growable: false);
      List<UInt32> r = List.filled(1, UInt32(0), growable: false);

      for (int j = m - 1; j >= 0; j--) {
        rem *= _base;
        rem += UInt64(u[j].value);

        UInt64 div = rem / UInt64(v0.value);
        rem -= div * UInt64(v0.value);
        q[j] = UInt32(div.value);
      }
      r[0] = UInt32(rem.value);

      return Tuple2(q, r);
    } else if (m >= n) {
      Int32 shift = Int32(_getNormalizedShift(v[n - 1]));
      List<UInt32> un = List.filled(m + 1, UInt32(0), growable: false);
      List<UInt32> vn = List.filled(n, UInt32(0), growable: false);

      _normalize(u, m, un, shift.value);
      _normalize(v, n, vn, shift.value);

      List<UInt32> q = List.filled(m - n + 1, UInt32(0), growable: false);
      // List<UInt32> r = [];

      // Main division loop
      for (int j = m - n; j >= 0; j--) {
        UInt64 rr, qq;
        int i;

        rr = _base * UInt64(un[j + n].value) + UInt64(un[j + n - 1].value);
        qq = rr / UInt64(vn[n - 1].value);
        rr -= qq * UInt64(vn[n - 1].value);

        for (;;) {
          if ((qq >= _base) ||
              (qq * UInt64(vn[n - 2].value) >
                  (rr * _base + UInt64(un[j + n - 2].value)))) {
            qq -= UInt64(1);
            rr += UInt64(vn[n - 1].value);

            if (rr < _base) {
              continue;
            }
          }
          break;
        }

        //  Multiply and subtract
        int b = 0;
        int t = 0;
        for (i = 0; i < n; i++) {
          UInt64 p = UInt64(vn[i].value) * qq;
          t = (UInt64(un[i + j].value) - p).value - b;
          un[i + j] = UInt32(t);
          p >>= 32;
          t >>= 32;
          b = (p - UInt64(t)).value;
        }

        t = un[j + n].value - b;
        un[j + n] = UInt32(t);

        q[j] = UInt32(qq.value);

        if (t < 0) {
          q[j] = q[j] - UInt32(1);
          UInt64 c = UInt64(0);
          for (i = 0; i < n; i++) {
            c = UInt64(vn[i].value) + UInt64(un[j + i].value) + c;
            un[j + i] = UInt32(c.value);
            c >>= 32;
          }
          c = c + UInt64(un[j + n].value);
          un[j + n] = UInt32(c.value);
        }
      }
      var retR = _unnormalize(un, shift.value);

      return Tuple2(q, retR);
    } else {
      return Tuple2([UInt32(0)], u);
    }
  }

  @override
  int get hashCode {
    int hash = sign.value * 0x01010101;
    int len = data.isNotEmpty ? data.length : 0;

    for (int i = 0; i < len; ++i) {
      hash ^= data[i].value;
    }
    return hash;
  }

  @override
  String toString() {
    return _toStringWithRadix(UInt32(10));
  }

  String toHexString() {
    return _toStringWithRadix(UInt32(16)).replaceFirst(RegExp(r'[\s0]'), '');
  }

  static List<UInt32> _makeTwoComplement(List<UInt32> v) {
    List<UInt32> res = List.filled(v.length, UInt32(0), growable: false);
    UInt64 carry = UInt64(1);
    for (int i = 0; i < v.length; ++i) {
      UInt32 word = v[i];
      carry = UInt64(~word.value) + carry;
      word = UInt32(carry.value);
      carry = UInt64((carry.value >> 32) & UInt32.mask);
      res[i] = word;
    }

    UInt32 last = res[res.length - 1];
    int idx = _firstNonFFByte(last);
    UInt32 mask = UInt32(0xFF);

    for (int i = 1; i < idx; ++i) {
      mask = (mask << 8) | UInt32(0xFF);
    }

    res[res.length - 1] = last & mask;
    return res;
  }

  String _toStringWithRadix(UInt32 radix) {
    const String characterSet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    if (characterSet.length < radix.value) {
      throw ArgumentError("charSet length less than radix");
    }
    if (radix.value == 1) {
      throw ArgumentError("There is no such thing as radix one notation");
    }

    if (sign.value == 0) {
      return "0";
    }
    if (data.length == 1 && data[0].value == 1) {
      return sign.value == 1 ? "1" : "-1";
    }

    List<String> digits = [];

    BigInteger a;
    if (sign.value == 1) {
      a = this;
    } else {
      List<UInt32> dt = data;
      if (radix.value > 10) {
        dt = _makeTwoComplement(dt);
      }
      a = BigInteger._internal(Int16(1), dt);
    }

    while (a != BigInteger.zero) {
      var radInteger = BigInteger.fromInt(radix.value);
      var divRemResult = divRem(a, radInteger);
      a = divRemResult.item1;
      var rem = divRemResult.item2;
      digits.add(characterSet[rem.toInt()]);
    }

    if (sign.value == -1 && radix.value == 10) {
      digits.add('-');
    }

    String last = digits.last;
    if (sign.value == 1 &&
        radix.value > 10 &&
        (last.compareTo('0') < 0 || last.compareTo('9') > 0)) {
      digits.add('0');
    }

    return digits.reversed.join();
  }
}
