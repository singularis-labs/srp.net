import 'package:srp_6a/srp_6a.dart';
import 'srp_parameters.dart';


abstract class ISrpServer {
  /// Generates the ephemeral value from the given verifier.
  /// [verifier] Verifier.
  SrpEphemeral generateEphemeral(String verifier);

  /// Derives the server session.
  /// [serverSecretEphemeral] The server secret ephemeral.
  /// [clientPublicEphemeral] The client public ephemeral.
  /// [salt] The salt.
  /// [username] The username.
  /// [verifier] The verifier.
  /// [clientSessionProof] The client session proof value.
  /// Returns: Session key and proof.
  SrpSession deriveSession(String serverSecretEphemeral, String clientPublicEphemeral, String salt, String username, String verifier, String clientSessionProof);
}

class SrpServer implements ISrpServer {
  /// Initializes a new instance of the [SrpServer] class.
  /// [parameters] The parameters of the SRP-6a protocol.
  SrpServer({SrpParameters? parameters}) : parameters = parameters ?? SrpParameters();

  /// Gets or sets the protocol parameters.
  final SrpParameters parameters;

  /// Generates the ephemeral value from the given verifier.
  /// [verifier] Verifier.
  @override
  SrpEphemeral generateEphemeral(String verifier) {
    // B = kv + g^b (b = random number)
    var b = SrpInteger.randomInteger(parameters.hashSizeBytes);
    var B = computeB(SrpInteger.fromHex(verifier), b);

    return SrpEphemeral(
      secret: b.toHex(),
      public: B.toHex(),
    );
  }

  /// Generates the public ephemeral value from the given verifier and the secret.
  /// [v] Password verifier.
  /// [b] Secret server ephemeral.
  SrpInteger computeB(SrpInteger v, SrpInteger b) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    // g — A generator modulo N
    // k — Multiplier parameter (k = H(N, g) in SRP-6a, k = 3 for legacy SRP-6)
    var N = parameters.prime;
    var g = parameters.generator;
    var k = parameters.multiplier;

    // B = kv + g^b (b = random number)
    return ((k * v) + g.modPow(b, N)) % N;
  }

  /// Computes S, the premaster-secret.
  /// [A] Client public ephemeral value.
  /// [b] Server secret ephemeral value.
  /// [u] The computed value of u.
  /// [v] The verifier.
  SrpInteger computeS(SrpInteger A, SrpInteger b, SrpInteger u, SrpInteger v) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    var N = parameters.prime;

    // S = (Av^u) ^ b (computes session key)
    return (A * v.modPow(u, N)).modPow(b, N);
  }

  /// Derives the server session.
  /// [serverSecretEphemeral] The server secret ephemeral.
  /// [clientPublicEphemeral] The client public ephemeral.
  /// [salt] The salt.
  /// [username] The username.
  /// [verifier] The verifier.
  /// [clientSessionProof] The client session proof value.
  /// Returns: Session key and proof.
  @override
  SrpSession deriveSession(String serverSecretEphemeral, String clientPublicEphemeral, String salt, String username, String verifier, String clientSessionProof) {
    // N — A large safe prime (N = 2q+1, where q is prime)
    // g — A generator modulo N
    // k — Multiplier parameter (k = H(N, g) in SRP-6a, k = 3 for legacy SRP-6)
    // H — One-way hash function
    // PAD — Pad the number to have the same number of bytes as N
    var N = parameters.prime;
    var g = parameters.generator;
    var k = parameters.multiplier;
    var H = parameters.hash;
    var PAD = parameters.pad;

    // b — Secret ephemeral values
    // A — Public ephemeral values
    // s — User's salt
    // I — Username
    // v — Password verifier
    var b = SrpInteger.fromHex(serverSecretEphemeral);
    var A = SrpInteger.fromHex(clientPublicEphemeral);
    var s = SrpInteger.fromHex(salt);
    var I = username;
    var v = SrpInteger.fromHex(verifier);

    // B = kv + g^b (b = random number)
    var B = computeB(v, b);

    // A % N > 0
    if (A % N == SrpInteger.zero) {
      throw Exception("The client sent an invalid public ephemeral");
    }

    // u = H(PAD(A), PAD(B))
    var u = H([PAD(A), PAD(B)]);

    // S = (Av^u) ^ b (computes session key)
    var S = computeS(A, b, u, v);

    // K = H(S)
    var K = H([S]);

    // M = H(H(N) xor H(g), H(I), s, A, B, K)
    var M = H([H([N]) ^ H([g]), H([I]), s, A, B, K]);

    // validate client session proof
    var expected = M;
    var actual = SrpInteger.fromHex(clientSessionProof);
    if (actual != expected) {
      throw Exception("Client provided session proof is invalid");
    }

    // P = H(A, M, K)
    var P = H([A, M, K]);

    return SrpSession(
      key: K.toHex(),
      proof: P.toHex(),
    );
  }
}
