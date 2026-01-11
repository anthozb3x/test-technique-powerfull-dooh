import 'package:flutter/foundation.dart';

import '../data/models/content.dart';
import '../services/content_service.dart';

enum ContentListState { initial, loading, loaded, error }

class ContentListViewModel extends ChangeNotifier {
  final ContentService _contentService;

  ContentListState _state = ContentListState.initial;
  List<Content> _contents = [];
  String? _error;

  ContentListViewModel(this._contentService);

  ContentListState get state => _state;
  List<Content> get contents => _contents;
  String? get error => _error;
  bool get isEmpty => _contents.isEmpty;

  Future<void> loadContents() async {
    _state = ContentListState.loading;
    _error = null;
    notifyListeners();

    try {
      _contents = await _contentService.getContents();
      _state = ContentListState.loaded;
    } catch (e) {
      _error = 'Impossible de charger les contenus';
      _state = ContentListState.error;
    }

    notifyListeners();
  }

  Future<void> refresh() => loadContents();
}
