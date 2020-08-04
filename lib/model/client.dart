import 'package:googleapis_auth/auth.dart';

class Client {
  AutoRefreshingAuthClient client;

  Client(this.client);

  Client.fromJson(Map<String, dynamic> json) : client = json['client'];

  Map<String, dynamic> toJson() => {'client': client};
}
