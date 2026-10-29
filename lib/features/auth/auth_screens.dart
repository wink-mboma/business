
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import 'auth_state.dart';

// -----------------------------------------------------------------------------
// AUTH FRAME
// -----------------------------------------------------------------------------

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.eyebrow = 'MONO STORE',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: leading ??
                            _BackButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                            ),
                      ),
                      const SizedBox(height: 24),
                      const _MonoBrand(),
                      const SizedBox(height: 44),
                      Text(
                        eyebrow.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          fontSize: 32,
                          height: 1.15,
                          letterSpacing: -1.1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.65,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      child,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MonoBrand extends StatelessWidget {
  const _MonoBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset("assets/dark-logo.png"),
          ),
        ),
        const SizedBox(height: 12),
         Image.asset("assets/light-logo2.png", height: 40, width: 150,),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.black,
            size: 21,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LOGIN
// -----------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Welcome back.',
      subtitle: 'Sign in to discover your favourites and continue shopping.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              _email,
              'Email address',
              icon: Icons.mail_outline_rounded,
              type: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!email.contains('@') ||
                    email.startsWith('@') ||
                    !email.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: (value) =>
              (value == null || value.length < 6)
                  ? 'Enter at least 6 characters'
                  : null,
              onFieldSubmitted: (_) => _signIn(),
              decoration: _decoration(
                'Password',
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _primaryButton(
              label: 'Sign in',
              onPressed: _signIn,
            ),
            const SizedBox(height: 26),
            _authDivider(),
            const SizedBox(height: 18),
            _switchText(
              "Don't have an account?",
              'Create account',
                  () => context.push('/register'),
            ),
            const SizedBox(height: 28),
            const _DemoNotice(),
          ],
        ),
      ),
    );
  }

  bool _submitting = false;

  Future<void> _signIn() async {
    if (!_form.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).login(email:_email.text,password:_password.text);
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString().replaceFirst('Exception: ',''))));
    } finally { if (mounted) setState(() => _submitting = false); }
  }
}

// -----------------------------------------------------------------------------
// REGISTER
// -----------------------------------------------------------------------------

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  XFile? _profilePhoto;
  final ImagePicker _imagePicker = ImagePicker();
  Future<void> _pickProfilePhoto() async { final file=await _imagePicker.pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:900); if(file!=null&&mounted)setState(()=>_profilePhoto=file); }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Create your account.',
      subtitle:
      'Join Mono Store for a more personal and seamless shopping experience.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child:Column(children:[GestureDetector(onTap:_pickProfilePhoto,child:Container(width:104,height:104,decoration:BoxDecoration(shape:BoxShape.circle,color:AppColors.grey100,border:Border.all(color:AppColors.grey200,width:1.5)),child:ClipOval(child:_profilePhoto==null?const Icon(Icons.add_a_photo_outlined,size:32,color:AppColors.grey600):FutureBuilder<Uint8List>(future:_profilePhoto!.readAsBytes(),builder:(context,snapshot)=>snapshot.hasData?Image.memory(snapshot.data!,width:104,height:104,fit:BoxFit.cover):const Center(child:CircularProgressIndicator(strokeWidth:2)))))),const SizedBox(height:9),Text(_profilePhoto==null?'Add a profile photo (optional)':'Change profile photo',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:AppColors.grey600)),const SizedBox(height:18)])),
            _field(
              _name,
              'Full name',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
              (value == null || value.trim().length < 2)
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 16),
            _field(
              _email,
              'Email address',
              icon: Icons.mail_outline_rounded,
              type: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!email.contains('@') ||
                    email.startsWith('@') ||
                    !email.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _field(
              _phone,
              'Phone number',
              icon: Icons.phone_outlined,
              type: TextInputType.phone,
              validator: (value) =>
              (value == null || value.trim().length < 7)
                  ? 'Enter a valid phone number'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: (value) =>
              (value == null || value.length < 6)
                  ? 'Use at least 6 characters'
                  : null,
              decoration: _decoration(
                'Create password',
                Icons.lock_outline_rounded,
              ).copyWith(
                helperText: 'Use at least 6 characters.',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _primaryButton(
              label: _submitting ? 'Creating account…' : 'Create account',
              onPressed: _register,
            ),
            const SizedBox(height: 24),
            _switchText(
              'Already have an account?',
              'Sign in',
                  () => context.go('/login'),
            ),
            const SizedBox(height: 24),
            const _DemoNotice(),
          ],
        ),
      ),
    );
  }
  Future<void> _register() async {
    if (!_form.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).register(
        name:_name.text, email:_email.text, phone:_phone.text, password:_password.text,
      );
      if (_profilePhoto != null) {
        try {
          final bytes = await _profilePhoto!.readAsBytes();
          await ref.read(authProvider.notifier).updateProfileImage(_profilePhoto!.name, bytes);
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your account was created, but the profile photo could not upload. You can try again later.')));
        }
      }
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString().replaceFirst('Exception: ',''))));
    } finally { if (mounted) setState(() => _submitting = false); }
  }
}

// -----------------------------------------------------------------------------
// OTP VERIFICATION — SIX PIN BOXES
// -----------------------------------------------------------------------------

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.details});

  final Map<String, String>? details;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _pinLength = 6;

  final List<TextEditingController> _controllers =
  List.generate(_pinLength, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(_pinLength, (_) => FocusNode());

  String _channel = 'Email';

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code =>
      _controllers.map((controller) => controller.text).join();

  String get _destination {
    if (_channel == 'Email') {
      return widget.details?['email'] ?? 'your email address';
    }
    return widget.details?['phone'] ?? 'your WhatsApp number';
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Verify it’s you.',
      subtitle:
      'We’ll use a one-time code to help keep your Mono Store account secure.',
      eyebrow: 'ACCOUNT SECURITY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _channel == 'Email'
                        ? Icons.mail_outline_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification destination',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _destination,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'Email',
                label: Text('Email'),
                icon: Icon(Icons.mail_outline_rounded),
              ),
              ButtonSegment<String>(
                value: 'WhatsApp',
                label: Text('WhatsApp'),
                icon: Icon(Icons.chat_outlined),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (selection) {
              setState(() => _channel = selection.first);
            },
            style: SegmentedButton.styleFrom(
              foregroundColor: AppColors.black,
              selectedForegroundColor: AppColors.white,
              selectedBackgroundColor: AppColors.black,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Enter the 6-digit code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter each digit in the box below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              _pinLength,
                  (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == _pinLength - 1 ? 0 : 7,
                  ),
                  child: _PinBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.length > 1) {
                        // Handle multi-character input gracefully.
                        final digits = value.replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        for (var i = 0; i < _pinLength; i++) {
                          _controllers[i].text =
                          i < digits.length ? digits[i] : '';
                        }
                        final nextIndex =
                        digits.length.clamp(0, _pinLength - 1);
                        _focusNodes[nextIndex].requestFocus();
                        setState(() {});
                        return;
                      }

                      if (value.isNotEmpty && index < _pinLength - 1) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }

                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _primaryButton(
            label: 'Verify and continue',
            onPressed: _verify,
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Didn’t receive a code?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                ),
                TextButton(
                  onPressed: _resendCode,
                  child: const Text(
                    'Resend code',
                    style: TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _DemoNotice(),
        ],
      ),
    );
  }

  void _verify() {
    if (_code.length != _pinLength ||
        _controllers.any((controller) => controller.text.isEmpty)) {
      _showMessage('Please enter all six digits.');
      return;
    }

    _showMessage('Account verification is not enabled yet. Create your account using the registration form.');
  }

  void _resendCode() {
    // Replace this with your email/WhatsApp OTP API call.
    _showMessage(
      'OTP delivery will be enabled when the backend is connected.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 60,
          decoration: BoxDecoration(
            color: focused ? AppColors.white : AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? AppColors.black : AppColors.grey200,
              width: focused ? 1.6 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// FORGOT PASSWORD
// -----------------------------------------------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Forgot your password?',
      subtitle:
      'Enter the email address linked to your account to begin resetting your password.',
      eyebrow: 'ACCOUNT RECOVERY',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              _email,
              'Email address',
              icon: Icons.mail_outline_rounded,
              type: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _primaryButton(
              label: 'Send reset instructions',
              onPressed: () {
                if (!_form.currentState!.validate()) return;

                // Replace this message with your password reset API call.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password reset will be available when the backend is connected.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
              ),
              child: const Text('Back to sign in'),
            ),
            const SizedBox(height: 20),
            const _DemoNotice(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED UI COMPONENTS
// -----------------------------------------------------------------------------

InputDecoration _decoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: AppColors.grey600,
      fontSize: 14,
    ),
    prefixIcon: Icon(
      icon,
      size: 21,
      color: AppColors.grey600,
    ),
    filled: true,
    fillColor: AppColors.grey50,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 19,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: AppColors.black,
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  );
}

Widget _field(
    TextEditingController controller,
    String label, {
      required IconData icon,
      TextInputType? type,
      TextCapitalization textCapitalization = TextCapitalization.none,
      String? Function(String?)? validator,
    }) {
  return TextFormField(
    controller: controller,
    keyboardType: type,
    textCapitalization: textCapitalization,
    textInputAction: TextInputAction.next,
    validator: validator,
    decoration: _decoration(label, icon),
  );
}

Widget _primaryButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_rounded, size: 19),
        ],
      ),
    ),
  );
}

Widget _switchText(
    String before,
    String action,
    VoidCallback onPressed,
    ) {
  return Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        before,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.grey600,
        ),
      ),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.black,
        ),
        child: Text(
          action,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

Widget _authDivider() {
  return Row(
    children: [
      const Expanded(child: Divider(color: AppColors.grey200)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          'YOUR MONO ACCOUNT',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.grey600,
          ),
        ),
      ),
      const Expanded(child: Divider(color: AppColors.grey200)),
    ],
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.grey600,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Customer login and registration are connected. Email/WhatsApp OTP and password recovery will be added separately.',
              style: TextStyle(
                fontSize: 11,
                height: 1.6,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
