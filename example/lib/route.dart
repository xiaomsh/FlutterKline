import 'package:get/get.dart';

import 'page/live/live_controller.dart';
import 'page/live/live_page.dart';
import 'page/setting/setting_page.dart';
import 'page/stock/stock_controller.dart';
import 'page/stock/stock_page.dart';

final List<GetPage> pages = [
  GetPage(
    name: '/setting',
    page: () => const SettingPage(),
    transition: Transition.noTransition,
  ),
  GetPage(
    name: '/setting/:entry',
    page: () => SettingPage(entryId: Get.parameters['entry']),
    transition: Transition.noTransition,
  ),
  GetPage(
    name: "/live",
    page: () => LivePage(),
    binding: BindingsBuilder.put(() => LiveController()),
  ),
  GetPage(
    name: '/stock',
    page: () => StockPage(),
    binding: BindingsBuilder.put(() => StockController()),
  ),
];
