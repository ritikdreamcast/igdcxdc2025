import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/view/breifcase/controller/common_document_controller.dart';
import 'package:dreamcast/view/exhibitors/controller/exhibitorsController.dart';
import 'package:dreamcast/view/representatives/controller/networkingController.dart';
import 'package:dreamcast/view/schedule/controller/session_controller.dart';
import 'package:dreamcast/view/speakers/controller/speakerNetworkController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../api_repository/api_service.dart';
import '../../../../api_repository/app_url.dart';
import '../../../theme/ui_helper.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../exhibitors/model/exibitorsModel.dart';
import '../../representatives/model/user_model.dart';
import '../../representatives/request/network_request_model.dart';
import '../../schedule/model/scheduleModel.dart';
import '../../schedule/request_model/session_request_model.dart';
import '../../speakers/model/speakersModel.dart';

class GlobalSearchController extends GetxController {
  final AuthenticationManager _authManager = Get.find();
  AuthenticationManager get authManager => _authManager;
  var selectedSearchTag = "Exhibitors".obs;
  var selectedSearchIndex = 0.obs;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final textController = TextEditingController().obs;

  /// Called when the controller is initialized.
  ///
  /// Initializes the controller and triggers the initial search based on the selected tab.
  @override
  void onInit() {
    super.onInit();
    //tabIndexAndSearch(false);
  }

  /// Handles tab index changes and performs search based on the selected search tag.
  ///
  /// Updates the search index and triggers the appropriate controller's search method.
  tabIndexAndSearch(bool isRefresh) {
    switch (selectedSearchTag.value) {
      case "Exhibitors":
        BoothController controller = Get.find();
        controller.bootRequestModel.filters?.text =
            textController.value.text.trim() ?? "";
        controller.bootRequestModel.favourite = 0;
        controller.bootRequestModel.filters?.notes = false;
        controller.bootRequestModel.page = 1;
        controller.bootRequestModel.filters?.sort = "";
        controller.bootRequestModel.filters?.params = {};
        controller.getExhibitorsList(isRefresh: isRefresh);
        selectedSearchIndex(0);
        break;
      case "Networking":
        selectedSearchIndex(3);
        NetworkingController controller = Get.find();
        controller.networkRequestModel.filters?.text =
            textController.value.text.trim() ?? "";
        controller.networkRequestModel.favorite = 0;
        controller.networkRequestModel.filters?.isBlocked = false;
        controller.networkRequestModel.filters?.notes = false;
        controller.networkRequestModel.filters?.sort = "";
        controller.networkRequestModel.filters?.params = {};
        controller.getAttendeeList(isRefresh: isRefresh);
        selectedSearchIndex(1);
        break;
      case "Sessions":
        selectedSearchIndex(2);
        SessionController controller = Get.find();
        controller.sessionRequestModel.filters?.text =
            textController.value.text.trim() ?? "";
        controller.sessionRequestModel.filters?.params =
            RequestParams(date: "");
        controller.getSessionList(isRefresh: isRefresh);

        break;
      case "Speakers":
        selectedSearchIndex(3);
        SpeakerNetworkController controller = Get.find();
        controller.networkRequestModel.filters?.text =
            textController.value.text.trim() ?? "";
        controller.networkRequestModel.favorite = 0;
        controller.networkRequestModel.filters?.isBlocked = false;
        controller.networkRequestModel.filters?.notes = false;
        controller.networkRequestModel.filters?.sort = "";
        controller.networkRequestModel.filters?.params = {};
        controller.getUserListApi(isRefresh: isRefresh);
        break;
    }
  }
}
