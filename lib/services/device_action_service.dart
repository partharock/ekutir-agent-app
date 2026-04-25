import '../models/farmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class DeviceActionService {
  Future<bool> callPhone(String phoneNumber);
  Future<bool> sendSms(String phoneNumber, {String? body});
  Future<bool> shareText({required String text, String? subject});
  Future<bool> openMapLocation(PlotLocation plotLocation, {String? label});
}

class PlatformDeviceActionService implements DeviceActionService {
  @override
  Future<bool> callPhone(String phoneNumber) {
    return _launch(Uri(scheme: 'tel', path: phoneNumber));
  }

  @override
  Future<bool> sendSms(String phoneNumber, {String? body}) {
    return _launch(
      Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: body == null || body.isEmpty ? null : {'body': body},
      ),
    );
  }

  @override
  Future<bool> shareText({required String text, String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openMapLocation(PlotLocation plotLocation, {String? label}) {
    return _launch(
      buildMapplsLocationUri(
        plotLocation,
        label: label,
      ),
    );
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

Uri buildMapplsLocationUri(PlotLocation plotLocation, {String? label}) {
  final queryParameters = <String, String>{};
  if (label != null && label.trim().isNotEmpty) {
    queryParameters['title'] = label.trim();
  }
  return Uri.https(
    'mappls.com',
    '/location/${plotLocation.center.latitude},${plotLocation.center.longitude}',
    queryParameters.isEmpty ? null : queryParameters,
  );
}
