class Int16 {
  final int _value;
  static const int _mask = 0xFFFF;

  const Int16(int value) : _value = value & _mask;

   int get value => _value >= 0x8000 ? _value - 0x10000 : _value;

   static int get mask => _mask;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Int16 && _value == other._value;
  }

  @override
  int get hashCode => _value.hashCode;

  Int16 operator +(Int16 other) {
    return Int16((_value + other._value) & _mask);
  }

  Int16 operator -(Int16 other) {
    return Int16((_value - other._value) & _mask);
  }

  Int16 operator *(Int16 other) {
    return Int16((_value * other._value) & _mask);
  }

  Int16 operator /(Int16 other) {
    return Int16((_value ~/ other._value) & _mask);
  }

  Int16 operator &(Int16 other) {
    return Int16(_value & other._value);
  }

  Int16 operator |(Int16 other) {
    return Int16(_value | other._value);
  }

  Int16 operator ^(Int16 other) {
    return Int16(_value ^ other._value);
  }

  Int16 operator <<(int shift) {
    return Int16((_value << shift) & _mask);
  }

  Int16 operator >>(int shift) {
    return Int16(_value >> shift);
  }

  Int16 operator ~() {
    return Int16((~_value) & _mask);
  }

  bool operator >(Int16 other) {
    return value > other.value;
  }

  bool operator <(Int16 other) {
    return value < other.value;
  }

  bool operator >=(Int16 other) {
    return value >= other.value;
  }

  bool operator <=(Int16 other) {
    return value <= other.value;
  }

  static List<Int16> fromIntList(List<int> list){
    var iList = list.map( (toElement) {
      return Int16(toElement);
    });
    return iList.toList();
  }

  static List<int> toIntList(List<Int16> list){
    var iList = list.map( (toElement) {
      return toElement.value;
    });
    return iList.toList();
  }

  @override
  String toString() => value.toString();
}
