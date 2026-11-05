import 'package:flutter/material.dart';

Widget googleButton({required VoidCallback? onPressed}) => OutlinedButton(
  onPressed: onPressed,
  child: const Text('Sign in with Google'),
);
