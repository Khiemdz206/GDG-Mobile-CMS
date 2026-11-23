import 'package:flutter_test/flutter_test.dart';
import 'package:gdgocms/core/router/app_router.dart';

void main() {
  test('mở app ở đúng route được truyền vào', () {
    final router = AppRouter.createRouter(initialLocation: AppRoutes.login);
    addTearDown(router.dispose);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });

  test('mỗi route có đường dẫn riêng', () {
    const paths = [
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.home,
      AppRoutes.events,
      AppRoutes.eventDetail,
    ];
    expect(paths.toSet(), hasLength(paths.length));
  });
}
