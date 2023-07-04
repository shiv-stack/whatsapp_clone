import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';

import '../../../colors.dart';

class OTPScreen extends ConsumerWidget {
  static const String routeName = '/otp-Screen';
  final String VerificationId;
  const OTPScreen({
    Key? key,
    required this.VerificationId,
  }) : super(key: key);

  void verifyOTP(BuildContext context, String userOTP, WidgetRef ref) {
    ref
        .read(authControllerProvider)
        .verifyOTP(context, VerificationId, userOTP);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifying your number'),
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            const Text('We have sent an sms with the code'),
            SizedBox(
              width: size.width * 0.5,
              child: TextField(
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '- - - - - -',
                  hintStyle: TextStyle(
                    fontSize: 30,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  if (val.length == 6) {
                    verifyOTP(context, val.trim(), ref);
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
