import 'package:material_ui/material_ui.dart';
import 'package:google_sign_in_web/web_only.dart' as google;

Widget googleButton({required VoidCallback? onPressed}) => onPressed == null
    ? const Text('Google sign-in is not ready')
    : google.renderButton();
