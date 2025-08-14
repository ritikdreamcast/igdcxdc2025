import 'dart:async';
import 'dart:convert';
import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../utils/image_constant.dart';
import '../../../widgets/dialog/custom_animated_dialog_widget.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../quiz/model/sessionPollModel.dart';
import '../../schedule/model/sessionPollsStatus.dart';
import '../model.dart';
import '../model/pollsReponse.dart';

class PollController extends GetxController {
  final DashboardController dashboardController = Get.find();

  ScrollController tabScrollController = ScrollController();

  AuthenticationManager authManager = Get.find();
  var loading = false.obs;
  late DatabaseReference _messagesRef;

  DatabaseReference get messagesRef => _messagesRef;

  var questionList = <PollListModel>[].obs;
  late StreamSubscription<DatabaseEvent> _eventsSubscription;
  var isAnswerd = false.obs;
  var selectedOption = "".obs;
  var isSubmit = false.obs;
  var selectedTabIndex = (-1).obs;

  var message = "";
  var itemType = "";
  var itemId = "";

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      itemType = Get.arguments?['item_type'] ??
          ''; // Type of the item (e.g., "event" or "session")
      itemId = Get.arguments?["item_id"] ??
          ''; // ID of the item for which polls are being fetched
    }
    _messagesRef = authManager.firebaseDatabase
        .ref(AppUrl.defaultFirebaseNode)
        .child(MyConstant.slugPoll);

    getThePolls();
  }

  getThePolls() async {
    await initMessageRef();
    checkPollStatus();
  }

  /// This method initializes the Firebase reference and listens for changes in the poll data.
  initMessageRef() async {
    questionList.clear();
    if (itemType == "event") {
      _eventsSubscription = _messagesRef
          .orderByChild("item_type")
          .equalTo(itemType)
          .onChildAdded
          .listen((snapshot) {
        onEventsSnapshot(snapshot);
      }); // Listen for new events related to the item type
    } else {
      _eventsSubscription = _messagesRef
          .orderByChild("item_id")
          .equalTo(itemId)
          .onChildAdded
          .listen((snapshot) {
        onEventsSnapshot(snapshot);
      }); // Listen for new events related to the item ID
    }

    _eventsSubscription = _messagesRef.onChildChanged.listen((snapshot) {
      print(snapshot.snapshot.value);
      final json = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final message = PollListModel.fromJson(json);
      if (message.status == 1) {
        return; // If the poll is active, do not update the list
      }
      //this is used to update the status of list with match item.
      if (questionList.isNotEmpty) {
        if (itemType == "event") {
          questionList[questionList
              .indexWhere((element) => element.id == message.id)] = message;
          // Update the specific poll in the list
        } else if (itemId == message.itemId) {
          questionList[questionList
              .indexWhere((element) => element.id == message.id)] = message;
          // Update the specific poll in the list
        }
        if (getLivePoll().isNotEmpty) {
          getPollStatus(
              pollId: message.id, pollStatus: getLivePoll()[0].status);
          // Check the status of the updated poll
        }
      }
      isAnswerd(false);
      selectedOption("");
      isSubmit(false);
    });
  }

  /// This method is called when a new event is added to the Firebase database.
  void onEventsSnapshot(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final json = event.snapshot.value as Map<dynamic, dynamic>;
      final pollData = PollListModel.fromJson(json);
      if (pollData.itemType == itemType) {
        questionList.add(pollData);
      }
      selectedTabIndex.value = -1; // reset selected tab index
      questionList.refresh();
    } else {
      print("@@@ data is load");
    }
  }

  //0=> Pending, 1=>Active, 2 => Result Declared, 3=> Completed
  // Filter the list to include only active or result declared polls
  List<PollListModel> getLivePoll() {
    List<PollListModel> outputList = questionList
        .where((parentRoomModel) =>
            parentRoomModel.status == 1 || parentRoomModel.status == 2)
        .toList();
    return outputList ?? [];
  }

  ///check the current status of poll
  checkPollStatus() {
    loading(true);
    Future.delayed(const Duration(seconds: 1), () {
      if (getLivePoll().isNotEmpty) {
        var questionId = getLivePoll()[0].id;
        getPollStatus(pollId: questionId, pollStatus: getLivePoll()[0].status);
      } else {
        loading(false);
        getPollStatus(pollId: "", pollStatus: 0);
      }
    });
  }

  //0=> Pending, 1=>Active, 2 => Result Declared, 3=> Completed
  ///model.body?.userStatus ==1 means the used has been submited the polls
  ///==0 means not submited the poll yet
  Future<void> getPollStatus({required pollId, required pollStatus}) async {
    var requestBody = {"id": pollId, "item_id": itemId, "item_type": itemType};
    loading(true);

    try {
      final model = SessionPollStatus.fromJson(json.decode(
        await apiService.dynamicPostRequest(
          body: requestBody,
          url: AppUrl.isPollSubmitted,
        ),
      ));
      loading(false);
      if (model.status! && model!.code == 200) {
        // If the poll is active
        if (model.body?.userStatus == 1) {
          update();
          message =
              model.body?.message ?? "Poll closed. Thank you for your interest";
          isSubmit(true);
          // Check if the poll is completed or result declared
          if (pollStatus == 2) {
            isSubmit(false);
          }
        } else if (model.body?.userStatus == 0) {
          // If the poll is not completed
          if (pollStatus != 3) {
            isSubmit(false);
          } else {
            isSubmit(true);
          }
          message = model.body?.message ?? "something went wrong";
          update();
        } else {
          isSubmit(false);
          message = model.body?.message ?? "something went wrong";
          update();
        }
      } else {
        message = model.message ?? "";
        isSubmit(true);
      }
    } catch (e, stack) {
      print("Error in API: $e\n$stack");
    } finally {
      loading(false);
    }
  }

  /// This method is used to submit the poll response.
  Future<Map> submitPollResponse({required requestBody}) async {
    var result = {};
    loading(true);
    final model = PollsSubmitModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: requestBody,
        url: AppUrl.savePolls,
      ),
    ));

    loading(false);
    if (model!.status! && model!.code == 200) {
      selectedOption(getLivePoll()[0].options![selectedTabIndex.value]);
      isSubmit(true);
      message = model.body?.message ?? "";
      update();
      await Get.dialog(
          barrierDismissible: false,
          CustomAnimatedDialogWidget(
            title: "success_action".tr,
            logo: ImageConstant.icSuccessAnimated,
            description: model.body?.message ?? model.message ?? "",
            buttonAction: "okay".tr,
            buttonCancel: "cancel".tr,
            isHideCancelBtn: true,
            onCancelTap: () {},
            onActionTap: () async {
              //Get.back();
            },
          ));
    } else {
      UiHelper.showFailureMsg(null, model?.message ?? "");
    }
    return result;
  }

  @override
  void dispose() {
    _messagesRef.onDisconnect(); // Disconnect from the Firebase reference
    _eventsSubscription
        .cancel(); // Cancel the subscription to the Firebase events
    Get.delete<PollController>();
    super.dispose();
  }

  @override
  void onClose() {
    _messagesRef.onDisconnect();
    _eventsSubscription.cancel();
    super.onClose();
  }
}
