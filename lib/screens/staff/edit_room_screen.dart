import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';

class EditRoomScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const EditRoomScreen({super.key, required this.room});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostelNameController;
  late final TextEditingController _roomNumberController;
  late final TextEditingController _capacityController;
  late final TextEditingController _rentController;

  late String _selectedRoomType;
  bool _isLoading = false;
  XFile? _imageFile;
  Uint8List? _imageData;
  String? _imageUrl;

  final List<String> _roomTypes = ['single', 'double', 'triple', 'quad', 'dormitory'];

  @override
  void initState() {
    super.initState();
    _hostelNameController = TextEditingController(text: widget.room['hostel_name'] ?? '');
    _roomNumberController = TextEditingController(text: widget.room['room_number'] ?? '');
    _capacityController = TextEditingController(text: widget.room['capacity']?.toString() ?? '');
    _rentController = TextEditingController(text: widget.room['rent_amount']?.toString() ?? '');
    _selectedRoomType = widget.room['room_type'] ?? 'single';
    _imageUrl = widget.room['image_url'];
  }

  @override
  void dispose() {
    _hostelNameController.dispose();
    _roomNumberController.dispose();
    _capacityController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final imageData = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageData = imageData;
      });
    }
  }

  Future<void> _updateRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateRoom(
        roomId: widget.room['id'],
        hostelName: _hostelNameController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
        roomType: _selectedRoomType,
        capacity: int.parse(_capacityController.text),
        rentAmount: double.parse(_rentController.text),
        imageBytes: _imageData,
        imageFileExtension: _imageFile?.mimeType?.split('/').last ?? _imageFile?.path.split('.').last,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room updated successfully!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating room: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Edit Room', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colors.shadow.withOpacity(0.2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: colors.outline.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(colors),
              const SizedBox(height: 24),
              _buildTextField(_hostelNameController, 'Hostel Name', 'e.g., Grand Hostel', Icons.home_work_outlined),
              const SizedBox(height: 16),
              _buildTextField(_roomNumberController, 'Room Name/Number', 'e.g., 101, Block A', Icons.meeting_room_outlined),
              const SizedBox(height: 16),
              _buildRoomTypeDropdown(colors),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_capacityController, 'Bed Capacity', 'e.g., 2', Icons.groups_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_rentController, 'Price (UGX)', 'e.g., 500000', Icons.price_change_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 32),
              _buildUpdateButton(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(ColorScheme colors) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outline.withOpacity(0.3), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: _imageData != null
                ? Image.memory(_imageData!, fit: BoxFit.cover)
                : (_imageUrl != null && _imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image_outlined, size: 50, color: colors.onSurfaceVariant.withOpacity(0.5)),
                      )
                    : Icon(Icons.apartment_rounded, size: 60, color: colors.onSurfaceVariant.withOpacity(0.5))),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Material(
              color: colors.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter the $label.';
        if (keyboardType == TextInputType.number && int.tryParse(value) == null) return 'Please enter a valid number.';
        return null;
      },
    );
  }

  Widget _buildRoomTypeDropdown(ColorScheme colors) {
    return DropdownButtonFormField<String>(
      value: _selectedRoomType,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: 'Room Type',
        prefixIcon: const Icon(Icons.king_bed_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _roomTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type[0].toUpperCase() + type.substring(1)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedRoomType = value);
      },
    );
  }

  Widget _buildUpdateButton(ColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text('Save Changes'),
      ),
    );
  }
}
