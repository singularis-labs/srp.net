import 'package:srp_6a/src/srp_types/srp_integer.dart';
import 'srp_parameters.dart';

  bool isValidInteger(String hexString, int requiredLength) {
    if (hexString.isEmpty || hexString.length != requiredLength) {
      return false;
    }
    try {
      var _ = SrpInteger(hexString);
      return true;
    } catch (e) {
      return false;
    }
  }

bool isValidSalt(String salt, SrpParameters parameters){
  return isValidInteger(salt, parameters.hashSizeBytes * 2);
}

bool isValidVerifier(String salt, SrpParameters parameters){
  return isValidInteger(salt, parameters.paddedLength);
}


