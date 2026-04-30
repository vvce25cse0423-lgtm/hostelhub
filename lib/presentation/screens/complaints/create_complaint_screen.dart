// lib/presentation/screens/complaints/create_complaint_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/app_snackbar.dart';

class CreateComplaintScreen extends ConsumerStatefulWidget {
  const CreateComplaintScreen({super.key});
  @override
  ConsumerState<CreateComplaintScreen> createState() =>
      _CreateComplaintScreenState();
}

class _CreateComplaintScreenState
    extends ConsumerState<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'maintenance';
  File? _selectedImage;
  bool _isLoading = false;

  final _categories = [
    ('maintenance', 'Maintenance', Iconsax.setting_2),
    ('food', 'Food & Mess', Iconsax.cake),
    ('cleanliness', 'Cleanliness', Iconsax.broom),
    ('security', 'Security', Iconsax.shield_tick),
    ('electricity', 'Electricity', Iconsax.flash),
    ('water', 'Water Supply', Iconsax.drop),
    ('internet', 'Internet/WiFi', Iconsax.wifi),
    ('other', 'Other', Iconsax.more_circle),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final img = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) setState(() => _selectedImage = File(img.path));
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = ref.read(authNotifierProvider).value;
    if (user == null) {
      setState(() => _isLoading = false);
      AppSnackbar.showError(context, 'Not logged in');
      return;
    }

    try {
      final repo = ref.read(complaintRepositoryProvider);
      final result = await repo.createComplaint(
        studentId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        image: _selectedImage,
      );

      if (!mounted) return;

      result.fold(
        (failure) => AppSnackbar.showError(context, failure.message),
        (_) {
          AppSnackbar.showSuccess(context, 'Complaint submitted successfully!');
          context.go(AppRoutes.complaints);
        },
      );
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Raise Complaint')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Category
              Text('Category', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat.$1;
                  return FilterChip(
                    label: Text(cat.$2, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.$1),
                    selectedColor:
                        theme.colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Title
              AppTextField(
                controller: _titleController,
                label: 'Complaint Title',
                hint: 'e.g. Water leakage in room 101',
                prefixIcon: Icons.title_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              // Description
              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe the issue in detail...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Please provide more details (min 10 chars)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image
              Text('Attach Photo (Optional)',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: _selectedImage != null ? 180 : 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color:
                            theme.colorScheme.outline.withOpacity(0.4),
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                  ),
                  child: _selectedImage != null
                      ? Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () =>
                                  setState(() => _selectedImage = null),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white),
                            ),
                          ),
                        ])
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.camera,
                                  color: theme.colorScheme.outline),
                              const SizedBox(height: 4),
                              Text('Tap to add photo',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              LoadingButton(
                onPressed: _isLoading ? () {} : _submit,
                isLoading: _isLoading,
                label: 'Submit Complaint',
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
