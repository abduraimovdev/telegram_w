import 'package:http/http.dart' as http;

void main() async {
  // Bot 1
  // String token = '5154976143:AAFWmjrLK2eH-90ea1eGhx_MIZ1j8hf--Lk';
  // String id = '5154976143';

  // Bot 2
  String token = '5318145177:AAG2QAeqMKILOenVLjVOUjsml1FiW5h58Jo';
  String id = '5318145177';

  // await getData(token);
  add(token, id);
}

void add(String token , String id) async {
  final result = await http.get(Uri.parse("https://api.telegram.org/bot$token/setWebhook?url=https://tgw.jprq.app/webhook?bot_id=$id"));
  print(result.body);
}

void remove(String token) async {
  final result = await http.get(Uri.parse("https://api.telegram.org/bot$token/deleteWebhook"));
  print(result.body);
}

Future<void> getData(String token) async {
  final result = await http.get(Uri.parse("https://api.telegram.org/bot$token/getMe"));
  print(result.body);
}
