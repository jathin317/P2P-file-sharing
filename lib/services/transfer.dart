import 'dart:io';
import 'dart:convert';
import 'dart:async';

class TransferTask {
  final String id;
  final String fileName;
  final bool isIncoming;
  final String peerName;
  int totalBytes;
  int transferredBytes;
  String status; // "progress", "completed", "failed", "cancelled"
  final void Function()? onCancel; // The power to kill the socket

  TransferTask({
    required this.id,
    required this.fileName,
    required this.isIncoming,
    required this.peerName,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.status = "progress",
    this.onCancel,
  });

  double get progress => totalBytes == 0 ? 0 : (transferredBytes / totalBytes);

  void cancel() {
    if (onCancel != null) onCancel!();
  }
}

class Transfer {
  ServerSocket? _server;
  final List<TransferTask> _tasks = [];
  final _tasksController = StreamController<List<TransferTask>>.broadcast();
  Stream<List<TransferTask>> get tasksStream => _tasksController.stream;

  Future<int> startServer({int port = 0, String saveDir = "."}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    final assignedPort = _server!.port;
    print("TCP server listening on port $assignedPort");

    _server!.listen((Socket client) {
      _handleIncomingConnection(client, saveDir);
    });

    return assignedPort;
  }

  void _handleIncomingConnection(Socket client, String savedir) {
    TransferTask? currentTask;
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
          
          final filePath = "$savedir/${meta["name"]}";

          currentTask = TransferTask(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fileName: meta["name"],
            isIncoming: true,
            peerName: meta["sender"] ?? "Unknown User",
            totalBytes: meta["size"],
            onCancel: () {
              client.destroy(); // Kill the incoming socket
              fileSink?.close();
              // Delete the partial corrupted file
              final file = File(filePath);
              if (file.existsSync()) file.deleteSync(); 
            }
          );
          
          _tasks.add(currentTask!);
          _tasksController.add(List.from(_tasks));

          fileSink = File(filePath).openWrite();
          
          List<int> leftoverData = buffer.sublist(newlineIndex + 1);
          if (leftoverData.isNotEmpty) {
            fileSink!.add(leftoverData);
            currentTask!.transferredBytes += leftoverData.length;
          }
          buffer.clear();
          metadataReceived = true;
        }
      } else if (currentTask != null) {
        fileSink!.add(data);
        currentTask!.transferredBytes += data.length;
        
        _tasksController.add(List.from(_tasks));

        if (currentTask!.transferredBytes >= currentTask!.totalBytes) {
          fileSink!.close();
          currentTask!.status = "completed";
          _tasksController.add(List.from(_tasks));
          client.close();
        }
      }
    }, 
    onError: (e) {
      _handleTaskFailure(currentTask, fileSink);
    }, 
    onDone: () {
      // If the sender cancelled the transfer, the socket closes early
      if (currentTask != null && currentTask!.transferredBytes < currentTask!.totalBytes) {
        _handleTaskFailure(currentTask, fileSink);
      }
    });
  }

  void _handleTaskFailure(TransferTask? task, IOSink? sink) {
    sink?.close();
    if (task != null && task.status == "progress") {
      task.status = "failed"; // Or cancelled if done remotely
      _tasksController.add(List.from(_tasks));
    }
  }

  Future<void> sendFile({
    required String targetIp,
    required int targetPort,
    required File file,
    required String myUsername,
    required String targetUsername,
  }) async {
    final socket = await Socket.connect(targetIp, targetPort);
    final fileLength = await file.length();
    final fileName = file.path.split("/").last;
    bool isCancelled = false;

    final currentTask = TransferTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      isIncoming: false,
      peerName: targetUsername,
      totalBytes: fileLength,
      onCancel: () {
        isCancelled = true;
        socket.destroy(); // Kill the outgoing socket
      }
    );
    
    _tasks.add(currentTask);
    _tasksController.add(List.from(_tasks));

    final metadata = "${jsonEncode({
      "name": fileName, 
      "size": fileLength,
      "sender": myUsername
    })}\n";
    socket.write(metadata);

    final stream = file.openRead().map((chunk) {
      if (isCancelled) throw Exception("Cancelled by user");
      currentTask.transferredBytes += chunk.length;
      _tasksController.add(List.from(_tasks)); 
      return chunk;
    });

    try {
      await socket.addStream(stream);
      await socket.flush();
      if (!isCancelled) currentTask.status = "completed";
    } catch (e) {
      currentTask.status = isCancelled ? "cancelled" : "failed";
    } finally {
      _tasksController.add(List.from(_tasks));
      socket.destroy();
    }
  }

  // Called from the UI
  void cancelTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    if (task.status == "progress") {
      task.cancel();
      task.status = "cancelled";
      _tasksController.add(List.from(_tasks));
    }
  }

  void stop() {
    _server?.close();
    _tasksController.close();
  }
}