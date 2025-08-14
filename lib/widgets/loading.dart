import 'package:dreamcast/core/extension/content_extension.dart';
import 'package:dreamcast/network/controller/internet_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Loading extends GetView<InternetController> {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
      // color: Colors.transparent,
      child: Center(
        child: normalLoading(),
      ),
    );
  }

  Widget normalLoading() {
    return CupertinoActivityIndicator(/*color: Colors.black, */ radius: 20.0);
  }

  Widget animatedLoading() {
    return Lottie.asset('assets/animated/loading.json', height: 200);
  }
}

class FavLoading extends StatelessWidget {
  const FavLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(height: 20, width: 15, color: Colors.red),
    );
  }
}
