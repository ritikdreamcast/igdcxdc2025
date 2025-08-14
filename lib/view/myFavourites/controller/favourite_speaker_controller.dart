import 'dart:convert';

import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import 'package:dreamcast/view/myFavourites/model/bookmark_speaker_model.dart';
import 'package:dreamcast/view/speakers/controller/speakersController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../routes/my_constant.dart';
import '../../representatives/request/network_request_model.dart';
import '../../representatives/model/user_model.dart';
import '../../speakers/model/speakersModel.dart';

class FavSpeakerController extends GetxController {
  var favouriteSpeakerList = <SpeakersData>[].obs;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  NetworkRequestModel networkRequestModel = NetworkRequestModel();
  var loading = false.obs;
  var isFirstLoading = false.obs;

  FavouriteController favouriteController = Get.find();
  SpeakersDetailController userController = Get.put(SpeakersDetailController());

  /// Called when the controller is initialized.
  ///
  /// Triggers the initial API data fetch for favourite speakers.
  @override
  void onInit() {
    super.onInit();
    getApiData();
  }

  /// Prepares the network request model and fetches the list of bookmarked speakers.
  getApiData() async {
    ///its a initial request for the get the data
    networkRequestModel = NetworkRequestModel(
        role: MyConstant.speakers,
        page: 1,
        favorite: 1,
        filters: RequestFilters(
            text: favouriteController.textController.value.text.trim(),
            isBlocked: false,
            sort: "ASC",
            notes: false,
            params: {}));
    getBookmarkUser(isRefresh: false);
  }

  /// Fetches the list of bookmarked speakers from the API and updates the observable list.
  Future<void> getBookmarkUser({required bool isRefresh}) async {
    userController.isBookmarkLoading(true);
    isFirstLoading(!isRefresh);

    final model = SpeakersModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: networkRequestModel,
        url: "${AppUrl.usersListApi}/search",
      ),
    ));
    userController.isBookmarkLoading(false);
    if (model.status! && model.code == 200) {
      /// If the API call is successful, clear the existing list and update it with the new data
      favouriteSpeakerList.clear();
      favouriteSpeakerList.value = model.body!.representatives ?? [];
      userController.bookMarkIdsList.clear();
      userController.bookMarkIdsList
          .addAll(favouriteSpeakerList.map((obj) => obj.id).toList());
    } else {
      print(model.code.toString());
    }
    isFirstLoading(false);
  }
}
