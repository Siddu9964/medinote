import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';

class PrescriptionViewer extends StatefulWidget {
  final List<Map<String, String>> records; // List of {'url': '...', 'date': '...'}
  final String patientName;

  const PrescriptionViewer({
    super.key,
    required this.records,
    required this.patientName,
  });

  @override
  State<PrescriptionViewer> createState() => _PrescriptionViewerState();
}

class _PrescriptionViewerState extends State<PrescriptionViewer> {
  int _currentIndex = 0;

  String _getFullUrl(String relativePath) {
    return ApiService.sanitizeImageUrl(relativePath);
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = widget.records.isNotEmpty 
        ? (widget.records[_currentIndex]['date'] ?? "N/A") 
        : "N/A";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Consultation Date: $currentDate",
              style: const TextStyle(color: Color(0xFFFACC15), fontSize: 13, fontWeight: FontWeight.bold), // Highlight date in gold
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "${_currentIndex + 1} / ${widget.records.length}",
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: PageView.builder(
        itemCount: widget.records.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                _getFullUrl(widget.records[index]['url']!),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 64),
                      SizedBox(height: 16),
                      Text("Failed to load clinical record", style: TextStyle(color: Colors.white54)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.records.length > 1
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.records.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
