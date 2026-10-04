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
