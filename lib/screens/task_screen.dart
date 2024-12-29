import 'package:flutter/material.dart';
import 'package:hrm/api/task_service.dart';
import 'package:hrm/model/task.dart';
import 'package:hrm/screens/add_task_screen.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TaskService _taskService = TaskService();
  late Future<List<Task>> futureTasks;

  @override
  void initState() {
    super.initState();
    futureTasks = _fetchTasks();
  }

  Future<List<Task>> _fetchTasks() async {
    try {
      return await _taskService.getTasks();
    } catch (e) {
      throw Exception('Gagal memuat data tugas: $e');
    }
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      setState(() {
        futureTasks = _fetchTasks();
      });
    } catch (e) {
      print('Gagal menghapus tugas: $e');
    }
  }

  Color _getStatusApprovalColor(String statusApproval) {
    switch (statusApproval.toLowerCase()) {
      case 'disetujui':
        return Colors.green.shade400;  // Soft green
      case 'ditolak':
        return Colors.red.shade400;    // Soft red
      case 'pending':
      default:
        return Colors.yellow.shade600;  // Soft yellow
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green.shade400;  // Soft green
      case 'dalam proses':
        return Colors.yellow.shade600;  // Soft yellow
      case 'belum dimulai':
      default:
        return Colors.red.shade400;    // Soft red
    }
  }

  Widget _buildMedal(int point) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.shade300,  // Soft orange
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, color: Colors.white, size: 16),
          Text(
            point.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Tugas'),
        backgroundColor: Colors.blue.shade700, // Soft blue
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureTasks = _fetchTasks();
          });
        },
        child: FutureBuilder<List<Task>>(
          future: futureTasks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Tidak ada tugas tersedia.'));
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = snapshot.data![index];
                  final statusApprovalColor = _getStatusApprovalColor(task.statusApproval);
                  final statusColor = _getStatusColor(task.status);

                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMedal(task.point),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.judulProyek,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800, // Soft blue
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${task.tglMulai} - ${task.batasPenyelesaian}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue.shade600),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TaskForm(task: task)),
                                    ).then((_) {
                                      setState(() {
                                        futureTasks = _fetchTasks();
                                      });
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red.shade600),
                                  onPressed: () {
                                    _deleteTask(task.idTugas);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Kegiatan: ${task.kegiatan}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${task.status}',
                              style: TextStyle(fontSize: 14, color: statusColor),
                            ),
                            SizedBox(height: 5),
                            Container(
                              color: statusApprovalColor,
                              padding: EdgeInsets.all(8),
                              child: Text(
                                task.statusApproval,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskForm()),
          ).then((_) {
            setState(() {
              futureTasks = _fetchTasks();
            });
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Tambah Tugas',
      ),
    );
  }
}
