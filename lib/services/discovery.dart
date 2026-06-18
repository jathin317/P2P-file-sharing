import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../data/peers.dart';

class Discovery {
  final String myUsername;
  final Map<String, Peer> _peers = {};

  final _peersController = StreamController<List<Peer>>.broadcast();
  Stream<List<Peer>> get peerStream => _peersController.stream;

  RawDatagramSocket? _listenSocket;
  RawDatagramSocket? _sendSocket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  Discovery({required this.myUsername});

  Future<void> start(int tcpPort) async {
    _listenSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      8080,
      reuseAddress: true,
      reusePort: true,
    );
    _listenSocket!.broadcastEnabled = true;

    _listenSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _listenSocket!.receive();
        if (datagram != null) {
          _handleMessage(datagram);
        }
      }
    });

    _sendSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8080);
    _sendSocket!.broadcastEnabled = true;

    final message = jsonEncode({
      "username": myUsername,
      "type": "announce",
      "port": tcpPort,
    });
    _broadcastTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _sendSocket!.send(
        utf8.encode(message),
        InternetAddress("255.255.255.255"),
        8080,
      );
    });

    _cleanupTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _removeOfflinePeers();
    });
  }

  void _handleMessage(Datagram datagram) {
    final message = jsonDecode(utf8.decode(datagram.data));
    final senderIp = datagram.address.address;
    final senderUsername = message["username"];
    final senderPort = message["port"] ?? 6000;

    if (senderUsername == myUsername) {
      return;
    }

    _peers[senderIp] = Peer(
      ip: senderIp,
      username: senderUsername,
      lastseen: DateTime.now(),
      port: senderPort
    );

    _peersController.add(_peers.values.toList());
  }

  void _removeOfflinePeers() {
    final now = DateTime.now();
    _peers.removeWhere(
      (ip, peer) => now.difference(peer.lastseen).inSeconds > 10,
    );
    _peersController.add(_peers.values.toList());
  }

  void stop() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _listenSocket?.close();
    _sendSocket?.close();
    _peersController.close();
  }
}
