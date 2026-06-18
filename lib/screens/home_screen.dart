import 'package:flutter/material.dart';
import '../services/discovery.dart';
import '../data/peers.dart';
import '../services/transfer.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    _discovery = Discovery(myUsername: widget.username);
    _discovery.start();

    _transfer = Transfer();
    _initServer();
  }

  Future<void> _initServer() async {
    final directory = await getApplicationDocumentsDirectory();
    _transfer.startServer(saveDir: directory.path);
  }

  @override
  void dispose() {
    _discovery.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("P2P File Sharing")),
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
                  final result = await FilePicker.pickFiles(type: FileType.any);
                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);
                    await _transfer.sendFile(
                      targetIp: peer.ip,
                      targetPort: 6000,
                      file: file,
                    );
                    print("File sent to ${peer.username}");
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
