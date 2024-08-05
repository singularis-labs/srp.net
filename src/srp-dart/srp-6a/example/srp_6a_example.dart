// import 'package:srp_6a/srp_6a.dart';

import 'package:srp_6a/srp_6a.dart';

import 'srp_test.dart';

void main() {
  /* UInt32 va = UInt32(-10);
  UInt64 ac = UInt64(1);
  print('Result 0: ${~va}');
  UInt64 result1 = UInt64(va.value) + ac;
  UInt64 result2 = UInt64(~va.value & UInt32.mask) + ac;

  print('Result 1: $result1');
  print('Result 2: $result2'); */

  /* var a = BigInteger.fromInt(0xFFFFFFFF);
  var b = BigInteger.fromInt(1);

  var c = a.toByteArray();
  var d = BigInteger.fromByteArray(c);

  print("D From ByteArray: ${d.toHexString()}, $d"); */

  /* var a = BigInteger.fromDouble(60.8);
  var b = BigInteger.fromDouble(10.0); */

  /* print('A: ${a.toHexString()}'); // Should print 1

  print('B: $b'); // Should print 1
  print("A+B: ${a + b}"); //
  print("A-B: ${a - b}"); //
  print("A*B: ${a * b}"); //
  print("A/B: ${a / b}"); //
  print("A%B: ${a % b}"); //

  // Bitwise AND
  print('Bitwise AND: ${a & b}'); // Should print 1

  // Bitwise OR
  print('Bitwise OR: ${a | b}'); // Should print 4294967295

  // Bitwise XOR
  print('Bitwise XOR: ${a ^ b}'); // Should print 4294967294

  // Bitwise NOT
  print('Bitwise NOT A: ${~a}'); // Should print -4294967296

  print('Bitwise NOT B: ${~b}'); // Should print 

  // Left shift
  print('Left shift: ${b << 1}'); // Should print 2

  // Right shift
  print('Right shift: ${a >> 1}'); // Should print 2147483647

  // var x = a.toInt();
  // print("A as int: $x");
  var y = b.toInt();
  print("B as int: $y");

  print("A > B: ${a > b}"); //
  print("A >= B: ${a >= b}"); //
  print("A < B: ${a < b}"); //
  print("A <= B: ${a <= b}"); //
  print("A == B: ${a == b}"); //
 */
  

  /* a = BigInteger.fromDouble(36.8);
  b = BigInteger.fromDouble(24.8);

  print("Double A: ${a}"); //
  print("Double B: ${b}"); // */

  /* print('A: ${a.toHexString()}, $a'); // Should print 1

  var bigNumber = BigInteger.parse("12345678912345661234567891234566123456789123456612345678912345661234567891234566");  
  print("bigNumber: $bigNumber");


  SrpInteger srp = SrpInteger.randomInteger(2048);
  print("SRP Integer: $srp ${srp.toHexString()}");
 */


  var server = SrpLoginServer();
  var client = SrpLoginClient();

  
  // User Registration
  var registration = client.registerUser("user1234", "S!ngular!s@9886");
  
  var userName = registration.item1;
  var password = registration.item2;
  server.register(userName, password);
  

  // Initiate auth.
  var lUser = client.initiateLogin("user1234");
  var initiation = server.initiateLogin(lUser);
  var salt = initiation.item1;
  var serverEphemeralB = initiation.item2;
  

  var response = client.respondToAuth(salt, serverEphemeralB, lUser, "S!ngular!s@9886");
  var clientEphemeral = response.item1;
  var clientProof = response.item2;

  if (clientProof.isEmpty) {
    print("User $lUser is not Authenticated");
    return;
  }

  var serverProof = server.respondToAuthResponse(clientEphemeral, clientProof);
  if (serverProof.isEmpty) {
    print("User $lUser is not Authenticated");
    return;
  }

  var isVerified = client.verifyServerProof(serverProof);
  if (isVerified) {
    print("User $lUser is Authenticated");
  } else {
    print("User $lUser is not Authenticated");
  }

}
