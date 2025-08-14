import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dreamcast/view/breifcase/controller/common_document_controller.dart';
import 'package:dreamcast/view/dashboard/dashboard_controller.dart';
import 'package:dreamcast/view/menu/controller/menuController.dart';
import 'package:get/get.dart';
import '../beforeLogin/globalController/authentication_manager.dart';
import '../menu/model/menu_data_model.dart';
import 'package:flutter/widgets.dart';

/// Controller for handling deep linking in the app using GetX.

class DeepLinkingController extends GetxController {
  final AuthenticationManager _authManager = Get.find();
  final DashboardController dashboardController = Get.find();

  var loading = false.obs;

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _lastHandledUri;
  bool _isListening = false;
  DateTime? _lastNavigationTime;
  bool _isNavigating = false;

  bool _shouldIgnoreUri(Uri uri) {
    if (_lastHandledUri?.toString() == uri.toString()) return true;
    if (_isNavigating) return true;
    final now = DateTime.now();
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inMilliseconds < 1500) {
      return true;
    }
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    print("DeepLinkingController initialized");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppLinks();
    });
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isListening = false;
    super.onClose();
  }

  Future<void> _initAppLinks() async {
    if (_isListening) return;
    _isListening = true;

    _appLinks ??= AppLinks();

    // Handle cold start
    try {
      final uri = await _appLinks?.getLatestLink();
      if (uri != null && uri.toString().isNotEmpty) {
        getTheParameter(uri);
      }
    } catch (e) {
      print('Failed to get initial URI: $e');
    }

    // Foreground deep link listener
    _linkSubscription = _appLinks?.uriLinkStream.listen(
      (uri) {
        if (uri == null || uri.toString().isEmpty) return;
        dashboardController.loading(true);
        Future.delayed(const Duration(seconds: 1), () {
          dashboardController.loading(false);
          getTheParameter(uri);
        });
      },
      onError: (err) => print('Deep link error: $err'),
    );
  }

  void getTheParameter(Uri uri) {
    print("Deep link _shouldIgnoreUri: ${_shouldIgnoreUri(uri)}");
    if (_shouldIgnoreUri(uri)) return;

    _isNavigating = true;
    _lastHandledUri = uri;
    _lastNavigationTime = DateTime.now();

    _authManager.clearPageRoute();

    final queryParams = uri.queryParameters;
    _authManager.pageRouteName = queryParams['page'] ?? "";
    _authManager.pageRouteId = queryParams['id'] ?? "";
    _authManager.type = queryParams['type'] ?? "";
    _authManager.role = queryParams['role'] ?? "";

    if (_authManager.pageRouteName.isNotEmpty ||
        _authManager.pageRouteId.isNotEmpty) {
      navigatePageAsPerNotification().then((_) {
        _isNavigating = false;
      });
    } else {
      _isNavigating = false;
    }
  }

  Future<void> navigatePageAsPerNotification() async {
    if (_authManager.pageRouteName == "null" ||
        _authManager.pageRouteName.isEmpty) {
      return;
    }

    if (!Get.isRegistered<HubController>()) {
      Get.lazyPut<HubController>(() => HubController());
    }
    if (!Get.isRegistered<CommonDocumentController>()) {
      Get.lazyPut<CommonDocumentController>(() => CommonDocumentController());
    }

    final HubController hubController = Get.find();
    hubController.commonMenuRouting(
      menuData: MenuData(
        pageId: _authManager.pageRouteId,
        icon: "",
        role: _authManager.role,
        slug: _authManager.pageRouteName,
        type: _authManager.type,
      ),
    );
  }
}
