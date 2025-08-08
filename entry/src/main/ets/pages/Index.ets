import { promptAction, UIContext } from '@kit.ArkUI'
import {
  QWEATHER_24H_URL,
  QWEATHER_3D_URL, QWEATHER_7D_URL,
  QWEATHER_AIR_NOW_URL,
  QWEATHER_API_KEY,
  QWEATHER_CITY_LOOKUP_URL,
  QWEATHER_INDICES_1D_URL,
  QWEATHER_NOW_URL } from '../common/Constants';
import {
  AirQualityApiResponse,
  AirQualityNow,
  CityLookupApiResponse,
  CurrentCityInfo,
  DailyForecast,
  ForecastApiResponse,
  HourlyApiResponse,
  HourlyForecast,
  IndicesApiResponse,
  initialNowWeatherData,
  LivingIndex,
  NowWeatherData, WeatherApiResponse } from '../model/WeatherModels';
import { http } from '@kit.NetworkKit';
import { formatForecastDate, formatTime, ICON_MAP } from '../utils/WeatherIconMapper';
import { geoLocationManager } from '@kit.LocationKit';
import {
  ability, abilityAccessCtrl, common, PermissionRequestResult, Permissions, Want} from '@kit.AbilityKit';
import { PermissionDialog } from '../view/PermissionDialog';
import { loadCityFromPreferences, saveCityToPreferences } from '../utils/PreferencesUtil';
import { getWeatherGradientColors } from '../utils/StyleProvider';
import { loadWeatherCache, saveWeatherCache } from '../utils/CacheUtil';
import { TopHeaderView } from '../view/TopHeaderView';
import { HourlyForecastView } from '../view/HourlyForecastView';
import { DailyForecastView } from '../view/DailyForecastView';
import { AirQualityCard } from '../view/AirQualityCard';
import { LivingIndicesCard } from '../view/LivingIndicesCard';


@Entry
@Component
struct Index {

  @State nowWeather:NowWeatherData = initialNowWeatherData;
  @State forecastDays: DailyForecast[] = []; // 新增：用于存储未来几天预报的数组
  @State hourlyForecasts: HourlyForecast[] = []; // 新增：存储逐小时预报数据
  @State updateTime: string = ''; // <-- 新增：用于存储格式化后的更新时间
  @State isRefreshing: boolean = false; // <-- 新增：控制刷新动画的显示状态
  @State backgroundColors: [string, number][] = getWeatherGradientColors('100');
  @State cacheInfoMessage: string = ''; // 用于显示离线模式“数据更新于X分钟前”
  @State airQuality: AirQualityNow | null = null; // 新增：存储空气质量数据
  @State livingIndices: LivingIndex[] = [];      // 新增：存储生活指数数据
  @StorageLink('currentcity')
  @Watch('onCityChange')
  currentCity: CurrentCityInfo = { id: '101010100', name: '北京' };
  pageStack: NavPathStack = new NavPathStack();
  private permissionDialogController: CustomDialogController = new CustomDialogController({
    // 使用我们自定义的 PermissionDialog 作为弹窗的UI
    builder: PermissionDialog({
      // 当弹窗内的“取消”按钮被点击时，执行这里的逻辑
      onCancel: () => {
        console.info("用户在自定义弹窗中点击了'取消'");
      },
      // 当弹窗内的“去设置”按钮被点击时，执行这里的逻辑
      onConfirm: () => {
        // 调用我们已经写好的跳转函数
        this.openAppSettings();
      }
    }),
    autoCancel: true, // 点击弹窗外部区域可关闭
    alignment: DialogAlignment.Center, // 居中显示
    customStyle: true // 关键！设为 true 才能让我们自己的样式生效
  });

  async aboutToAppear(): Promise<void> {
    // 1. 在加载UI之前，先尝试从闪存加载城市数据
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const savedCity = await loadCityFromPreferences(context);

    // 2. 如果成功加载，就用它覆盖 AppStorage 中的默认值
    if(savedCity) {
      // 这里的键名 'currentcity' 必须和您主页中 @StorageLink('currentcity') 的完全一致！
      AppStorage.set<CurrentCityInfo>('currentcity',savedCity);
      console.info("成功设置了城市信息:", JSON.stringify(savedCity));
    }
    // 在组件中获取 UIContext
    let uiContext: UIContext = this.getUIContext();
    // 注册字体
    uiContext.getFont().registerFont({
      familyName: 'myfont',
      familySrc: '/fonts/iconfont.ttf'
    });
    this.getweather();
    this.get3dForecast();
    this.get24hForecast();
    this.getAirQuality();
    this.getLivingIndices();
  }
  async getweather(){
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    //this.currentCity = AppStorage.get<CurrentCityInfo>('currentcity')!
    // 创建 http request 实例
    let httpRequest = http.createHttp()
    // 拼接请求的 URL，location=101010100 是北京的城市ID，你可以换成其他的
    const url = `${QWEATHER_NOW_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
      });

      // 判断网络请求是否成功 (HTTP状态码 200)
      if (response.responseCode === 200) {
        // 将返回的字符串结果解析成 JSON 对象
        const result = JSON.parse(response.result as string) as WeatherApiResponse;

        // 判断和风天气API返回的业务状态码是否成功 ("200")
        if (result.code === '200') {
          // 成功！将获取到的 now 对象，更新到 @State 变量上
          // UI 会自动刷新！
          this.nowWeather = result.now;
          this.backgroundColors = getWeatherGradientColors(this.nowWeather.icon);
          console.info('Weather data updated successfully.');
          this.updateTime = formatTime(new Date());
          this.cacheInfoMessage = ''; // 清空离线提示
          // 将成功获取的数据存入缓存
          await saveWeatherCache(context, 'now_weather', result.now);
          return; // 成功后直接退出函数
        } else {
          // API 返回了错误信息，例如key不正确
          console.error(`Weather API Error: ${result.code}`);

        }
      } else {
        // 网络请求本身失败
        console.error(`Http request failed, code: ${response.responseCode}`);
      }
    } catch (err) {
      console.error("获取实时天气失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<NowWeatherData>(context, 'now_weather');
      if (cachedData) {
        this.nowWeather = cachedData.data;
        // 计算缓存时间并显示提示
        const minutesAgo = Math.round((Date.now() - cachedData.timestamp) / 60000);
        this.cacheInfoMessage = `离线模式：数据更新于${minutesAgo}分钟前`;
      }
    } finally {
      // 无论成功失败，最后都销毁请求实例，释放资源
      httpRequest.destroy();
    }
  }
  async get3dForecast() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 这个函数结构和 getweather 几乎一模一样
    let httpRequest = http.createHttp();
    // 注意！URL现在是 QWEATHER_3D_URL
    const url = `${QWEATHER_3D_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;

    try {
      const response = await httpRequest.request(url); // Method 默认是 GET
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ForecastApiResponse;
        if (result.code === '200') {
          console.info('3-day forecast updated successfully.');
          // 当数据获取成功，更新存储预报数据的 State 变量
          this.forecastDays = result.daily;
          // 将成功获取的数据存入缓存
          await saveWeatherCache(context, '3d_forecast', result.daily);
          return; // 成功后直接退出
        } else {
          console.error(`Forecast API Error: ${result.code}`);
        }
      } else {
        console.error(`Forecast http request failed, code: ${response.responseCode}`);
      }
    } catch (err) {
      // --- 网络失败，启动备用方案 ---
      console.error("获取3日预报失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<DailyForecast[]>(context, '3d_forecast');
      if (cachedData) {
        this.forecastDays = cachedData.data;
      }
    } finally {
      httpRequest.destroy();
    }
  }
  async get24hForecast() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const url = `${QWEATHER_24H_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;
    let httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as HourlyApiResponse;
        if (result.code === '200') {
          // --- 网络成功 ---
          this.hourlyForecasts = result.hourly;
          // 将成功获取的数据存入缓存
          await saveWeatherCache(context, '24h_forecast', result.hourly);
          return; // 成功后直接退出
        }
      }
      throw new Error(`API or HTTP Error for 24h forecast`);

    } catch (err) {
      // --- 网络失败，启动备用方案 ---
      console.error("获取逐小时预报失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<HourlyForecast[]>(context, '24h_forecast');
      if (cachedData) {
        this.hourlyForecasts = cachedData.data;
      }
    } finally {
      httpRequest.destroy();
    }
  }
  async getAirQuality() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_AIR_NOW_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;

    // 为了让缓存键名与城市关联，我们把城市ID也加进去
    const cacheKey = `air_quality_${this.currentCity.id}`;

    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as AirQualityApiResponse;
        if (result.code === '200' && result.now) {
          // --- 网络成功 ---
          console.info("[AQI] 成功从网络获取空气质量数据。");
          this.airQuality = result.now;
          // 将成功获取的数据存入缓存
          await saveWeatherCache(context, cacheKey, result.now);
          return; // 成功后直接退出
        }
      }
      // 如果 responseCode 不是 200 或 result.code 不是 '200'，就抛出错误进入catch流程
      throw new Error(`API or HTTP Error for Air Quality`);

    } catch (err) {
      // --- 网络失败，启动备用方案 ---
      console.error("获取空气质量失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<AirQualityNow>(context, cacheKey);
      if (cachedData) {
        this.airQuality = cachedData.data;
        console.info("[AQI] 成功从缓存加载空气质量数据。");
      }
    } finally {
      httpRequest.destroy();
    }
  }
  async getLivingIndices() {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_INDICES_1D_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}&type=0`;

    const cacheKey = `living_indices_${this.currentCity.id}`;

    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as IndicesApiResponse;
        if (result.code === '200' && result.daily) {
          // --- 网络成功 ---
          console.info("[Indices] 成功从网络获取生活指数数据。");
          this.livingIndices = result.daily;
          // 将成功获取的数据存入缓存
          await saveWeatherCache(context, cacheKey, result.daily);
          return; // 成功后直接退出
        }
      }
      throw new Error(`API or HTTP Error for Living Indices`);

    } catch (err) {
      // --- 网络失败，启动备用方案 ---
      console.error("获取生活指数失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<LivingIndex[]>(context, cacheKey);
      if (cachedData) {
        this.livingIndices = cachedData.data;
        console.info("[Indices] 成功从缓存加载生活指数数据。");
      }
    } finally {
      httpRequest.destroy();
    }
  }
  async handleRefresh() {
    // 1. 开始刷新，显示加载动画
    this.isRefreshing = true;

    // 2. 使用 Promise.all 并发执行两个网络请求，提高效率
    //    这会同时开始获取实时天气和3日预报
    await Promise.all([
      this.getweather(),
      this.get3dForecast(),
      this.get24hForecast(),
      this.getAirQuality(),
      this.getLivingIndices()
    ]);
    // 3.等待两秒之后 ，结束刷新，隐藏加载动画
    setTimeout(() => {
      this.isRefreshing = false
    }, 2000)
  }
  async getLocation() {
    try {
      const permissions: Array<Permissions> = [
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION'
      ];
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let atManager = abilityAccessCtrl.createAtManager();

      // 2. 关键修复：直接使用导入的 PermissionRequestResult 类型
      const permissionResult = await (atManager.requestPermissionsFromUser(context, permissions) as Promise<PermissionRequestResult>);

      // 3. 后续的所有逻辑保持不变，它们现在可以正确工作了
      const locationPermissionIndex = permissions.indexOf('ohos.permission.APPROXIMATELY_LOCATION');
      if (permissionResult.authResults[locationPermissionIndex] === 0) {
        // --- 权限被授予 ---
        console.log("定位权限已被授予。");
        promptAction.showToast({ message: "正在获取当前位置..." });

        let isLocationEnabled = await geoLocationManager.isLocationEnabled();
        if (!isLocationEnabled) {
          promptAction.showToast({ message: "请在系统中开启定位服务" });
          return;
        }

        let location = await geoLocationManager.getCurrentLocation();
        console.log('经度：' + location.longitude);
        console.log('纬度：' + location.latitude);
        await this.getCityInfoByCoords(location.longitude, location.latitude);

      } else {
        // --- 权限被拒绝 ---
        console.warn("定位权限被用户拒绝。");
        promptAction.showToast({ message: "您拒绝了定位授权，无法获取位置" });
        this.permissionDialogController.open();

      }

    } catch (error) {
      console.error('定位过程中发生异常：' + JSON.stringify(error));
      promptAction.showToast({ message: "定位失败，请稍后重试" });
    }
  }
  async getCityInfoByCoords(longitude: number, latitude: number) {
    // 和风API要求经纬度格式是：经度,纬度，且小数点后保留两位
    const locationStr = `${longitude.toFixed(2)},${latitude.toFixed(2)}`;

    let httpRequest = http.createHttp();
    // 使用的还是城市查询API，只是 location 参数的格式变了
    const url = `${QWEATHER_CITY_LOOKUP_URL}?location=${locationStr}&key=${QWEATHER_API_KEY}`;

    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as CityLookupApiResponse;
        if (result.code === '200' && result.location.length > 0) {
          // API调用成功，并且返回了至少一个城市
          const city = result.location[0];
          const newCity: CurrentCityInfo = { id: city.id, name: city.name };

          // 5. 关键一步：更新全局AppStorage，触发@Watch和天气刷新！
          AppStorage.set<CurrentCityInfo>('currentcity',newCity);
          promptAction.showToast({ message: `已切换到 ${newCity.name}` });

        } else {
          // API业务失败
          promptAction.showToast({ message: `无法识别当前位置，错误码: ${result.code}` });
        }
      }
    } catch (err) {
      console.error("逆地理编码失败", err);
    } finally {
      httpRequest.destroy();
    }
  }
  async openAppSettings() {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      // 获取当前应用的包名，这是它的唯一“身份证”
      let bundleName = 'com.example.weatherapp';
      promptAction.showToast({ message: "“去设置”按钮被点击了！" });

      // 创建一个“意图(Want)”对象，它像一个要去特定地方的“信使”
      let want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
      };

      // 使用 context 的 startAbility 方法，派遣“信使”去启动系统设置页面
      context.startAbility(want);
      console.info("成功请求跳转到应用设置页面");

    } catch (error) {
      console.error("跳转到应用设置失败", JSON.stringify(error));
      promptAction.showToast({ message: "无法打开设置页面" });
    }
  }
  async onCityChange() {
    this.getweather();
    this.get3dForecast();
    this.get24hForecast();
    this.getAirQuality();
    this.getLivingIndices();
    //持久化保存城市信息
    try {
      // 1. 在需要时，动态获取当前页面的上下文
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (context) {
        // 2. 将上下文作为参数，传递给我们的工具函数
        await saveCityToPreferences(context, this.currentCity);
      }
    } catch (e) {
      console.error("在 onCityChange 中保存城市失败", e);
    }
  }


  build() {
    // 用 Refresh 组件包裹最外层的 Column
    Navigation(this.pageStack){
      Refresh({refreshing:this.isRefreshing,promptText:'正在加载中...'}) {
        Scroll(){
          Column({space:10}) {
            //第一部分的实时天气
            TopHeaderView({
              // 传递所有需要“展示”的数据
              nowWeather: this.nowWeather,
              currentCity: this.currentCity,
              updateTime: this.updateTime,
              cacheInfoMessage: this.cacheInfoMessage,
              // 传递所有需要“执行”的动作
              onLocationClick: (): Promise<void> => this.getLocation(),
              onSearchClick: () => this.pageStack.pushPath({ name: 'CitySearchPage' })
            })
              .animation({ duration: 600, curve: Curve.EaseInOut }) // 动画持续600毫秒，缓入缓出

            //中间的24h天气预报
            HourlyForecastView({
              hourlyForecasts: this
                .hourlyForecasts })
              .animation({ duration: 600, curve: Curve.EaseInOut, delay: 100 })

            // 3. 未来几天预报模块
            DailyForecastView({ forecastDays: this.forecastDays })
              .animation({ duration: 600, curve: Curve.EaseInOut, delay: 200 })

            // 4. 空气质量模块
            AirQualityCard({ airQuality: this.airQuality })
              .animation({ duration: 600, curve: Curve.EaseInOut, delay: 300 })

            // 5. 生活指数模块
            LivingIndicesCard({ livingIndices: this.livingIndices })
              .animation({ duration: 600, curve: Curve.EaseInOut, delay: 400 })

            Button(`拨打电话`)
              .onClick(() => {
                let phoneNumber: string = '10086';

                let wantInfo: Want = {
                  action: 'ohos.want.action.DIAL',
                  entities: ['entity.system.dial'],
                  uri: 'tel:10086'
                };
                // UIAbilityContext 获取方式：
                // 在 UIAbility 中用 this.context
                // 在普通组件中通过 getContext(this) 获取
                let context = this.getUIContext().getHostContext() as common.UIAbilityContext;

                context.startAbility(wantInfo)
                  .then(() => {
                    console.log('已启动拨号器');
                  })
                  .catch((err:Error) => {
                    console.error('启动拨号器失败', JSON.stringify(err));
                  });
              })

          }
          .width('100%')
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        }
        .scrollBar(BarState.Off)

      }
      .onRefreshing(()=>{
        this.handleRefresh();
      })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .linearGradient({
      direction: GradientDirection.Bottom, // GradientDirection 是全局可用的，不需要import
      colors: this.backgroundColors
    })

  }


}