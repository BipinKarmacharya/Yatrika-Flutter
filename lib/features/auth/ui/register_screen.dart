import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onRegisterSuccess});

  final VoidCallback? onRegisterSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    for (var controller in [
      _usernameController, _firstNameController, _lastNameController,
      _phoneController, _emailController, _passwordController, _confirmPasswordController
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill in all required fields");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }

    final auth = context.read<AuthProvider>();
    
    // Prepare data for the provider
    final userData = {
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
    };

    final success = await auth.register(userData);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!"), backgroundColor: Colors.green),
        );
        // AuthWrapper will handle navigation to Home automatically
        Navigator.pop(context); 
      } else {
        _showError(auth.errorMessage ?? "Registration failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(),
              const SizedBox(height: 32),
              const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28)),
              const SizedBox(height: 8),
              const Text('Sign up to start planning your dream trips', style: TextStyle(color: AppColors.subtext, fontSize: 15)),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildLabelledField('First Name', _firstNameController, hint: 'John', icon: Icons.person_outline)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLabelledField('Last Name', _lastNameController, hint: 'Doe', icon: Icons.person_outline)),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabelledField('Username', _usernameController, hint: 'johndoe123', icon: Icons.alternate_email),
              const SizedBox(height: 20),
              _buildLabelledField('Email', _emailController, hint: 'email@example.com', icon: Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabelledField('Phone Number', _phoneController, hint: '+1 234...', icon: Icons.phone_outlined, type: TextInputType.phone),
              const SizedBox(height: 20),
              
              _buildLabelledField(
                'Password', _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true, 
                obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)
              ),
              const SizedBox(height: 20),
              _buildLabelledField(
                'Confirm Password', _confirmPasswordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true, 
                obscure: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
              ),
              const SizedBox(height: 20),

              _buildTermsCheckbox(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_agreeToTerms && !auth.isLoading) ? _handleRegister : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.stroke,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.stroke)),
        child: const Icon(Icons.chevron_left, color: AppColors.text),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          activeColor: AppColors.primary,
        ),
        const Expanded(
          child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(color: AppColors.subtext, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildLabelledField(String label, TextEditingController controller, {required String hint, required IconData icon, bool isPassword = false, bool obscure = false, VoidCallback? onToggle, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.stroke)),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppColors.subtext),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.subtext),
                onPressed: onToggle,
              ) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}