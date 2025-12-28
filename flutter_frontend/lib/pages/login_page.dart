import 'package:flumpose/flumpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/utils/palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${next.user!.email}!')),
        );
      } else if (next.error != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Error'),
            content: SelectableText(next.error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(context, authState);
          } else {
            return _buildMobileLayout(context, authState);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AuthState authState) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Card
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350, minHeight: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SYN', style: TextStyle(fontFamily: 'First', fontSize: 40, color: Color(0xFF1E1E1E), height: 1)),
                const Text('CER', style: TextStyle(fontFamily: 'First', fontSize: 40, color: Color(0xFF1E1E1E), height: 1)),
                const Text('ELY', style: TextStyle(fontFamily: 'First', fontSize: 40, color: Color(0xFF1E1E1E), height: 1)),
              ],
            )
            .align(const Alignment(-0.6, -0.8))
            .width(double.infinity)
            .decorate((d) => d.color(const Color(0xFFD9D9D9)).circular(16)),
          ),

          const SizedBox(height: 40),

          // Login Using Label
          const Text('LOGIN USING', style: TextStyle(fontFamily: 'PressStart2P', fontSize: 10, color: Colors.white)),
          const SizedBox(height: 16),

          // Login Form
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email Row with Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          child: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                            textAlignVertical: const TextAlignVertical(y: 0.2),
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              hintText: 'EMAIL',
                              hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 16.0, top: 8),
                                child: tabler.MailFilled(color: Colors.black87, height: 35),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        )
                        .decorate((d) => d.color(Colors.black12).circular(30)),
                      ),
                      const SizedBox(width: 12),
                      // Submit Button
                      Container(
                        width: 60,
                        height: 60,
                        padding: EdgeInsets.all(authState.isLoading ? 4 : 12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: authState.isLoading
                            ? CircularProgressIndicator(
                                strokeWidth: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(palette.black),
                              ).pad(12)
                            : tabler.ArrowRightToArc(
                                color: authState.isLoading ? palette.black : const Color(0xFFD9D9D9),
                                height: 12,
                              ),
                      ).inkTap(
                        onTap: authState.isLoading
                            ? () {}
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  ref.read(authProvider.notifier).login(
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                }
                              },
                        splashColor: palette.primary,
                        color: authState.isLoading ? palette.primary : const Color(0xff1c1c1c),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Password Field
                  Container(
                    height: 60,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                      textAlignVertical: const TextAlignVertical(y: 0),
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        hintText: 'PASSWORD',
                        hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                        prefixIcon: tabler.Password(color: Colors.black87, height: 80),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  )
                  .decorate((d) => d.color(Colors.black12).circular(30)),
                ],
              ),
            )
            .pad(10)
            .decorate((d) => d.color(const Color(0xFFD9D9D9)).circular(30)),
          ),

          const SizedBox(height: 20),
          _buildQrSection(),
        ],
      ).pad(24).alignCenter(),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AuthState authState) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 600),
      child: Row(
        children: [
          // Left Card
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('SYN', style: TextStyle(fontFamily: 'First', fontSize: 80, color: Color(0xFF1E1E1E), height: 1)),
                const Text('CER', style: TextStyle(fontFamily: 'First', fontSize: 80, color: Color(0xFF1E1E1E), height: 1)),
                const Text('ELY', style: TextStyle(fontFamily: 'First', fontSize: 80, color: Color(0xFF1E1E1E), height: 1)),
              ],
            )
                .alignCenter()
                .decorate((d) => d.color(const Color(0xFFD9D9D9)).circular(4)), 
          ),
          const SizedBox(width: 60),

          // Right Side
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('LOGIN USING', style: TextStyle(fontFamily: 'PressStart2P', fontSize: 12, color: Colors.white)),
                const SizedBox(height: 20),

                // Desktop Login Form
                ConstrainedBox(
                 constraints: const BoxConstraints(maxWidth: 350),
                 child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Row with Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 60,
                              child: TextFormField(
                                controller: _emailController,
                                style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                                textAlignVertical: const TextAlignVertical(y: 0.2),
                                textAlign: TextAlign.end,
                                decoration: const InputDecoration(
                                  hintText: 'EMAIL',
                                  hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(left: 16.0, top: 8),
                                    child: tabler.MailFilled(color: Colors.black87, height: 35),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            )
                            .decorate((d) => d.color(Colors.black12).circular(30)),
                          ),
                          const SizedBox(width: 12),
                          // Submit Button
                          Container(
                            width: 60,
                            height: 60,
                            padding: EdgeInsets.all(authState.isLoading ? 4 : 12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: authState.isLoading
                                ? CircularProgressIndicator(
                                    strokeWidth: 6,
                                    valueColor: AlwaysStoppedAnimation<Color>(palette.black),
                                  ).pad(12)
                                : tabler.ArrowRightToArc(
                                    color: authState.isLoading ? palette.black : const Color(0xFFD9D9D9),
                                    height: 12,
                                  ),
                          ).inkTap(
                            onTap: authState.isLoading
                                ? () {}
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      ref.read(authProvider.notifier).login(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                    }
                                  },
                            splashColor: palette.primary,
                            color: authState.isLoading ? palette.primary : const Color(0xff1c1c1c),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // Password Field
                      Container(
                        height: 60,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                          textAlignVertical: const TextAlignVertical(y: 0),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            hintText: 'PASSWORD',
                            hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                            prefixIcon: tabler.Password(color: Colors.black87, height: 80),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      )
                      .decorate((d) => d.color(Colors.black12).circular(30)),
                    ],
                  ),
                )
                .pad(14)
                .decorate((d) => d.color(const Color(0xFFD9D9D9)).circular(30)),
               ),

                const SizedBox(height: 30),
                _buildQrSection(),
              ],
            ),
          ),
        ],
      )
          .pad(0)
          .alignCenter(),
    );
  }

  Widget _buildQrSection() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // QR Text Left (Vertical "USE QR")
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 10),
              Text('U\nS\nE', style: TextStyle(fontFamily: 'PressStart2P', fontSize: 20, height: 1, fontWeight: FontWeight.bold)),
              SizedBox(width: 6),
              Text('Q\nR', style: TextStyle(fontFamily: 'First', fontSize: 30, height: 1, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 16),
          const Text(
            'OR',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          // QR Icon Right
          FittedBox(
            fit: BoxFit.scaleDown,
            child: const tabler.Qrcode(color: Colors.black87, height: 80),
          ),
        ],
      )
          .padH(5).padV(5)
          .height(80)
          .decorate((d) => d.color(const Color(0xFFD9D9D9)).circular(20)),
    );
  }
}
