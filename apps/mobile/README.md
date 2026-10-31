# Mobile app

Ứng dụng Flutter dành cho khách hàng. Khởi tạo app tại thư mục này bằng:

```bash
flutter create --org com.plantflowershop --project-name plant_flower_mobile .
```

Sau khi khởi tạo, đưa app vào pub workspace:

1. Trong `apps/mobile/pubspec.yaml`: đặt `environment.sdk: ^3.9.0`, thêm
   `resolution: workspace` và các dependency nội bộ:
   ```yaml
   resolution: workspace
   dependencies:
     plant_flower_shared: ^0.1.0
     plant_flower_api_client: ^0.1.0
     plant_flower_ui: ^0.1.0
   ```
2. Thêm `apps/mobile` vào mục `workspace:` trong `pubspec.yaml` ở root.
3. Xoá `apps/mobile/pubspec.lock` (workspace dùng chung lock ở root), rồi chạy
   `melos bootstrap`.

## Tích hợp chatbot trên mọi màn hình khách hàng

Khởi tạo một `ChatbotRepository` dùng chung và bọc Navigator một lần trong
`MaterialApp.builder`. Không tạo repository mới bên trong `builder`, vì mỗi lần
rebuild sẽ làm mất controller và phiên chat đang mở.

```dart
MaterialApp(
  builder: (context, child) => ChatbotOverlayHost(
    repository: chatbotRepository,
    visible: session.isAuthenticated && session.isCustomer,
    contextProvider: () => ChatbotRequestContext(
      screen: currentScreenName,
      productId: currentProductId,
      orderId: currentOrderId,
      paymentId: currentPaymentId,
    ),
    onProductTap: (productId) {
      productRouter.openDetail(productId);
    },
    onOpenIncidentReport: (draft) {
      incidentRouter.openPrefilled(draft);
    },
    child: child!,
  ),
  home: const HomeScreen(),
);
```

Adapter HTTP của ứng dụng triển khai `ChatbotApiTransport` và cung cấp access
token hiện tại cho `ChatbotRemoteDataSource`. API key Gemini chỉ được cấu hình ở
backend; mobile không lưu hoặc gửi key của nhà cung cấp AI.
