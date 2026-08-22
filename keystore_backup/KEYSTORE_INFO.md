# Genius Wallet - Android Release Keystore & Build Documentation

本文档记录了 Genius Wallet 项目的 Android 正式发布签名证书（Keystore）信息、凭证及 Release APK 打包指南。

> [!CAUTION]
> **重要安全提示**：
> 1. 请妥善保管此目录下的 `geniuswallet-release.jks` 文件与密钥信息。
> 2. Android 应用一旦上线发布，后续所有升级版本的 APK 都**必须**使用完全相同的 Keystore 进行签名，否则用户手机将无法直接覆盖更新安装。
> 3. 建议将此备份文件夹另行存放在安全的密码管理器或离线存储设备中。

---

## 1. 签名证书基本信息 (Keystore Info)

| 属性项 | 配置值 |
| :--- | :--- |
| **Keystore 文件名** | `geniuswallet-release.jks` |
| **Keystore 格式** | PKCS12 (2048-bit RSA) |
| **Key Alias (别名)** | `geniuswallet` |
| **Keystore 密码** | `GeniusWallet2026!SecureKey` |
| **Key 密码** | `GeniusWallet2026!SecureKey` |
| **证书有效期** | 10,000 天（至 2054 年 1 月） |
| **Distinguished Name (DName)** | `CN=Genius Wallet, OU=Mobile, O=GeniusWallet, L=Global, ST=Decentralized, C=US` |

### 证书指纹 (Fingerprints)
- **SHA-1**: `E5:E7:17:75:1D:6B:3D:09:F1:5D:69:D4:16:3F:58:80:8A:5D:59:F2`
- **SHA-256**: `45:3B:DA:6D:FF:16:AE:18:DD:A2:AA:36:B7:DD:C3:EF:DD:C0:17:28:E3:04:88:76:31:18:76:BD:5D:A8:02:DC`

---

## 2. 项目配置位置 (Project Locations)

- **正式签名密钥文件**：`android/app/geniuswallet-release.jks`
- **签名配置文件**：`android/key.properties`
- **Gradle 签名配置**：`android/app/build.gradle.kts`
- **备份归档目录**：`keystore_backup/`

---

## 3. Release APK 打包命令 (Build Commands)

### 编译单架构或通用 Release APK
在项目根目录运行：
```bash
flutter build apk --release
```
生成的 APK 路径：
```
build/app/outputs/flutter-apk/app-release.apk
```

### 编译分架构（体积更小）Release APK
```bash
flutter build apk --release --split-per-abi
```
生成的 APK 路径：
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### 验证 APK 签名
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. 手机安装方法 (Installation)

1. **直接传输**：将 `app-release.apk` 发送到 Android 手机（微信文件传输、数据线、邮件等），点击直接安装。
2. **ADB 命令行安装**：
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
