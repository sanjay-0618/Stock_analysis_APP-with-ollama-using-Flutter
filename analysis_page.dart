import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xl;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnalysisPage extends StatefulWidget {
  final File file;
  const AnalysisPage({super.key, required this.file});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  List<List<String>> parsedRows = [];
  String recommendationText = '';
  String errorMessage = '';
  bool isLoading = true;

  String selectedStatusFilter = 'All';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    analyzeExcelWithLLM();
  }

  Future<void> analyzeExcelWithLLM() async {
    try {
      final bytes = widget.file.readAsBytesSync();
      final excel = xl.Excel.decodeBytes(bytes);

      final tableData = <String>[
        "Product Name | Item Name | Item ID | Stock | Sold",
      ];

      for (final sheet in excel.tables.values) {
        for (var row in sheet.rows.skip(1)) {
          final cells = row.map((c) => c?.value?.toString() ?? '').toList();
          if (cells.length >= 5) {
            tableData.add(
              "${cells[0]} | ${cells[1]} | ${cells[2]} | ${cells[3]} | ${cells[4]}",
            );
          }
        }
      }

      final prompt =
          '''
You are an inventory AI assistant.

Analyze the following stock data:

${tableData.join('\n')}

1. Group similar items by Product Name and Item Name (ignore different Item IDs).
2. Show a table: Product | Item | Total Stock | Sold | Status
   - Status: Fast-moving, Slow-moving, or Restock Needed
3. After the table, write:
Recommendations:

- Suggest restocking items that are selling quickly and running low.
- Suggest holding off or promoting items that have high stock but are not selling well.
- Provide 2–3 sentences summarizing the key action points.
''';

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "llama3",
          "prompt": prompt,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['response'] ?? '';

        final splitIndex = responseText.toLowerCase().indexOf(
          'recommendations:',
        );
        final tablePart = splitIndex != -1
            ? responseText.substring(0, splitIndex).trim()
            : responseText.trim();
        final recPart = splitIndex != -1
            ? responseText.substring(splitIndex).trim()
            : '';

        setState(() {
          parsedRows = _parseResponseTable(tablePart);
          recommendationText = recPart;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'LLaMA Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  List<List<String>> _parseResponseTable(String text) {
    final lines = text.trim().split('\n');
    final rows = <List<String>>[];

    for (final line in lines) {
      final columns = line.split('|').map((e) => e.trim()).toList();
      if (columns.length >= 5) {
        rows.add(columns);
      }
    }

    return rows;
  }

  Color _getRowColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('fast')) return Colors.green.shade100;
    if (lower.contains('slow')) return Colors.red.shade100;
    if (lower.contains('restock')) return Colors.orange.shade100;
    return Colors.grey.shade100;
  }

  List<List<String>> get filteredRows {
    if (parsedRows.isEmpty) return [];

    final header = parsedRows.first;
    final filtered = parsedRows.skip(1).where((row) {
      if (row.length < 5) return false;

      final status = row[4].toLowerCase();
      final matchesStatus =
          selectedStatusFilter == 'All' ||
          status.contains(selectedStatusFilter.toLowerCase());

      final matchesSearch =
          searchQuery.isEmpty ||
          row.any(
            (cell) => cell.toLowerCase().contains(searchQuery.toLowerCase()),
          );

      return matchesStatus && matchesSearch;
    }).toList();

    return [header, ...filtered];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Analysis'),
        backgroundColor: const Color(0xFF003366),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002147), Color(0xFF005288)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Analysing your stocks...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExpansionTile(
                      title: Text(
                        '📦 Grouping Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Group Similar Items:\nCombine data for items with the same Product Name and Item Name, even if they have different Item IDs.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search by Product/Item',
                              prefixIcon: Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: selectedStatusFilter,
                          dropdownColor: Colors.white,
                          items:
                              [
                                    'All',
                                    'Fast-moving',
                                    'Slow-moving',
                                    'Restock Needed',
                                  ]
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) =>
                              setState(() => selectedStatusFilter = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    filteredRows.length <= 1
                        ? const Text(
                            'No matching results.',
                            style: TextStyle(color: Colors.white),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 16,
                                columns: filteredRows.first
                                    .map(
                                      (h) => DataColumn(
                                        label: Text(
                                          h,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                rows: filteredRows.skip(1).map((row) {
                                  return DataRow(
                                    color: MaterialStateProperty.all(
                                      _getRowColor(row[4]),
                                    ),
                                    cells: row
                                        .map((cell) => DataCell(Text(cell)))
                                        .toList(),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    if (recommendationText.isNotEmpty) ...[
                      const Text(
                        '📌 AI Recommendations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Text(
                          recommendationText,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
