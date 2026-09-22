import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../models/daily_usage.dart';
import '../services/firestore_service.dart';

/// Provider managing usage history and trend analytics
class HistoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<DailyUsage> _history = [];
  bool _isLoading = false;
  int _selectedDays = 7;
  String? _errorMessage;

  List<DailyUsage> get history => _history;
  bool get isLoading => _isLoading;
  int get selectedDays => _selectedDays;
  String? get errorMessage => _errorMessage;

  /// Average screen time in minutes over the loaded history
  double get averageScreenTimeMinutes {
    if (_history.isEmpty) return 0.0;
    final total = _history.fold<int>(0, (sum, item) => sum + item.totalScreenTimeMinutes);
    return total / _history.length;
  }

  /// Average digital addiction risk score over the loaded history
  double get averageRiskScore {
    if (_history.isEmpty) return 0.0;
    final total = _history.fold<int>(0, (sum, item) => sum + item.riskScore);
    return total / _history.length;
  }

  /// Aggregated category totals in minutes over the loaded timeframe
  Map<AppCategory, int> get categoryTimeTotals {
    final Map<AppCategory, int> totals = {
      AppCategory.socialMedia: 0,
      AppCategory.gaming: 0,
      AppCategory.entertainment: 0,
      AppCategory.education: 0,
      AppCategory.productivity: 0,
      AppCategory.communication: 0,
      AppCategory.other: 0,
    };

    for (final day in _history) {
      totals[AppCategory.socialMedia] = (totals[AppCategory.socialMedia] ?? 0) + day.socialMediaTime;
      totals[AppCategory.gaming] = (totals[AppCategory.gaming] ?? 0) + day.gamingTime;
      totals[AppCategory.entertainment] = (totals[AppCategory.entertainment] ?? 0) + day.entertainmentTime;
      totals[AppCategory.education] = (totals[AppCategory.education] ?? 0) + day.educationTime;
      totals[AppCategory.productivity] = (totals[AppCategory.productivity] ?? 0) + day.productivityTime;
      totals[AppCategory.communication] = (totals[AppCategory.communication] ?? 0) + day.communicationTime;
      totals[AppCategory.other] = (totals[AppCategory.other] ?? 0) + day.otherTime;
    }

    return totals;
  }

  /// Fetches historical usage for the given number of days
  Future<void> fetchHistory(String uid, {int days = 7}) async {
    _isLoading = true;
    _selectedDays = days;
    _errorMessage = null;
    notifyListeners();

    try {
      final records = await _firestoreService.getUsageHistory(uid, limitDays: days);
      _history = records;
    } catch (e) {
      _errorMessage = 'Failed to load history: $e';
      debugPrint('Error in fetchHistory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the active timeframe (7, 14, 30 days)
  Future<void> setTimeframe(String uid, int days) async {
    if (_selectedDays == days) return;
    await fetchHistory(uid, days: days);
  }
}
