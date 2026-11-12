import 'package:material_ui/material_ui.dart';

Widget googleButton({required VoidCallback? onPressed}) => OutlinedButton(
  onPressed: onPressed,
  child: const Text('Sign in with Google'),
);
