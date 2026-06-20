import 'package:flutter/material.dart';
import '../services/discovery.dart';
import '../data/peers.dart';
import '../services/transfer.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'active_transfers_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Discovery _discovery;
  late Transfer _transfer;

  @override
  void initState() {
    super.initState();
    _transfer = Transfer();
    _discovery = Discovery(myUsername: widget.username);
    _initServices();
  }

  Future<void> _initServices() async {
    Directory? baseDirectory;

    if (Platform.isAndroid) {
      baseDirectory = Directory('/storage/emulated/0/Download');
      if (!await baseDirectory.exists()) {
        baseDirectory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      baseDirectory = await getApplicationDocumentsDirectory();
    } else {
      baseDirectory = await getDownloadsDirectory();
    }
    baseDirectory ??= await getApplicationDocumentsDirectory();

    final p2pDir = Directory("${baseDirectory.path}/p2p");
    if (!await p2pDir.exists()) {
      await p2pDir.create(recursive: true);
    }

    final assignedPort = await _transfer.startServer(
      port: 0,
      saveDir: p2pDir.path,
    );
    _discovery.start(assignedPort);
  }

  @override
  void dispose() {
    _discovery.stop();
    _transfer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P2P File Sharing"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: "Active Transfers",
            onPressed: () {
              // Navigate to the new screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActiveTransfersScreen(transfer: _transfer),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Peer>>(
        stream: _discovery.peerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Searching for devices..."));
          }
          final peers = snapshot.data;

          return ListView.builder(
            itemCount: peers!.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return ListTile(
                leading: const Icon(Icons.devices),
                title: Text(peer.username),
                subtitle: Text(peer.ip),
                onTap: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.any,
                    allowMultiple: true,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    for (var platformFile in result.files) {
                      if (platformFile.path != null) {
                        final file = File(platformFile.path!);
                        _transfer.sendFile(
                          targetIp: peer.ip,
                          targetPort: peer.port,
                          file: file,
                          myUsername: widget.username,
                          targetUsername: peer.username,
                        );
                      }
                    }

                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActiveTransfersScreen(transfer: _transfer),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
