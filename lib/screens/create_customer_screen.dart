import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../services/customer_api.dart';
import 'view_customer_screen.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  final CustomerApi _api = CustomerApi();

  // Error messages state
  String? _nameError;
  String? _mobileError;
  String? _emailError;
  String? _addressError;

  // Mobile validator
  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    final cleaned = value.trim();
    if (cleaned.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^[5-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile must start with 5, 6, 7, 8, or 9';
    }
    return null;
  }

  // Email validator
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final email = value.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Auto-convert email to lowercase
  void _onEmailChanged(String value) {
    final lower = value.toLowerCase();
    if (value != lower) {
      _emailController.value = TextEditingValue(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
    }
    _updateEmailError(lower);
  }

  void _updateNameError(String value) {
    setState(() {
      _nameError = value.trim().isEmpty ? 'Please enter customer name' : null;
    });
  }

  void _updateMobileError(String value) {
    setState(() {
      _mobileError = _validateMobile(value);
    });
  }

  void _updateEmailError(String value) {
    setState(() {
      _emailError = _validateEmail(value);
    });
  }

  void _updateAddressError(String value) {
    setState(() {
      _addressError = value.trim().isEmpty ? 'Please enter address' : null;
    });
  }

  bool _isFormValid() {
    return _nameError == null &&
        _mobileError == null &&
        _emailError == null &&
        _addressError == null &&
        _nameController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  Future<void> _submitCustomer() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors above')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _api.createCustomer(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      if (response.success == true) {
        showSuccessToast(context, "Customer created successfully!");
        // Navigate to the View Customers screen after successful creation
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ViewCustomerScreenFixed()),
        );
      } else {
        showErrorToast(
          context,
          response.message ?? "Failed to create customer.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorToast(context, "Network error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        title: Text(
          'Create Customer',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a new customer to the system',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              _buildTextField(
                label: 'Customer Name',
                controller: _nameController,
                icon: Icons.person,
                errorText: _nameError,
                onChanged: _updateNameError,
              ),
              const SizedBox(height: 16),

              // Mobile Field
              _buildTextField(
                label: 'Mobile',
                controller: _mobileController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                errorText: _mobileError,
                onChanged: _updateMobileError,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: _onEmailChanged,
              ),
              const SizedBox(height: 16),

              // Address Field
              _buildTextField(
                label: 'Address',
                controller: _addressController,
                icon: Icons.location_on,
                isMultiLine: true,
                errorText: _addressError,
                onChanged: _updateAddressError,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Create Customer',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool isMultiLine = false,
    String? errorText,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType:
              keyboardType ??
              (isMultiLine ? TextInputType.multiline : TextInputType.text),
          maxLines: isMultiLine ? 3 : 1,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : const Color.fromRGBO(0, 140, 192, 1),
              ),
            ),
            errorText: null, // We show error below manually
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
        ),
        // Dynamic Error Message with Animation
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: AnimatedOpacity(
              opacity: errorText.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                errorText,
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (errorText != null) const SizedBox(height: 8),
      ],
    );
  }
}
