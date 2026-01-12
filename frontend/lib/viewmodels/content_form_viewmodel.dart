import 'package:flutter/foundation.dart';

import '../data/models/site.dart';
import '../services/content_service.dart';

/// ViewModel pour le formulaire de création
class ContentFormViewModel extends ChangeNotifier {
  final ContentService _contentService;

  bool _isLoading = false;
  bool _isSiteLoading = true;
  String? _error;
  Site? _userSite;

  String _title = '';
  String _mediaUrl = '';
  DateTime? _startDate;
  DateTime? _endDate;

  ContentFormViewModel(this._contentService);

  bool get isLoading => _isLoading;
  bool get isSiteLoading => _isSiteLoading;
  bool get hasSite => _userSite != null;
  String? get error => _error;
  Site? get userSite => _userSite;

  String get title => _title;
  String get mediaUrl => _mediaUrl;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setMediaUrl(String value) {
    _mediaUrl = value;
    notifyListeners();
  }

  void setStartDate(DateTime? value) {
    _startDate = value;
    if (_endDate != null && value != null && !_endDate!.isAfter(value)) {
      _endDate = null;
    }
    notifyListeners();
  }

  void setEndDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  Future<void> loadUserSite() async {
    _isSiteLoading = true;
    notifyListeners();

    try {
      _userSite = await _contentService.getUserSite();
    } catch (e) {
      _userSite = null;
    } finally {
      _isSiteLoading = false;
      notifyListeners();
    }
  }

  String? validateForm() {
    if (_title.trim().isEmpty) {
      return 'Le titre est obligatoire';
    }
    if (_startDate == null) {
      return 'La date de début est obligatoire';
    }
    if (_endDate == null) {
      return 'La date de fin est obligatoire';
    }
    if (!_endDate!.isAfter(_startDate!)) {
      return 'La date de fin doit être après la date de début';
    }
    return null;
  }

  Future<bool> submit() async {
    final validationError = validateForm();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _contentService.createContent(
        title: _title.trim(),
        mediaUrl: _mediaUrl.isNotEmpty ? _mediaUrl : null,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      _isLoading = false;

      if (result.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = result.errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _title = '';
    _mediaUrl = '';
    _startDate = null;
    _endDate = null;
    _error = null;
    notifyListeners();
  }
}
