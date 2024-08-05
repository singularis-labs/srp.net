
class UInt32 {
  static const int _mask = 0xFFFFFFFF;
  final int _value;

  const UInt32(int value) : _value = value & _mask;

  int get value => _value & _mask;
  static int get mask => _mask;

  int get maskedValue => _value & mask;

  UInt32 operator +(UInt32 other) {
    return UInt32((_value + other._value) & _mask);
  }

  UInt32 operator -(UInt32 other) {
    return UInt32((_value - other._value) & _mask);
  }

  UInt32 operator *(UInt32 other) {
    return UInt32((_value * other._value) & _mask);
  }

  UInt32 operator /(UInt32 other) {
    if (other._value == 0) {
      throw UnsupportedError("Division by Zero");
    }
    return UInt32(_value ~/ other._value);
  }

  UInt32 operator &(UInt32 other) {
    return UInt32(_value & other._value);
  }

  UInt32 operator |(UInt32 other) {
    return UInt32(_value | other._value);
  }

  UInt32 operator ^(UInt32 other) {
    return UInt32(_value ^ other._value);
  }

  UInt32 operator <<(int shiftAmount) {
    return UInt32((_value << shiftAmount) & _mask);
  }

  UInt32 operator >>(int shiftAmount) {
    return UInt32(_value >> shiftAmount);
  }

  UInt32 operator ~() {
    return UInt32((~_value) & _mask);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UInt32 && _value == other._value;
  }

  bool operator >(UInt32 other) {
    return _value > other._value;
  }

  bool operator <(UInt32 other) {
    return _value < other._value;
  }

  bool operator >=(UInt32 other) {
    return _value >= other._value;
  }

  bool operator <=(UInt32 other) {
    return _value <= other._value;
  }

  static List<UInt32> fromIntList(List<int> list){
    var iList = list.map( (toElement) {
      return UInt32(toElement);
    });
    return iList.toList();
  }

  static List<int> toIntList(List<UInt32> list){
    var iList = list.map( (toElement) {
      return toElement.value;
    });
    return iList.toList();
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value.toString();
}


