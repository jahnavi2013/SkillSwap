import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class EditPortfolioScreen extends StatefulWidget {
  const EditPortfolioScreen({super.key});

  @override
  State<EditPortfolioScreen> createState() => _EditPortfolioScreenState();
}

class _EditPortfolioScreenState extends State<EditPortfolioScreen> {
  final _formKey = GlobalKey<FormState>();

  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final userId = _userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = snapshot.data() ?? {};

      _githubController.text = data['githubUrl'] ?? '';
      _portfolioController.text = data['portfolioUrl'] ?? '';
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load your saved links.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final url = _normaliseUrl(value);
    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return 'Enter a valid website link.';
    }

    return null;
  }

  String _normaliseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return '';

    if (!trimmed.startsWith('https://') && !trimmed.startsWith('http://')) {
      return 'https://$trimmed';
    }

    return trimmed;
  }

  Future<void> _saveLinks() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to save your links.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'githubUrl': _normaliseUrl(_githubController.text),
        'portfolioUrl': _normaliseUrl(_portfolioController.text),
        'linksUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your links have been saved! 🎉')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save links: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _githubController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Portfolio & Links'),
        backgroundColor: AppTheme.background,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      size: 54,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Show what you can do! ✨',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your GitHub and portfolio links so '
                      'other learners can explore your work.',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _githubController,
                      keyboardType: TextInputType.url,
                      validator: _validateUrl,
                      decoration: InputDecoration(
                        labelText: 'GitHub profile',
                        hintText: 'github.com/yourusername',
                        prefixIcon: const Icon(Icons.code_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _portfolioController,
                      keyboardType: TextInputType.url,
                      validator: _validateUrl,
                      decoration: InputDecoration(
                        labelText: 'Portfolio website',
                        hintText: 'yourportfolio.com',
                        prefixIcon: const Icon(Icons.language_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveLinks,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? 'Saving...' : 'Save Links'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Leave a field empty if you do not have that link yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
