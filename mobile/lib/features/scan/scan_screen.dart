import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/discharge_request.dart';
import '../../core/services/discharge_api.dart';
import '../../core/l10n.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final TextEditingController _textController = TextEditingController();

  File? _selectedImage;
  bool _isProcessing = false; // true while OCR is running
  bool _isSubmitting = false; // true while we're waiting on the backend
  String _selectedLanguage = 'en';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
      _isProcessing = true;
      _textController.clear();
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _textController.text = recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${L10n.get('couldNotRead', _selectedLanguage)}$e'),
        ),
      );
    }
  }

  Future<void> _continueToTeachBack() async {
    final dischargeText = _textController.text.trim();

    if (dischargeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.get('pleaseScan', _selectedLanguage),
          ),
        ),
      );
      return;
    }

    final request = DischargeRequest(
      patientId: 'P001',
      preferredLanguage: _selectedLanguage,
      dischargeText: dischargeText,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await DischargeApi.processDischarge(request);

      if (!mounted) return;

      context.push('/summary', extra: session);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${L10n.get('somethingWentWrong', _selectedLanguage)}$e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isProcessing || _isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.get('scanDischarge', _selectedLanguage)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              icon: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                DropdownMenuItem(value: 'ta', child: Text('Tamil')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.get('scanInstructions', _selectedLanguage),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              L10n.get('takePhoto', _selectedLanguage),
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: isBusy ? null : () => _pickImage(ImageSource.camera),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      elevation: isBusy ? 0 : 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                            const SizedBox(height: 12),
                            Text(L10n.get('camera', _selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: isBusy ? null : () => _pickImage(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      elevation: isBusy ? 0 : 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library, size: 40, color: Theme.of(context).colorScheme.onSecondaryContainer),
                            const SizedBox(height: 12),
                            Text(L10n.get('gallery', _selectedLanguage), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

            if (_selectedImage != null) const SizedBox(height: 24),

            Text(
              L10n.get('reviewText', _selectedLanguage),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              L10n.get('editIfMistake', _selectedLanguage),
            ),

            const SizedBox(height: 12),

            if (_isProcessing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Extracting text...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 10,
                  enabled: !_isSubmitting,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                  decoration: InputDecoration(
                    hintText: L10n.get('extractedHint', _selectedLanguage),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: isBusy ? null : _continueToTeachBack,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(L10n.get('continueTeachBack', _selectedLanguage)),
            ),
          ],
        ),
      ),
    );
  }
}