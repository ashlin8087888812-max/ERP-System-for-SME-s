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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Card
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 350, minHeight: 320),
              alignment: Alignment(-0.6,-0.8),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(16),
              ),
              //SYNCERELY
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SYN',
                    style: TextStyle(
                      fontFamily: 'First',
                      fontSize: 40,
                      color: const Color(0xFF1E1E1E),
                      height: 1,
                    ),
                  ),
                  Text(
                    'CER',
                    style: TextStyle(
                      fontFamily: 'First',
                      fontSize: 40,
                      color: const Color(0xFF1E1E1E),
                      height: 1,
                    ),
                  ),
                  Text(
                    'ELY',
                    style: TextStyle(
                      fontFamily: 'First',
                      fontSize: 40,
                      color: const Color(0xFF1E1E1E),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Login Using Label
            const Text(
              'LOGIN USING',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Login Form
            Container(
              constraints: const BoxConstraints(maxWidth: 350),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(30),
              ),
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
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child:TextFormField(
                              controller: _emailController,
                              style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                              textAlignVertical: TextAlignVertical(y: 0.2),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                hintText: 'EMAIL',
                                hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(left: 16.0,top: 8),
                                  child: tabler.MailFilled(color: Colors.black87, height: 35),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16,),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Submit Button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Material(
                            color:authState.isLoading
                                    ? palette.primary: Color(0xff1c1c1c),
                            child: InkWell(
                              hoverColor: Color(0xff000000),
                              splashColor: palette.primary,
                              onTap: authState.isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        ref.read(authProvider.notifier).login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );
                                      }
                                    },
                              child: Container(
                                width: 60,
                                height: 60,
                                padding: EdgeInsets.all(authState.isLoading
                                    ? 4:12),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: authState.isLoading
                                    ? Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 6,
                                          valueColor: AlwaysStoppedAnimation<Color>(palette.black),
                                        ),
                                      )
                                    : tabler.ArrowRightToArc(color: authState.isLoading
                                    ? palette.black:Color(0xFFD9D9D9) , height: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Password Field
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                        textAlignVertical: TextAlignVertical(y: 0),
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          hintText: 'PASSWORD',
                          hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                          prefixIcon: tabler.Password(color: Colors.black87, height: 80),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16,),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildQrSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AuthState authState) {
    return Center(
      child: Container(
        constraints: const BoxConstraints( maxHeight: 600),
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            // Left Card
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SYN',
                        style: TextStyle(
                          fontFamily: 'First',
                          fontSize: 80,
                          color: const Color(0xFF1E1E1E),
                          height: 1,
                        ),
                      ),
                      Text(
                        'CER',
                        style: TextStyle(
                          fontFamily: 'First',
                          fontSize: 80,
                          color: const Color(0xFF1E1E1E),
                          height: 1,
                        ),
                      ),
                      Text(
                        'ELY',
                        style: TextStyle(
                          fontFamily: 'First',
                          fontSize: 80,
                          color: const Color(0xFF1E1E1E),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
            
            // Right Side
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'LOGIN USING',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Desktop Login Form
                  Container(
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 350),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(30),
                    ),
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
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child:TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                                    textAlignVertical: TextAlignVertical(y: 0.2),
                                    textAlign: TextAlign.end,
                                    decoration: const InputDecoration(
                                      hintText: 'EMAIL',
                                      hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.only(left: 16.0,top: 8),
                                        child: tabler.MailFilled(color: Colors.black87, height: 35),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16,),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Submit Button
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Material(
                                  color:authState.isLoading
                                          ? palette.primary: Color(0xff1c1c1c),
                                  child: InkWell(
                                    hoverColor: Color(0xff000000),
                                    splashColor: palette.primary,
                                    onTap: authState.isLoading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!.validate()) {
                                              ref.read(authProvider.notifier).login(
                                                    _emailController.text,
                                                    _passwordController.text,
                                                  );
                                            }
                                          },
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      padding: EdgeInsets.all(authState.isLoading
                                          ? 4:12),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: authState.isLoading
                                          ? Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 6,
                                                valueColor: AlwaysStoppedAnimation<Color>(palette.black),
                                              ),
                                            )
                                          : tabler.ArrowRightToArc(color: authState.isLoading
                                          ? palette.black:Color(0xFFD9D9D9) , height: 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          // Password Field
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(fontFamily: 'Practa', fontSize: 14),
                              textAlignVertical: TextAlignVertical(y: 0),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                hintText: 'PASSWORD',
                                hintStyle: TextStyle(fontFamily: 'Practa', fontSize: 12, color: Colors.black54),
                                prefixIcon: tabler.Password(color: Colors.black87, height: 80),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16,),
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildQrSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      height: 80,
      constraints: const BoxConstraints(maxWidth: 350),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // QR Text Left (Vertical "USE QR")
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              const SizedBox(width: 10),
              Text('U\nS\nE', style: TextStyle(fontFamily: 'PressStart2P', fontSize: 20, height: 1, fontWeight: FontWeight.bold),),
              const SizedBox(width: 6),
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
            child: const tabler.Qrcode(color: Colors.black87, height: 80),),
        ],
      ),
    );
  }
}
