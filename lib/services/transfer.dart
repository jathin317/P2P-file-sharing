import 'dart:io';
import 'dart:convert';
import 'dart:async';

class Transfer {
  ServerSocket? _server;

  final _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incomingStream => _incomingController.stream;

  Future<void> startServer({int port = 6000, String saveDir = "."}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print("TCP server listening on port $port");

    _server!.listen((Socket client) {
      _handleIncomingConnection(client, saveDir);
    });
  }

  void _handleIncomingConnection(Socket client, String savedir) {
    String? fileName;
    int? expectedSize;
    int receivedBytes = 0;
    bool metadataReceived = false;
    IOSink? fileSink;
    List<int> buffer = [];

    client.listen((List<int> data) {
      if (!metadataReceived) {
        buffer.addAll(data);
        int newlineIndex = buffer.indexOf(10);

        if (newlineIndex != -1) {
          String metaString = utf8.decode(buffer.sublist(0, newlineIndex));
          final meta = jsonDecode(metaString);
          fileName = meta["name"];
          expectedSize = meta["size"];
          metadataReceived = true;

          fileSink = File("$savedir/$fileName").openWrite();
          _incomingController.add({
            "status": "started",
            "fileName": fileName,
            "totalSize": expectedSize,
          });
          List<int> leftoverData = buffer.sublist(newlineIndex + 1);
          if (leftoverData.isNotEmpty) {
            fileSink!.add(leftoverData);
            receivedBytes += leftoverData.length;
          }
          buffer.clear();
        }
      } else {
        fileSink!.add(data);
        receivedBytes += data.length;

        _incomingController.add({
          "status": "progress",
          "fileName": fileName,
          "received": receivedBytes,
          "totalSize": expectedSize,
        });

        if (receivedBytes >= expectedSize!) {
          fileSink!.close();
          _incomingController.add({
            "status": "completed",
            "fileName": fileName,
          });
          client.close();
        }
      }
    });
  }

  Future<void> sendFile({
    required String targetIp,
    required int targetPort,
    required File file,
  }) async {
    final socket = await Socket.connect(targetIp, targetPort);
    final fileLength = await file.length();
    final metadata =
        "${jsonEncode({"name": file.path.split("/").last, "size": fileLength})}\n";

    socket.write(metadata);
    await socket.addStream(file.openRead());

    await socket.flush();
    await socket.close();
  }

  void stop() {
    _server?.close();
    _incomingController.close();
  }
}
