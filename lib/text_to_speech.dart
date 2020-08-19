import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vocalize_it/api_key.dart';

var _apiKey = myApiKey;
var _voices = [
  {"languageCode": "en-AU", "name": "en-AU-Standard-C", "ssmlGender": "FEMALE"},
  {"languageCode": "en-IN", "name": "en-IN-Standard-D", "ssmlGender": "FEMALE"},
  {"languageCode": "en-IN", "name": "en-IN-Wavenet-B", "ssmlGender": "MALE"},
  {"languageCode": "en-GB", "name": "en-GB-Standard-B", "ssmlGender": "MALE"},
  {"languageCode": "en-US", "name": "en-US-Standard-C", "ssmlGender": "FEMALE"}
];

Future<http.Response> voiceResponse(String mytext, int index) async {
  String url =
      "https://texttospeech.googleapis.com/v1/text:synthesize?key=$_apiKey";
  var body = jsonEncode({
    "input": {"text": mytext},
    "voice": {
      "languageCode": _voices[index]['languageCode'],
      "name": _voices[index]['name'],
      "ssmlGender": _voices[index]['ssmlGender']
    },
    "audioConfig": {"audioEncoding": "MP3"}
  });
  var response = http.post(
    url,
    headers: {"Content-type": "application/json"},
    body: body,
  );
  return response;
}
