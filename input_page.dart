import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'analysis_page.dart';

class ExcelInputPage extends StatefulWidget {
  const ExcelInputPage({super.key});

  @override
  State<ExcelInputPage> createState() => _ExcelInputPageState();
}

class _ExcelInputPageState extends State<ExcelInputPage> {
  File? selectedFile;

  void pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  void analyzeFile() {
    if (selectedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AnalysisPage(file: selectedFile!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Twite Stock Analysis',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Stock Analyser',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Pick Excel File'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selectedFile != null ? analyzeFile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFile != null
                        ? Colors.greenAccent
                        : Colors.grey,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Analyze'),
                ),
                const SizedBox(height: 20),
                Text(
                  selectedFile != null
                      ? 'Selected: ${selectedFile!.path.split('/').last}'
                      : 'No file selected',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
