class Int32 {
  final int _value;
  static const int _mask = 0xFFFFFFFF;

  const Int32(int value) : _value = value & _mask;

  int get value => _value >= 0x80000000 ? _value - 0x100000000 : _value;
  static int get mask => _mask;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Int32 && _value == other._value;
  }

  @override
  int get hashCode => _value.hashCode;

  Int32 operator +(Int32 other) {
    return Int32((_value + other._value) & _mask);
  }

  Int32 operator -(Int32 other) {
    return Int32((_value - other._value) & _mask);
  }

  Int32 operator *(Int32 other) {
    return Int32((_value * other._value) & _mask);
  }

  Int32 operator /(Int32 other) {
    return Int32((_value ~/ other._value) & _mask);
  }

  Int32 operator &(Int32 other) {
    return Int32(_value & other._value);
  }

  Int32 operator |(Int32 other) {
    return Int32(_value | other._value);
  }

  Int32 operator ^(Int32 other) {
    return Int32(_value ^ other._value);
  }

  Int32 operator <<(int shift) {
    return Int32((_value << shift) & _mask);
  }

  Int32 operator >>(int shift) {
    return Int32(_value >> shift);
  }

  Int32 operator ~() {
    return Int32((~_value) & _mask);
  }
  

  bool operator >(Int32 other) {
    return value > other.value;
  }

  bool operator <(Int32 other) {
    return value < other.value;
  }

  bool operator >=(Int32 other) {
    return value >= other.value;
  }

  bool operator <=(Int32 other) {
    return value <= other.value;
  }

  static List<Int32> fromIntList(List<int> list){
    var iList = list.map( (toElement) {
      return Int32(toElement);
    });
    return iList.toList();
  }

  static List<int> toIntList(List<Int32> list){
    var iList = list.map( (toElement) {
      return toElement.value;
    });
    return iList.toList();
  }


  @override
  String toString() => value.toString();
}
