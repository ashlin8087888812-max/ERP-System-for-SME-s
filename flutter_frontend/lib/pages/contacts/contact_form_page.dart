import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/contact_model.dart';
import '../../repositories/contacts_repository.dart';
import '../../injection_container.dart' as di;
import '../../providers/contacts_provider.dart';

class ContactFormPage extends ConsumerStatefulWidget {
  final int? contactId;

  const ContactFormPage({super.key, this.contactId});

  @override
  ConsumerState<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends ConsumerState<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _companyController;
  late TextEditingController _websiteController;
  late TextEditingController _functionController;
  late TextEditingController _vatController;
  late TextEditingController _streetController;
  late TextEditingController _street2Controller;
  late TextEditingController _cityController;
  late TextEditingController _zipController;
  late TextEditingController _commentController;
  
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isCompany = false;
  String? _imageBase64;
  ContactModel? _contact;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.contactId != null && widget.contactId != 0) {
      _loadContact();
    } else {
      _isInitializing = false;
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _mobileController = TextEditingController();
    _companyController = TextEditingController();
    _websiteController = TextEditingController();
    _functionController = TextEditingController();
    _vatController = TextEditingController();
    _streetController = TextEditingController();
    _street2Controller = TextEditingController();
    _cityController = TextEditingController();
    _zipController = TextEditingController();
    _commentController = TextEditingController();
  }

  Future<void> _loadContact() async {
    try {
      final repo = di.sl<ContactsRepository>();
      final contact = await repo.getContact(widget.contactId!);
      if (mounted) {
        setState(() {
          _contact = contact;
          _isCompany = contact.isCompany;
          _nameController.text = contact.name ?? '';
          _emailController.text = contact.email ?? '';
          _phoneController.text = contact.phone ?? '';
          _mobileController.text = contact.mobile ?? '';
          _companyController.text = contact.companyName ?? '';
          _websiteController.text = contact.website ?? '';
          _functionController.text = contact.function ?? '';
          _vatController.text = contact.vat ?? '';
          _streetController.text = contact.street ?? '';
          _street2Controller.text = contact.street2 ?? '';
          _cityController.text = contact.city ?? '';
          _zipController.text = contact.zip ?? '';
          _commentController.text = contact.comment ?? '';
          _imageBase64 = contact.image128; // Using 128 for now
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contact: $e')),
        );
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _functionController.dispose();
    _vatController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = di.sl<ContactsRepository>();
      
      final contactData = ContactModel(
        id: widget.contactId ?? 0,
        name: _nameController.text,
        isCompany: _isCompany,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        mobile: _mobileController.text.isEmpty ? null : _mobileController.text,
        companyName: _companyController.text.isEmpty ? null : _companyController.text,
        website: _websiteController.text.isEmpty ? null : _websiteController.text,
        function: _functionController.text.isEmpty ? null : _functionController.text,
        vat: _vatController.text.isEmpty ? null : _vatController.text,
        street: _streetController.text.isEmpty ? null : _streetController.text,
        street2: _street2Controller.text.isEmpty ? null : _street2Controller.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        zip: _zipController.text.isEmpty ? null : _zipController.text,
        comment: _commentController.text.isEmpty ? null : _commentController.text,
        image1920: _imageBase64, // Send as image_1920 for high res
      );

      if (widget.contactId == null || widget.contactId == 0) {
        await repo.createContact(contactData);
      } else {
        await repo.updateContact(widget.contactId!, contactData);
      }

      if (mounted) {
        // Invalidate list provider to refresh
        ref.invalidate(contactsListProvider);
        if (widget.contactId != null) {
             ref.invalidate(contactDetailProvider(widget.contactId!));
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactId == null || widget.contactId == 0 ? 'New Contact' : 'Edit Contact'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageBase64 != null 
                      ? MemoryImage(base64Decode(_imageBase64!)) 
                      : null,
                  child: _imageBase64 == null
                      ? Icon(_isCompany ? Icons.business : Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Tap to change photo', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 24),

            _buildSectionTitle('Basic Info'),
            
            // Is Company Switch
            SwitchListTile(
              title: const Text('Is a Company?'),
              value: _isCompany,
              onChanged: (val) {
                setState(() {
                  _isCompany = val;
                });
              },
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Only show Company Name if it's a person
            if (!_isCompany) ...[
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _functionController,
                decoration: const InputDecoration(labelText: 'Job Position', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
            ],
            
            _buildSectionTitle('Communication'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(labelText: 'Mobile', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder()),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Address'),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _street2Controller,
              decoration: const InputDecoration(labelText: 'Street 2', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(labelText: 'Zip', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Other'),
            TextFormField(
              controller: _vatController,
              decoration: const InputDecoration(labelText: 'Tax ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Internal Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.contactId == null || widget.contactId == 0 ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}
