import 'package:url_launcher/url_launcher.dart';

Future<void> abrirEnMaps(
    String direccion, {
      double? lat,
      double? lng,
    }) async {
  if (lat != null && lng != null) {
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  } else {
    final encoded = Uri.encodeComponent(direccion);
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}