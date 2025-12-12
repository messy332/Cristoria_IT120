import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('coffee_predictions');
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Query by user_id to only show current user's history
      // Note: This requires indexing on 'user_id' in Firebase rules for best performance
      // For now, we'll fetch all and filter client-side if needed, or assume the ref is global
      // The current implementation in main.dart saves user_id but doesn't seem to use it for structure
      
      final snapshot = await _ref.orderByChild('timestamp').get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedData = [];
        
        data.forEach((key, value) {
          if (value is Map) {
            // Filter by user_id if available in the record
            if (value['user_id'] == _currentUser!.uid) {
              loadedData.add({
                'id': key,
                'predicted_class': value['predicted_class'] ?? 'Unknown',
                'accuracy_rate': value['accuracy_rate'] ?? 0.0,
                'timestamp': value['timestamp'] ?? '',
                'confidence': value['confidence'] ?? 0.0,
              });
            }
          }
        });

        // Sort by timestamp descending (newest first)
        loadedData.sort((a, b) {
          final timeA = DateTime.tryParse(a['timestamp']) ?? DateTime(1970);
          final timeB = DateTime.tryParse(b['timestamp']) ?? DateTime(1970);
          return timeB.compareTo(timeA);
        });

        setState(() {
          _historyData = loadedData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _historyData = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      // Simple formatting without intl package
      // YYYY-MM-DD HH:MM
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Prediction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.brown.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history found',
                        style: TextStyle(
                          color: Colors.brown.shade600,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyData.length,
                  itemBuilder: (context, index) {
                    final item = _historyData[index];
                    final accuracy = (item['accuracy_rate'] as num).toDouble();
                    final isHighConfidence = accuracy > 70;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isHighConfidence 
                                    ? Colors.green.shade50 
                                    : Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.coffee,
                                color: isHighConfidence 
                                    ? Colors.green.shade700 
                                    : Colors.orange.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['predicted_class'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF6F4E37),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(item['timestamp']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${accuracy.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isHighConfidence 
                                        ? Colors.green.shade700 
                                        : Colors.orange.shade700,
                                  ),
                                ),
                                const Text(
                                  'Accuracy',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
