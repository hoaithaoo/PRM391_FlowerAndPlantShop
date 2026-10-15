import 'package:flutter/material.dart';

class ChatbotLauncher extends StatelessWidget {
  const ChatbotLauncher({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mở trợ lý tư vấn',
      child: Material(
        color: const Color(0xFF132B1E),
        elevation: 8,
        shadowColor: const Color(0x550D1E15),
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('chatbot-launcher'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 58,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}
