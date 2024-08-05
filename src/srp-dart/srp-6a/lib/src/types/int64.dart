class Int64 {
  final int _value;
  static const int _mask = 0xFFFFFFFFFFFFFFFF;

  const Int64(int value) : _value = value & _mask;

  int get value => _value >= 0x8000000000000000 ? _value - (1 << 64) : _value;
  static int get mask => _mask;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Int64 && _value == other._value;
  }

  @override
  int get hashCode => _value.hashCode;

  Int64 operator +(Int64 other) {
    return Int64((_value + other._value) & _mask);
  }

  /* Int64 operator +(int other) {
    return Int64((_value + other) & _mask);
  } */

  Int64 operator -(Int64 other) {
    return Int64((_value - other._value) & _mask);
  }

  Int64 operator *(Int64 other) {
    return Int64((_value * other._value) & _mask);
  }

  Int64 operator /(Int64 other) {
    return Int64((_value ~/ other._value) & _mask);
  }

  Int64 operator &(Int64 other) {
    return Int64(_value & other._value);
  }

  Int64 operator |(Int64 other) {
    return Int64(_value | other._value);
  }

  Int64 operator ^(Int64 other) {
    return Int64(_value ^ other._value);
  }

  Int64 operator <<(int shift) {
    return Int64((_value << shift) & _mask);
  }

  Int64 operator >>(int shift) {
    return Int64(_value >> shift);
  }

  Int64 operator ~() {
    return Int64((~_value) & _mask);
  }

  bool operator >(Int64 other) {
    return value > other.value;
  }

  bool operator <(Int64 other) {
    return value < other.value;
  }

  bool operator >=(Int64 other) {
    return value >= other.value;
  }

  bool operator <=(Int64 other) {
    return value <= other.value;
  }

  static List<Int64> fromIntList(List<int> list){
    var iList = list.map( (toElement) {
      return Int64(toElement);
    });
    return iList.toList();
  }

  static List<int> toIntList(List<Int64> list){
    var iList = list.map( (toElement) {
      return toElement.value;
    });
    return iList.toList();
  }

  @override
  String toString() => value.toString();
}
