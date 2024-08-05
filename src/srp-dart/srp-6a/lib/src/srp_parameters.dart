

import 'package:crypto/crypto.dart';
import 'package:srp_6a/src/srp_hash.dart';
import 'package:srp_6a/srp_6a.dart';


/// Hash function signature.
/// Computes the hash of the specified [String] or [SrpInteger] values.
  typedef SrpHashFunction = SrpInteger Function(List<Object?> values);

class SrpParameters {

  /// Gets or sets the length of the padded N and g values.
  int paddedLength;

  /// Gets or sets the revision of the SRP protocol, which affects the exact algorithms used.
  SrpRevision revision;

  /// Gets or sets the large safe prime number (N = 2q+1, where q is prime).
  SrpInteger prime;

  /// Gets or sets the generator modulo N.
  SrpInteger generator;

  /// Gets or sets the SRP hasher.
  SrpHash hasher;

  

  /// Initializes a new instance of the [SrpParameters] class.
  SrpParameters({
    SrpHash Function()? hashAlgorithmFactory,
    String? largeSafePrime,
    String? generator,
    int? paddedLength,
    SrpRevision rev = SrpRevision.sixA,
  })  : prime = SrpInteger.fromHex(largeSafePrime ?? SrpConstants.safePrime2048),
        generator = SrpInteger.fromHex(generator ?? SrpConstants.generator2048),
        paddedLength = paddedLength ?? SrpInteger.fromHex(largeSafePrime ?? SrpConstants.safePrime2048).hexLength ?? 0,
        hasher = (hashAlgorithmFactory != null ? hashAlgorithmFactory() : SrpHash(SrpHash.createSha256)),
        pad = ((i) => i.pad(paddedLength ?? SrpInteger.fromHex(largeSafePrime ?? SrpConstants.safePrime2048).hexLength ?? 0)),
        revision = rev;

  /// Creates the SRP-6a parameters using the specified hash function.
  static SrpParameters create<T extends Hash>({
    String? largeSafePrime,
    String? generator,
    int? paddedLength,
    SrpRevision revision = SrpRevision.sixA,
  }) {
    var result = SrpParameters(
      hashAlgorithmFactory: () => SrpHashGeneric<T>(),
    );

    if (largeSafePrime != null) {
      result.prime = SrpInteger.fromHex(largeSafePrime);
      result.paddedLength = result.prime.hexLength ?? 0;
    }

    if (generator != null) {
      result.generator = SrpInteger.fromHex(generator);
    }

    if (paddedLength != null) {
      result.paddedLength = paddedLength;
    }

    result.revision = revision;

    return result;
  }

  /// Creates the SRP-6a parameters using the specified hash function and 1024-bit group.
  static SrpParameters create1024<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime1024, generator: SrpConstants.generator1024);

  /// Creates the SRP-6a parameters using the specified hash function and 1536-bit group.
  static SrpParameters create1536<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime1536, generator: SrpConstants.generator1536);

  /// Creates the SRP-6a parameters using the specified hash function and 2048-bit group.
  static SrpParameters create2048<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime2048, generator: SrpConstants.generator2048);

  /// Creates the SRP-6a parameters using the specified hash function and 3072-bit group.
  static SrpParameters create3072<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime3072, generator: SrpConstants.generator3072);

  /// Creates the SRP-6a parameters using the specified hash function and 4096-bit group.
  static SrpParameters create4096<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime4096, generator: SrpConstants.generator4096);

  /// Creates the SRP-6a parameters using the specified hash function and 6144-bit group.
  static SrpParameters create6144<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime6144, generator: SrpConstants.generator6144);

  /// Creates the SRP-6a parameters using the specified hash function and 8192-bit group.
  static SrpParameters create8192<T extends Hash>() =>
      create<T>(largeSafePrime: SrpConstants.safePrime8192, generator: SrpConstants.generator8192);
  
  /// Gets the hashing function.
  SrpHashFunction get hash => hasher.computeHash;

  /// Gets the function to pad the specified integer value.
  final SrpInteger Function(SrpInteger) pad;

  /// Gets the hash size in bytes.
  int get hashSizeBytes => hasher.hashSizeBytes;

  /// Gets the multiplier parameter: k = H(N, g) in SRP-6a (k = 3 for legacy SRP-6).
  SrpInteger get multiplier {
    switch (revision) {
      case SrpRevision.three:
        return SrpInteger("01");
      case SrpRevision.six:
        return SrpInteger("03");
      default:
        return hash([prime, pad(generator)]);
    }
  }

  @override
  String toString() =>
      'SrpParameters.create<${hasher.algorithmName}>("${prime.toHex()}", "${generator.toHex()}")';
}
