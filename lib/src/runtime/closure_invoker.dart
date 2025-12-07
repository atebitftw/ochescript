import 'package:oche_script/src/runtime/obj.dart';
import 'package:oche_script/src/runtime/vm.dart';

/// Invokes a script closure with the given arguments.
///
/// The [vm] is the VM to use to invoke the closure.
/// The [closure] is the closure to invoke.
/// The [arguments] are the arguments to pass to the closure.
Future<Object?> invokeScriptClosure(VM vm, ObjClosure closure, List<dynamic> arguments) async {
  return await vm.callClosure(closure, arguments);
}
