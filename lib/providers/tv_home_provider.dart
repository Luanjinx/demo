import 'package:flutter/material.dart';
import '../models/section_model.dart';
import '../models/banner_model.dart';
import '../models/type_model.dart';
import '../webservice/api_service.dart';

class TVTabCache {
  final List<BannerItem> banners;
  final List<SectionItem> sections;
  final DateTime timestamp;

  TVTabCache({
    required this.banners,
    required this.sections,
    required this.timestamp,
  });
}

class TVHomeProvider extends ChangeNotifier {
  final TVApiService _api = TVApiService();

  // Types / Categories
  List<TypeItem> _types = [];
  List<TypeItem> get types => _types;
  bool _loadingTypes = false;
  bool get loadingTypes => _loadingTypes;

  // Selected Category (0 = Home/All, or specific type_id)
  int _selectedTypeId = 0;
  int get selectedTypeId => _selectedTypeId;
  String _selectedTypeName = "Beranda";
  String get selectedTypeName => _selectedTypeName;

  // Current Banners & Sections
  List<BannerItem> _banners = [];
  List<BannerItem> get banners => _banners;
  bool _loadingBanners = false;
  bool get loadingBanners => _loadingBanners;

  List<SectionItem> _sections = [];
  List<SectionItem> get sections => _sections;
  bool _loadingSections = false;
  bool get loadingSections => _loadingSections;

  // Search
  List<ContentItem> _searchResults = [];
  List<ContentItem> get searchResults => _searchResults;
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // In-Memory Tab Cache (Zero Shimmer on Tab Switching)
  final Map<int, TVTabCache> _cache = {};

  // Initialize Home Data
  Future<void> initHome() async {
    await fetchTypes();
    await selectTab(0, "Beranda");
  }

  // Reload content after switching between User and Kids profile
  Future<void> reloadForProfileChange() async {
    _cache.clear();
    await selectTab(0, "Beranda");
  }

  Future<void> fetchTypes() async {
    _loadingTypes = true;
    notifyListeners();

    final result = await _api.getTypes();
    if (result.status == 200 && result.result != null) {
      _types = result.result!;
    }
    _loadingTypes = false;
    notifyListeners();
  }

  Future<void> selectTab(int typeId, String typeName) async {
    _selectedTypeId = typeId;
    _selectedTypeName = typeName;

    // 1. Check if cache exists
    if (_cache.containsKey(typeId)) {
      final cached = _cache[typeId]!;
      _banners = cached.banners;
      _sections = cached.sections;
      _loadingBanners = false;
      _loadingSections = false;
      notifyListeners();

      // Background refresh silently if cache is older than 5 minutes
      if (DateTime.now().difference(cached.timestamp).inMinutes >= 5) {
        _loadTabData(typeId, isBackground: true);
      }
      return;
    }

    // 2. Fetch fresh data
    await _loadTabData(typeId, isBackground: false);
  }

  Future<void> _loadTabData(int typeId, {bool isBackground = false}) async {
    if (!isBackground) {
      _loadingBanners = true;
      _loadingSections = true;
      notifyListeners();
    }

    final isHomeScreen = (typeId == 0) ? 1 : 2;

    // Parallel fetch banners and sections
    final bannerFuture = _api.getBanners(isHomeScreen: isHomeScreen, typeId: typeId);
    final sectionFuture = _api.getSections(isHomeScreen: isHomeScreen, typeId: typeId);

    final results = await Future.wait([bannerFuture, sectionFuture]);
    final bannerRes = results[0] as BannerListModel;
    final sectionRes = results[1] as SectionListModel;

    _banners = bannerRes.result ?? [];
    _sections = (sectionRes.result ?? []).where((s) => s.data != null && s.data!.isNotEmpty).toList();

    // Cache the loaded data
    _cache[typeId] = TVTabCache(
      banners: _banners,
      sections: _sections,
      timestamp: DateTime.now(),
    );

    _loadingBanners = false;
    _loadingSections = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchResults = await _api.search(query: query.trim());
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
