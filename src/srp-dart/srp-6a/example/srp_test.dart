import 'package:srp_6a/srp_6a.dart';
import 'package:tuple/tuple.dart';

class SrpLoginServer {
  late String _userName;
  late String _salt;
  late String _verifier;

  String get salt => _salt;
  String get verifier => _verifier;
  String get userName => _userName;

  SrpServer _server = SrpServer();
  late SrpEphemeral _serverEphemeral;

  void register(String userName, String password) {
    // 1. Register Generates salt, and verifier from client class
    _userName = userName;
    var client = SrpClient();
    // save salt and verifier in database    
    _salt = client.generateSalt();    
    var privateKey = client.derivePrivateKey(_salt, userName, password);    
    _verifier = client.deriveVerifier(privateKey);    
  }

  Tuple2<String, String> initiateLogin(String userName) {
    // Get Verifier and Salt based on userName
    var verifier = _verifier; // From Database
    var salt = _salt; // From Database
    _serverEphemeral = _server.generateEphemeral(verifier);

    return Tuple2(salt, _serverEphemeral.public);
  }

  String respondToAuthResponse(String clientEphemeral, String clientProof) {
    try {
      var session = _server.deriveSession(
          _serverEphemeral.secret, clientEphemeral, _salt, _userName, _verifier, clientProof);
      print("Server Proof: ${session.key}");
      return session.proof;
    } catch (e) {
      return "";
    }
  }
}

class SrpLoginClient {
  late SrpSession _session;
  late SrpEphemeral _clientEphemeral;

  SrpClient _client = SrpClient();

  Tuple2<String, String> registerUser(String userName, String password) {
    return Tuple2(userName, password);
  }

  String initiateLogin(String userName) {
    return userName;
  }

  Tuple2<String, String> respondToAuth(
      String salt, String serverEphemeral, String userName, String password) {
    try {
      _clientEphemeral = _client.generateEphemeral();
      var privateKey = _client.derivePrivateKey(salt, userName, password);
      _session = _client.deriveSession(
          _clientEphemeral.secret, serverEphemeral, salt, userName, privateKey);
      print("Client Proof: ${_session.key}");
      return Tuple2(_clientEphemeral.public, _session.proof);
    } catch (e) {
      return Tuple2("", "");
    }
  }

  bool verifyServerProof(String serverProof) {
    try {
      _client.verifySession(_clientEphemeral.public, _session, serverProof);
      return true;
    } catch (e) {
      return false;
    }
  }
}
