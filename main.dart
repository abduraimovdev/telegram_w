import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

// Bot tokenlari ro'yxati (faylda yoki DB’da bo'lishi mumkin)
final Map<String, String> bots = {};

// Umumiy webhookni boshqaruvchi funksiya
Future<Response> handleWebhook(Request request) async {
  print('Nimadir');

  // URL'dan bot identifikatorini olamiz (masalan, bot1 yoki bot2)
  var botId = request.url.queryParameters['bot_id'];

  if (botId == null || !bots.containsKey(botId)) {
    return Response.notFound('Noto‘g‘ri bot identifikatori');
  }

  var botToken = bots[botId];
  if (botToken == null) {
    print('Token topilmadi ');
  }
  if (botToken == null) return Response.ok('Muammo bor');

  // So‘rovni o‘qib olamiz
  var content = await request.readAsString();
  var update = jsonDecode(content);

  // Xabar va chat_id ni olamiz
  var chatId = update['message']['chat']['id'].toString();
  var message = update['message']['text'];

  print('Yangi xabar keldi: $update');

  // Xabarni qaytarish uchun funksiyadan foydalanamiz
  await sendMessage(botToken, chatId, """Siz yuborgan xabar: $message
  
  Bot id : $botId
  Token : $botToken
  
  """);

  return Response.ok('Xabar qabul qilindi');
}

// Bot orqali xabar yuborish funksiyasi
Future<void> sendMessage(String botToken, String chatId, String text) async {
  var url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
  await http.post(url, body: {
    'chat_id': chatId,
    'text': text,
  });
}

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : '../specs/swagger.yaml';
  final swaggerHandler = SwaggerUI(
    path,
    title: 'Swagger Test',
    docExpansion: DocExpansion.full,
    syntaxHighlightTheme: SyntaxHighlightTheme.nord,
  );

  var app = Router();

  // Umumiy webhook yo'lini o'rnatamiz
  app.post('/webhook', handleWebhook);
  app.post('/add', addBot);
  app.delete('/remove', removeBot);
  app.mount('/', swaggerHandler.call);

  var server = await io.serve(app.call, InternetAddress.anyIPv4, 8228);
  print('Server ishlamoqda: http://${server.address.host}:${server.port}');
}

// Umumiy webhookni boshqaruvchi funksiya
Future<Response> addBot(Request request) async {
  print('Add Bot');

  final botJson = await request.readAsString();
  print(botJson);
  print(jsonDecode(botJson));
  String? token = jsonDecode(botJson)['token'];
  if (token == null) {
    return Response.badRequest(body: errorResponse('Iltimos tekshirib qayta urinib koring'));
  }
  final bot = await getData(token);
  if (bot == null || bot.bot.id == 0) {
    return Response.badRequest(body: errorResponse("Botdan Ma'lumotlarni olib bo'lmadi !"));
  }
  bots[bot.bot.id.toString()] = token;
  final result = await add(token, bot.bot.id.toString());
  return Response.ok(result);
}

Future<Response> removeBot(Request request) async {
  print('Remove');

  final botJson = await request.readAsString();
  print(botJson);
  print(jsonDecode(botJson));
  String? token = jsonDecode(botJson)['token'];
  if (token == null) {
    return Response.badRequest(body: errorResponse('Iltimos tekshirib qayta urinib koring'));
  }
  final bot = await getData(token);
  if (bot == null || bot.bot.id == 0) {
    return Response.badRequest(body: errorResponse("Botdan Ma'lumotlarni olib bo'lmadi !"));
  }
  await remove(token);
  final isContain = bots.containsKey(bot.bot.id.toString());
  if (isContain) {
    bots.remove(bot.bot.id.toString());
  }
  return Response.ok(jsonEncode({
    "result": isContain,
  }));
}

Future<String> add(String token, String id) async {
  final result = await http.get(Uri.parse("https://api.telegram.org/bot$token/setWebhook?url=https://tgbot.jprq.app/webhook?bot_id=$id"));
  return result.body;
}

Future<void> remove(String token) async {
  final result = await http.get(Uri.parse("https://api.telegram.org/bot$token/deleteWebhook"));
  print(result.body);
}

Future<BotState?> getData(String token) async {
  final result = await http.get(Uri.parse("https://api.telegram.org/bot$token/getMe"));
  final body = jsonDecode(result.body);
  print(body);
  if (body is Map) {
    return BotState.fromJson(body as Map<String, Object?>);
  } else {
    return null;
  }
}

final jspn = {
  "ok": true,
  "result": {
    "id": 5318145177,
    "is_bot": true,
    "first_name": "1 - WIN",
    "username": "aviatoruz_1win_bot",
    "can_join_groups": true,
    "can_read_all_group_messages": false,
    "supports_inline_queries": false,
    "can_connect_to_business": false,
    "has_main_web_app": false,
  },
};

class BotState {
  final bool ok;
  final Bot bot; //result
  const BotState({
    this.ok = false,
    this.bot = const Bot(),
  });

  factory BotState.fromJson(Map<String, Object?> json) {
    return BotState(
      ok: json['ok'] as bool? ?? false,
      bot: Bot.fromJson((json['result'] as Map<String, Object?>? ?? {})),
    );
  }

  Map<String, Object?> toJson() => {
        'ok': ok,
        'result': bot.toJson(),
      };
}

class Bot {
  final int id;
  final bool isBot;
  final String firstName;
  final String username;
  final bool canJoinGroups;
  final bool canReadAllGroupMessages;
  final bool supportsInlineQueries;
  final bool canConnectToBusiness;
  final bool hasMainWebApp;

  const Bot({
    this.id = 0,
    this.isBot = false,
    this.firstName = '',
    this.username = '',
    this.canJoinGroups = false,
    this.canReadAllGroupMessages = false,
    this.supportsInlineQueries = false,
    this.canConnectToBusiness = false,
    this.hasMainWebApp = false,
  });

  factory Bot.fromJson(Map<String, Object?> json) {
    return Bot(
      id: json['id'] as int? ?? 0,
      isBot: json['is_bot'] as bool? ?? false,
      firstName: json['first_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      canJoinGroups: json['can_join_groups'] as bool? ?? false,
      canReadAllGroupMessages: json['can_read_all_group_messages'] as bool? ?? false,
      supportsInlineQueries: json['supports_inline_queries'] as bool? ?? false,
      canConnectToBusiness: json['can_connect_to_business'] as bool? ?? false,
      hasMainWebApp: json['has_main_web_app'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'is_bot': isBot,
        'first_name': firstName,
        'username': username,
        'can_join_groups': canJoinGroups,
        'can_read_all_group_messages': canReadAllGroupMessages,
        'supports_inline_queries': supportsInlineQueries,
        'can_connect_to_business': canConnectToBusiness,
        'has_main_web_app': hasMainWebApp,
      };
}

String errorResponse(String text) {
  return jsonEncode({'error': text});
}
