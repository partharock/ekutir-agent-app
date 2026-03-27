import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common.dart';
import '../theme/app_colors.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _controller.text.trim().length >= 10;

    return AuthBackground(
      backgroundAssetPath: 'assets/reference/auth_signin_blur.png',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 56)),
                    const SizedBox(height: 20),
                    Text(
                      'Sign In To Your Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Phone Number *',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('phone_number_field'),
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: '+91   ',
                        hintText: 'Enter your phone number',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('send_otp_button'),
                      style: filledButtonStyle(),
                      onPressed: canContinue
                          ? () {
                              context
                                  .read<AppState>()
                                  .beginSignIn(_controller.text.trim());
                              context.push('/otp');
                            }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Send OTP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingPhone =
        context.watch<AppState>().pendingPhoneNumber ?? 'XX XXXX 4331';
    final value = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');

    return AuthBackground(
      backgroundAssetPath: 'assets/reference/auth_signin_blur.png',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 56)),
                    const SizedBox(height: 20),
                    Text(
                      'Verify Your Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OTP sent to +91 $pendingPhone',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Stack(
                        children: [
                          Row(
                            children: List.generate(4, (index) {
                              final digit =
                                  index < value.length ? value[index] : '0';
                              return Expanded(
                                child: Container(
                                  height: 74,
                                  margin: EdgeInsets.only(
                                    right: index == 3 ? 0 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    digit,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.02,
                              child: TextField(
                                key: const Key('otp_field'),
                                controller: _controller,
                                focusNode: _focusNode,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                onChanged: (_) => setState(() {
                                  _error = null;
                                }),
                                decoration:
                                    const InputDecoration(counterText: ''),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('submit_otp_button'),
                      style: filledButtonStyle(),
                      onPressed: () {
                        final success =
                            context.read<AppState>().verifyOtp(value);
                        if (success) {
                          context.go('/home');
                        } else {
                          setState(() {
                            _error = 'Enter any valid 4 digit OTP to continue.';
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Submit'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _error = 'Mock OTP resent. Use any 4 digits.';
                        });
                      },
                      child: const Text('Resend OTP'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
