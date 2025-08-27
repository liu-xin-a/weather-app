
# HarmonyOS Weather App (鸿蒙天气App)

![语言](https://img.shields.io/badge/Language-ArkTS-blue.svg)
![平台](https://img.shields.io/badge/Platform-HarmonyOS-green.svg)

这是一款基于 HarmonyOS 和 ArkTS 语言开发的现代化、功能完备的天气应用。本项目旨在完整地、端到端地展示一个ArkTS应用的开发全过程，从UI构建、网络请求到高级功能（如服务卡片、持久化存储）的实现。

## ✨ 应用截图 (App Screenshot)
<img width="630" height="1360" alt="Screenshot_2025-08-27T103032" src="https://github.com/user-attachments/assets/517629f0-0303-44d7-814b-6c8302b5797e" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103056" src="https://github.com/user-attachments/assets/ac7619f9-022d-46fd-bfec-f2f52de7c4ae" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103105" src="https://github.com/user-attachments/assets/9ac066b1-74b5-4e4d-81a5-4ad5cee9a19a" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103110" src="https://github.com/user-attachments/assets/b5f91ad8-de97-4e1b-9470-8c13f615bfd0" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103151" src="https://github.com/user-attachments/assets/a693e354-32b3-493d-a8d7-337746a4296d" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103214" src="https://github.com/user-attachments/assets/f40d0ba2-559f-45e1-883e-63ac6fe6019e" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103232" src="https://github.com/user-attachments/assets/0076ba76-e618-42ae-892b-d0b4521f21fe" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103258" src="https://github.com/user-attachments/assets/854da334-86c7-4c44-b133-639dea1c9a83" />
<img width="630" height="1360" alt="Screenshot_2025-08-27T103315" src="https://github.com/user-attachments/assets/243b3276-c49d-4198-bc38-fb7dd6c34eee" />


## 🚀 主要功能 (Features)

- **实时天气查询**: 显示当前城市的实时温度、天气状况、体感温度、湿度、风力风向等详细信息。
- **多日天气预报**: 提供未来3天的天气预报，包括最高/最低温度和天气状况。
- **逐小时天气预报**: 以横向滚动列表的形式，展示未来24小时内的天气和温度变化。
- **空气质量与生活指数**: 展示AQI、PM2.5等空气质量数据，以及穿衣、洗车、运动等生活建议。
- **动态天气背景**: 应用背景色可根据实时天气状况（晴、阴、雨、夜）平滑地进行渐变色切换。
- **城市搜索与切换**: 支持中英文模糊搜索城市，并切换查看目标城市的天气。
- **GPS自动定位**: 可通过用户授权，自动获取当前位置并显示当地天气。
- **下拉刷新**: 支持标准的手动下拉刷新交互。
- **数据持久化**: 应用能“记住”用户上次选择的城市，下次启动时自动加载。
- **离线缓存**: 在无网络连接时，能够展示上一次成功获取的天气数据，并提供离线提示。
- **桌面服务卡片 (Widget)**: 提供2x2尺寸的桌面小组件，无需打开App即可快速浏览天气概览，并支持定时刷新。
- **完善的权限处理**: 包含对定位权限的申请、用户拒绝后的友好引导（跳转至系统设置）。

## 🛠️ 技术栈 (Technology Stack)

- **开发语言**: **ArkTS**
- **UI框架**: **ArkUI (声明式UI)**
- **核心架构**:
    - **组件化**: 将UI拆分为多个独立的、可复用的自定义组件。
    - **MVVM (思想)**: 通过 `ViewModel` (或 `Controller`) 将业务逻辑与UI视图分离。
    - **状态管理**: `@State`, `@Link`, `@Prop`, `@Watch`, `@Provide`/`@Consume`, `@Observed`, 全局 `AppStorage`。
- **核心能力**:
    - **网络请求**: `@kit.NetworkKit`
    - **数据持久化**: `@ohos.data.preferences`
    - **定位服务**: `@kit.LocationKit`
    - **权限管理**: `@kit.AbilityKit` (abilityAccessCtrl)
    - **页面导航**: `Navigation` (声明式导航)
    - **服务卡片**: `FormExtensionAbility`
    - **动画与交互**: `animateTo`, `transition`, `@ohos.vibrator`
- **数据源**: **和风天气 (QWeather)**

## 📦 如何运行 (Getting Started)

1.  **克隆项目**:
    ```bash
    git clone https://github.com/liu-xin-a/weather-app.git
    ```
2.  **打开项目**:
    使用最新版本的 **DevEco Studio** 打开项目。
3.  **配置API Key**:
    打开 `entry/src/main/ets/common/Constants.ets` 文件，将 `QWEATHER_API_KEY` 的值替换为您自己从和风天气开发者平台申请的 Key。
4.  **运行**:
    连接真机或模拟器，点击运行按钮。

## 📂 项目结构 (Project Structure)

```
/entry/src/main/ets
├── common          # 存放常量 (Constants.ets)
├── controller      # (可选) ViewModel/Controller 层
├── entryability    # 应用主入口 (EntryAbility.ets)
├── model           # 数据模型 (WeatherModels.ets)
├── pages           # 页面UI (Index.ets, CitySearchPage.ets)
├── utils           # 工具类 (PreferencesUtil, CacheUtil, etc.)
├── view            # 可复用的自定义UI组件
└── weatherwidgetability # 服务卡片逻辑与UI
```

## 🙏 致谢 (Acknowledgments)

* 感谢 **和风天气 (QWeather)** 提供的免费、稳定、强大的天气数据API。
* 感谢所有为鸿蒙生态做出贡献的开发者和布道者。
