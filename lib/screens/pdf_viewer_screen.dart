import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/course.dart';
import '../utils/constants.dart';

/// PDF Viewer Screen - Displays course PDF materials
class PDFViewerScreen extends StatefulWidget {
  final Course course;

  const PDFViewerScreen({super.key, required this.course});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _pdfPath;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;

  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  /// Load PDF file
  Future<void> _loadPDF() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      String pdfPath;

      if (widget.course.isBundled) {
        // Load from assets
        pdfPath = await _loadAssetPDF();
      } else if (widget.course.isDownloaded &&
          widget.course.localPath != null) {
        // Load from local storage
        pdfPath = widget.course.localPath!;
      } else {
        throw Exception('Course file not available');
      }

      setState(() {
        _pdfPath = pdfPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }

  /// Load PDF from assets to temporary directory
  Future<String> _loadAssetPDF() async {
    try {
      // Get asset path
      final assetPath = widget.course.localPath!;

      // Load asset as bytes
      final byteData = await rootBundle.load(assetPath);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(assetPath);
      final file = File('${tempDir.path}/$fileName');

      // Write to temporary file
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );

      return file.path;
    } catch (e) {
      throw Exception('Failed to load bundled PDF: $e');
    }
  }

  /// Go to specific page
  void _goToPage(int page) {
    _pdfViewController?.setPage(page);
  }

  /// Go to previous page
  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  /// Go to next page
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  /// Show page selector dialog
  void _showPageSelector() {
    final controller = TextEditingController(text: '${_currentPage + 1}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _goToPage(page - 1);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid page number. Enter 1-$_totalPages'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.courseCode,
              style: const TextStyle(fontSize: 16),
            ),
            if (_isReady)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          if (_isReady)
            IconButton(
              icon: const Icon(LucideIcons.hash),
              onPressed: _showPageSelector,
              tooltip: 'Go to page',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isReady ? _buildNavigationBar() : null,
    );
  }

  /// Build main body
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.fileX,
                size: 64,
                color: AppConstants.errorColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPDF,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfPath == null) {
      return const Center(child: Text('No PDF file available'));
    }

    return PDFView(
      filePath: _pdfPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.WIDTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
          _isReady = true;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        print('Error on page $page: $error');
      },
      onViewCreated: (PDFViewController pdfViewController) {
        _pdfViewController = pdfViewController;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
    );
  }

  /// Build bottom navigation bar
  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: _currentPage > 0 ? _previousPage : null,
              tooltip: 'Previous page',
              color: AppConstants.primaryColor,
              disabledColor: AppConstants.textTertiary,
            ),

            // Page Info
            Expanded(
              child: GestureDetector(
                onTap: _showPageSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Next Button
            IconButton(
              icon: const Icon(LucideIcons.chevronRight),
              onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
              tooltip: 'Next page',
              color: AppConstants.primaryColor,
              disabledColor: AppConstants.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewController = null;
    super.dispose();
  }
}
