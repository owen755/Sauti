import 'dart:js' as js;

void eval(List<dynamic> arguments) {
  js.context.callMethod('eval', arguments);
}