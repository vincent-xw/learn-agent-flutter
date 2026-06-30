import 'package:flutter/foundation.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class ToolInvocationLogStore extends ChangeNotifier {
  final List<ToolInvocationLog> _items = [];

  List<ToolInvocationLog> get items => List.unmodifiable(_items);

  void add(ToolInvocationLog item) {
    _items.insert(0, item);
    notifyListeners();
  }
}
