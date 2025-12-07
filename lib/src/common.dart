import 'package:logging/logging.dart';

final _logger = Logger.root;

class Common {
  static const int MaxFunctionArity = 255;

  static Logger get log => _logger;
}
