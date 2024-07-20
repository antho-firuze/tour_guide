import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/main.dart';

extension PageUtilContext on BuildContext {
  Future goto({required Widget page}) async => await Navigator.of(this, rootNavigator: true).push(CupertinoPageRoute(
        builder: (context) => page,
      ));
}

class PageUtils {
  Ref ref;
  PageUtils(this.ref);

  Future goto({required Widget page}) async =>
      await Navigator.of(rootNavigatorKey.currentContext!, rootNavigator: true).push(CupertinoPageRoute(
        builder: (context) => page,
      ));
}

final pageUtilsProvider = Provider(PageUtils.new);
