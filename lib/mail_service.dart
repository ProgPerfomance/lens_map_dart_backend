import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void sendMail(email,mail) async {
  final smtpServer = gmail('jekcatpopov@gmail.com', 'favq gose ivmu qwvi');

  final message = Message()
    ..from = Address('jekcatpopov@gmail.com', 'Lens map')
    ..recipients.add(email)
    ..subject = 'Auth code'
    ..text = ''
    ..html = "<h1>Your code:</h1>\n<p>$mail</p>";

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Message not sent. \n${e.toString()}');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}
