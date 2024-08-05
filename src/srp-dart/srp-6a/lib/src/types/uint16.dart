class UInt16 {
  final int _value;
  static const int _mask = 0xFFFF;

  const UInt16(int value) : _value = value & _mask;

   int get value => _value & _mask;
   static int get mask => _mask;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UInt16 && _value == other._value;
  }

  @override
  int get hashCode => _value.hashCode;

  UInt16 operator +(UInt16 other) {
    return UInt16((_value + other._value) & _mask);
  }

  UInt16 operator -(UInt16 other) {
    return UInt16((_value - other._value) & _mask);
  }

  UInt16 operator *(UInt16 other) {
    return UInt16((_value * other._value) & _mask);
  }

  UInt16 operator /(UInt16 other) {
    return UInt16((_value ~/ other._value) & _mask);
  }

  UInt16 operator &(UInt16 other) {
    return UInt16(_value & other._value);
  }

  UInt16 operator |(UInt16 other) {
    return UInt16(_value | other._value);
  }

  UInt16 operator ^(UInt16 other) {
    return UInt16(_value ^ other._value);
  }

  UInt16 operator <<(int shift) {
    return UInt16((_value << shift) & _mask);
  }

  UInt16 operator >>(int shift) {
    return UInt16(_value >> shift);
  }

  UInt16 operator ~() {
    return UInt16((~_value) & _mask);
  }

  bool operator >(UInt16 other) {
    return value > other.value;
  }

  bool operator <(UInt16 other) {
    return value < other.value;
  }

  bool operator >=(UInt16 other) {
    return value >= other.value;
  }

  bool operator <=(UInt16 other) {
    return value <= other.value;
  }

  static List<UInt16> fromIntList(List<int> list){
    var iList = list.map( (toElement) {
      return UInt16(toElement);
    });
    return iList.toList();
  }

  static List<int> toIntList(List<UInt16> list){
    var iList = list.map( (toElement) {
      return toElement.value;
    });
    return iList.toList();
  }

  @override
  String toString() => value.toString();
}
