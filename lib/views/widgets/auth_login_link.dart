import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class AuthLoginLink extends StatelessWidget {
  const AuthLoginLink({super.key, this.prompt});
  final String? prompt;

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        if (prompt != null) Text(prompt!, style: AppTextStyles.sessionMeta),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Log in', style: TextStyle(fontSize: 14)),
        ),
      ],
    ),
  );
}
