class UInt64 {
  static const int _mask = 0xFFFFFFFFFFFFFFFF;
  final int _value;

  const UInt64(int value) : _value = value & _mask;

  int get value => _value & _mask;
  static int get mask => _mask;

  UInt64 operator +(UInt64 other) {
    return UInt64((_value + other._value) & _mask);
  }

  UInt64 operator -(UInt64 other) {
    return UInt64((_value - other._value) & _mask);
  }

  UInt64 operator *(UInt64 other) {
    return UInt64((_value * other._value) & _mask);
  }

  UInt64 operator /(UInt64 other) {
    if (other._value == 0) {
      throw UnsupportedError("Division by Zero");
    }
    return UInt64(_value ~/ other._value);
  }

  UInt64 operator &(UInt64 other) {
    return UInt64(_value & other._value);
  }

  UInt64 operator |(UInt64 other) {
    return UInt64(_value | other._value);
  }

  UInt64 operator ^(UInt64 other) {
    return UInt64(_value ^ other._value);
  }

  UInt64 operator <<(int shiftAmount) {
    return UInt64((_value << shiftAmount) & _mask);
  }

  UInt64 operator >>(int shiftAmount) {
    return UInt64(_value >> shiftAmount);
  }

  UInt64 operator ~() {
    return UInt64((~_value) & _mask);
  }  
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UInt64 && _value == other._value;
  }

  bool operator >(UInt64 other) {
    return _value > other._value;
  }

  bool operator <(UInt64 other) {
    return _value < other._value;
  }

  bool operator >=(UInt64 other) {
    return _value >= other._value;
  }

  bool operator <=(UInt64 other) {
    return _value <= other._value;
  }

  static List<UInt64> fromIntList(List<int> list){
    var iList = list.map( (toElement) {
      return UInt64(toElement);
    });
    return iList.toList();
  }

  static List<int> toIntList(List<UInt64> list){
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
