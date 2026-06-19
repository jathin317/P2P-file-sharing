import 'package:flutter/material.dart';
import '../services/transfer.dart';

class ActiveTransfersScreen extends StatelessWidget {
  final Transfer transfer;

  const ActiveTransfersScreen({super.key, required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Transfers")),
      body: StreamBuilder<List<TransferTask>>(
        stream: transfer.tasksStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No active transfers"));
          }
          
          // Reverse the list so the newest transfers show up at the top
          final tasks = snapshot.data!.reversed.toList(); 

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: task.isIncoming ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  child: Icon(
                    task.isIncoming ? Icons.download : Icons.upload,
                    color: task.isIncoming ? Colors.blue : Colors.orange,
                  ),
                ),
                title: Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("${task.isIncoming ? 'From' : 'To'}: ${task.peerName}"),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.grey[800],
                      color: task.status == "failed" ? Colors.red : (task.isIncoming ? Colors.blue : Colors.orange),
                    ),
                  ],
                ),
                trailing: _buildTrailingIcon(task),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrailingIcon(TransferTask task) {
    if (task.status == "completed") {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (task.status == "cancelled") {
      return const Icon(Icons.cancel, color: Colors.grey);
    } else if (task.status == "failed") {
      return const Icon(Icons.error, color: Colors.red);
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${(task.progress * 100).toInt()}%",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            tooltip: "Cancel Transfer",
            onPressed: () {
              transfer.cancelTask(task.id);
            },
          )
        ],
      );
    }
  }
}