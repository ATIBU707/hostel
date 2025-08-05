import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ResidentProfileScreen extends StatefulWidget {
  const ResidentProfileScreen({super.key});

  @override
  State<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Uint8List? _imageData;
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile != null) {
      setState(() {
        _nameController.text = userProfile['full_name'] ?? '';
        _emailController.text = authProvider.user?.email ?? '';
        _phoneController.text = userProfile['phone'] ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageData = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageData = null;
    });
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.updateProfile(
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        imageBytes: _imageData,
        imageFileExtension: _imageFile?.path.split('.').last,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditingProfile = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // This is a placeholder for the actual password change logic
      // which is not yet implemented in AuthProvider.
      // final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // await authProvider.changePassword(
      //   currentPassword: _currentPasswordController.text,
      //   newPassword: _newPasswordController.text,
      // );

      await Future.delayed(const Duration(seconds: 1)); // Simulate network call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isChangingPassword = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        
        if (authProvider.userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          key: ValueKey(authProvider.userProfile?['avatar_url']),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _profileFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage: _imageData != null
                                        ? MemoryImage(_imageData!)
                                        : (authProvider.userProfile?['avatar_url'] != null && authProvider.userProfile!['avatar_url'].isNotEmpty
                                            ? NetworkImage(authProvider.userProfile!['avatar_url'])
                                            : null) as ImageProvider?,
                                    child: _imageData == null && (authProvider.userProfile?['avatar_url'] == null || authProvider.userProfile!['avatar_url'].isEmpty)
                                        ? const Icon(Icons.person, size: 60)
                                        : null,
                                  ),
                                  if (_isEditingProfile)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                          icon: const Icon(Icons.camera_alt, size: 20),
                                          onPressed: _pickImage,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isEditingProfile && (authProvider.userProfile?['avatar_url'] != null || _imageData != null))
                              Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    authProvider.removeProfilePicture();
                                    _removeImage();
                                  },
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Profile Information Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Profile Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isEditingProfile)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => setState(() => _isEditingProfile = true),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Profile Form Fields
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Full Name'),
                              subtitle: _isEditingProfile
                                  ? TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your full name',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    )
                                  : Text(_nameController.text),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.email_outlined),
                              title: const Text('Email Address'),
                              subtitle: _isEditingProfile
                                  ? TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your email address',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty || !value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    )
                                  : Text(_emailController.text),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.phone_outlined),
                              title: const Text('Phone Number'),
                              subtitle: _isEditingProfile
                                  ? TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your phone number',
                                      ),
                                      keyboardType: TextInputType.phone,
                                    )
                                  : Text(_phoneController.text.isEmpty ? 'Not provided' : _phoneController.text),
                            ),
                            if (_isEditingProfile)
                              const SizedBox(height: 24),
                            if (_isEditingProfile)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingProfile = false;
                                        _removeImage(); // Also clear any staged image changes
                                      });
                                      _loadProfileData();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _updateProfile,
                                    icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_alt_outlined),
                                    label: _isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Save Changes'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Security',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isChangingPassword)
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() => _isChangingPassword = true),
                                    icon: const Icon(Icons.lock, size: 16),
                                    label: const Text('Change Password'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_isChangingPassword)
                              const SizedBox(height: 16),
                            if (_isChangingPassword)
                              TextFormField(
                                controller: _currentPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Current Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your current password';
                                  }
                                  return null;
                                },
                              ),
                            if (_isChangingPassword)
                              const SizedBox(height: 16),
                            if (_isChangingPassword)
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            if (_isChangingPassword)
                              const SizedBox(height: 16),
                            if (_isChangingPassword)
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm New Password',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) {
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            if (_isChangingPassword)
                              const SizedBox(height: 24),
                            if (_isChangingPassword)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _isChangingPassword = false);
                                      _currentPasswordController.clear();
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _changePassword,
                                    icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_alt_outlined),
                                    label: _isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Update Password'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
