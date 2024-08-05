import 'package:srp_6a/srp_6a.dart';
import 'srp_parameters.dart';

abstract class ISrpClient {
  /// Generates the random salt of the same size as a used hash.
  /// [saltLength] is an optional, custom salt length specifying the number of bytes. If it is unset,
  /// the `HashSizeBytes` of the hash function from the `Parameters` will be used.
  String generateSalt([int? saltLength]);

  /// Derives the private key from the given salt, user name and password.
  /// [salt] The salt.
  /// [userName] The name of the user.
  /// [password] The password.
  String derivePrivateKey(String salt, String userName, String password);

  /// Derives the verifier from the private key.
  /// [privateKey] The private key.
  String deriveVerifier(String privateKey);

  /// Generates the ephemeral value.
  SrpEphemeral generateEphemeral();

  /// Derives the client session.
  /// [clientSecretEphemeral] The client secret ephemeral.
  /// [serverPublicEphemeral] The server public ephemeral.
  /// [salt] The salt.
  /// [username] The username.
  /// [privateKey] The private key.
  /// Returns: Session key and proof.
  SrpSession deriveSession(String clientSecretEphemeral, String serverPublicEphemeral, String salt, String username, String privateKey);

  /// Verifies the session using the server-provided session proof.
  /// [clientPublicEphemeral] The client public ephemeral.
  /// [clientSession] The client session.
  /// [serverSessionProof] The server session proof.
  void verifySession(String clientPublicEphemeral, SrpSession clientSession, String serverSessionProof);
}

class SrpClient implements ISrpClient {
  /// Initializes a new instance of the [SrpClient] class.
  /// [parameters] The parameters of the SRP-6a protocol.
  SrpClient({SrpParameters? parameters}) : parameters = parameters ?? SrpParameters();

  /// Gets or sets the protocol parameters.
  final SrpParameters parameters;

  /// Generates the random salt of the same size as a used hash.
  /// [saltLength] is an optional, custom salt length specifying the number of bytes. If it is unset,
  /// the `HashSizeBytes` of the hash function from the `Parameters` will be used.
  @override
  String generateSalt([int? saltLength]) {
    var hashSize = saltLength ?? parameters.hashSizeBytes;
    return SrpInteger.randomInteger(hashSize).toHex();
  }

  /// Derives the private key from the given salt, user name and password.
  /// [salt] The salt.
  /// [userName] The name of the user.
  /// [password] The password.
  @override
  String derivePrivateKey(String salt, String userName, String password) {
    // H() — One-way hash function
    var H = parameters.hash;

    // validate the parameters:
    // s — User's salt, hexadecimal
    // I — login
    // p — Cleartext Password
    var s = SrpInteger.fromHex(salt);
    var I = userName;
    var p = password;

    // x = H(s, H(I | ':' | p))  (s is chosen randomly)
    var x = H([s, H(["$I:$p"])]);
    return x.toHex();
  }

  /// Derives the verifier from the private key.
  /// [privateKey] The private key.
  @override
  String deriveVerifier(String privateKey) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    // g — A generator modulo N
    var N = parameters.prime;
    var g = parameters.generator;

    // x — Private key (derived from p and s)
    var x = SrpInteger.fromHex(privateKey);
    print("One...Three...One");

    // v = g^x (computes password verifier)
    var v = g.modPow(x, N);
    print("One...Three...Two");
    return v.toHex();
  }

  /// Generates the ephemeral value.
  @override
  SrpEphemeral generateEphemeral() {
    // A = g^a (a = random number)
    var a = SrpInteger.randomInteger(parameters.hashSizeBytes);
    var A = computeA(a);

    return SrpEphemeral(
      secret: a.toHex(),
      public: A.toHex(),
    );
  }

  /// Computes the public ephemeral value using the specified secret.
  /// [a] Secret ephemeral value.
  SrpInteger computeA(SrpInteger a) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    // g — A generator modulo N
    var N = parameters.prime;
    var g = parameters.generator;

    // A = g^a (a = random number)
    return g.modPow(a, N);
  }

  /// Computes the value of u = H(PAD(A), PAD(B)).
  /// [A] Client public ephemeral value.
  /// [B] Server public ephemeral value.
  SrpInteger computeU(SrpInteger A, SrpInteger B) {
    // H — One-way hash function
    // PAD — Pad the number to have the same number of bytes as N
    var H = parameters.hash;
    var PAD = parameters.pad;

    // u = H(PAD(A), PAD(B))
    return H([PAD(A), PAD(B)]);
  }

  /// Computes S, the premaster-secret.
  /// [a] Client secret ephemeral value.
  /// [B] Server public ephemeral value.
  /// [u] The computed value of u.
  /// [x] The private key.
  SrpInteger computeS(SrpInteger a, SrpInteger B, SrpInteger u, SrpInteger x) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    // g — A generator modulo N
    // k — Multiplier parameter (k = H(N, g) in SRP-6a, k = 3 for legacy SRP-6)
    var N = parameters.prime;
    var g = parameters.generator;
    var k = parameters.multiplier;

    // S = (B - kg^x) ^ (a + ux)
    return (B - (k * g.modPow(x, N))).modPow(a + (u * x), N);
  }

  /// Derives the client session.
  /// [clientSecretEphemeral] The client secret ephemeral.
  /// [serverPublicEphemeral] The server public ephemeral.
  /// [salt] The salt.
  /// [username] The username.
  /// [privateKey] The private key.
  /// Returns: Session key and proof.
  @override
  SrpSession deriveSession(String clientSecretEphemeral, String serverPublicEphemeral, String salt, String username, String privateKey) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    // g — A generator modulo N
    // k — Multiplier parameter (k = H(N, g) in SRP-6a, k = 3 for legacy SRP-6)
    // H — One-way hash function
    var N = parameters.prime;
    var g = parameters.generator;
    var H = parameters.hash;

    // a — Secret ephemeral value
    // B — Public ephemeral value
    // s — User's salt
    // I — Username
    // x — Private key (derived from p and s)
    var a = SrpInteger.fromHex(clientSecretEphemeral);
    var B = SrpInteger.fromHex(serverPublicEphemeral);
    var s = SrpInteger.fromHex(salt);
    var I = username;
    var x = SrpInteger.fromHex(privateKey);

    // A = g^a (a = random number)
    var A = g.modPow(a, N);

    // B % N > 0
    if (B % N == SrpInteger.zero) {
      throw Exception("The server sent an invalid public ephemeral");
    }

    // u = H(PAD(A), PAD(B))
    var u = computeU(A, B);

    // S = (B - kg^x) ^ (a + ux)
    var S = computeS(a, B, u, x);

    // K = H(S)
    var K = H([S]);

    // M1 = H(H(N) xor H(g), H(I), s, A, B, K)
    var M1 = H([H([N]) ^ H([g]), H([I]), s, A, B, K]);

    return SrpSession(
      key: K.toHex(),
      proof: M1.toHex(),
    );
  }

  /// Verifies the session using the server-provided session proof.
  /// [clientPublicEphemeral] The client public ephemeral.
  /// [clientSession] The client session.
  /// [serverSessionProof] The server session proof.
  @override
  void verifySession(String clientPublicEphemeral, SrpSession clientSession, String serverSessionProof) {
    // H — One-way hash function
    var H = parameters.hash;

    // A — Public ephemeral values
    // M — Proof of K
    // K — Shared, strong session key
    var A = SrpInteger.fromHex(clientPublicEphemeral);
    var M = SrpInteger.fromHex(clientSession.proof);
    var K = SrpInteger.fromHex(clientSession.key);

    // H(A, M, K)
    var expected = H([A, M, K]);
    var actual = SrpInteger.fromHex(serverSessionProof);

    if (actual != expected) {
      throw Exception("Server provided session proof is invalid");
    }
  }
}
