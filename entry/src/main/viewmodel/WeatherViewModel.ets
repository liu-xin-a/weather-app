// 文件路径: entry/src/main/ets/controller/WeatherController.ets


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
  LivingIndex, NowWeatherData,
  WeatherApiResponse } from '../ets/model/WeatherModels';
import { getWeatherGradientColors } from '../ets/utils/StyleProvider';
import { abilityAccessCtrl, common, PermissionRequestResult, Permissions, Want } from '@kit.AbilityKit';
import { saveCityToPreferences } from '../ets/utils/PreferencesUtil';
import { vibrator } from '@kit.SensorServiceKit';
import { QWEATHER_24H_URL, QWEATHER_3D_URL, QWEATHER_AIR_NOW_URL,
  QWEATHER_CITY_LOOKUP_URL,
  QWEATHER_INDICES_1D_URL,
  QWEATHER_NOW_URL } from '../ets/common/Constants';
import { QWEATHER_API_KEY } from '../ets/common/Constants';
import { formatTime } from '../ets/utils/WeatherIconMapper';
import { loadWeatherCache, saveWeatherCache } from '../ets/utils/CacheUtil';
import { geoLocationManager } from '@kit.LocationKit';
import { promptAction } from '@kit.ArkUI';
import { http } from '@kit.NetworkKit';

// 1. 使用 @Observed 装饰器，让这个类成为一个“可被观察的”数据源
@Observed
export class WeatherViewModel {
  // --- 1. 所有的UI状态变量 ---
  nowWeather: NowWeatherData = initialNowWeatherData;
  forecastDays: DailyForecast[] = [];
  hourlyForecasts: HourlyForecast[] = [];
  updateTime: string = '';
  isRefreshing: boolean = false;
  backgroundColors: [string, number][] = getWeatherGradientColors('100');
  cacheInfoMessage: string = '';
  airQuality: AirQualityNow | null = null;
  livingIndices: LivingIndex[] = [];

  // currentCity 通过 AppStorage 交互
  currentCity: CurrentCityInfo = { id: '101010100', name: '北京' };

  private context?: common.UIAbilityContext;

  // --- 2. 构造函数与初始化 ---
  constructor() {
    // 监听 AppStorage 的变化，并更新自己的 currentCity 属性
    AppStorage.link('currentcity').set((value: CurrentCityInfo) => {
      this.currentCity = value;
      this.onCityChange(); // 当 AppStorage 变化时，触发逻辑
    });
    // 初始化时，也从 AppStorage 同步一次最新值
    this.currentCity = AppStorage.get<CurrentCityInfo>('currentcity') || this.currentCity;
  }

  // 允许外部注入上下文
  setContext(context: common.UIAbilityContext) {
    this.context = context;
  }

  // --- 3. 核心业务逻辑 ---

  // 当城市变更时触发的逻辑
  onCityChange() {
    this.fetchAllWeather();
    if (this.context) {
      saveCityToPreferences(this.context, this.currentCity);
    }
  }

  // 获取所有天气数据的总入口
  fetchAllWeather() {
    this.getweather();
    this.get3dForecast();
    this.get24hForecast();
    this.getAirQuality();
    this.getLivingIndices();
  }

  // 下拉刷新的逻辑
  async handleRefresh() {
    this.isRefreshing = true;
    try {
      await Promise.all([
        this.getweather(),
        this.get3dForecast(),
        this.get24hForecast(),
        this.getAirQuality(),
        this.getLivingIndices()
      ]);
      // vibrator.startVibration({ type: 'haptic.clock.tick' });
    } catch (e) {
      console.error("刷新失败", e);
    } finally {
      setTimeout(() => {
        this.isRefreshing = false;
      }, 1000);
    }
  }

  // --- 4. 所有的网络请求与缓存函数 ---

  async getweather() {
    if (!this.context) return;
    const cacheKey = `now_weather_${this.currentCity.id}`;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_NOW_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as WeatherApiResponse;
        if (result.code === '200' && result.now) {
          this.nowWeather = result.now;
          this.backgroundColors = getWeatherGradientColors(this.nowWeather.icon);
          this.updateTime = formatTime(new Date());
          this.cacheInfoMessage = '';
          await saveWeatherCache(this.context, cacheKey, result.now);
          return;
        }
      }
      throw new Error(`API or HTTP Error for now weather`);
    } catch (err) {
      console.error("获取实时天气失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<NowWeatherData>(this.context, cacheKey);
      if (cachedData) {
        this.nowWeather = cachedData.data;
        this.backgroundColors = getWeatherGradientColors(this.nowWeather.icon);
        const minutesAgo = Math.round((Date.now() - cachedData.timestamp) / 60000);
        this.cacheInfoMessage = `离线模式：数据更新于${minutesAgo}分钟前`;
      }
    } finally {
      httpRequest.destroy();
    }
  }

  async get3dForecast() {
    if (!this.context) return;
    const cacheKey = `3d_forecast_${this.currentCity.id}`;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_3D_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ForecastApiResponse;
        if (result.code === '200' && result.daily) {
          this.forecastDays = result.daily;
          await saveWeatherCache(this.context, cacheKey, result.daily);
          return;
        }
      }
      throw new Error(`API or HTTP Error for 3d forecast`);
    } catch (err) {
      console.error("获取3日预报失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<DailyForecast[]>(this.context, cacheKey);
      if (cachedData) { this.forecastDays = cachedData.data; }
    } finally {
      httpRequest.destroy();
    }
  }

  async get24hForecast() {
    if (!this.context) return;
    const cacheKey = `24h_forecast_${this.currentCity.id}`;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_24H_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as HourlyApiResponse;
        if (result.code === '200' && result.hourly) {
          this.hourlyForecasts = result.hourly;
          await saveWeatherCache(this.context, cacheKey, result.hourly);
          return;
        }
      }
      throw new Error(`API or HTTP Error for 24h forecast`);
    } catch (err) {
      console.error("获取逐小时预报失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<HourlyForecast[]>(this.context, cacheKey);
      if (cachedData) { this.hourlyForecasts = cachedData.data; }
    } finally {
      httpRequest.destroy();
    }
  }

  async getAirQuality() {
    if (!this.context) return;
    const cacheKey = `air_quality_${this.currentCity.id}`;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_AIR_NOW_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as AirQualityApiResponse;
        if (result.code === '200' && result.now) {
          this.airQuality = result.now;
          await saveWeatherCache(this.context, cacheKey, result.now);
          return;
        }
      }
      throw new Error(`API or HTTP Error for Air Quality`);
    } catch (err) {
      console.error("获取空气质量失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<AirQualityNow>(this.context, cacheKey);
      if (cachedData) { this.airQuality = cachedData.data; }
    } finally {
      httpRequest.destroy();
    }
  }

  async getLivingIndices() {
    if (!this.context) return;
    const cacheKey = `living_indices_${this.currentCity.id}`;
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_INDICES_1D_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}&type=0`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as IndicesApiResponse;
        if (result.code === '200' && result.daily) {
          this.livingIndices = result.daily;
          await saveWeatherCache(this.context, cacheKey, result.daily);
          return;
        }
      }
      throw new Error(`API or HTTP Error for Living Indices`);
    } catch (err) {
      console.error("获取生活指数失败，尝试从缓存加载...", err);
      const cachedData = await loadWeatherCache<LivingIndex[]>(this.context, cacheKey);
      if (cachedData) { this.livingIndices = cachedData.data; }
    } finally {
      httpRequest.destroy();
    }
  }

  // --- 5. 所有的定位与跳转函数 ---

  async getLocation() {
    if (!this.context) return;
    try {
      const permissions: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
      let atManager = abilityAccessCtrl.createAtManager();
      const permissionResult = await (atManager.requestPermissionsFromUser(this.context, permissions) as Promise<PermissionRequestResult>);
      const locationPermissionIndex = permissions.indexOf('ohos.permission.APPROXIMATELY_LOCATION');
      if (permissionResult.authResults[locationPermissionIndex] === 0) {
        let isLocationEnabled = await geoLocationManager.isLocationEnabled();
        if (!isLocationEnabled) {
          promptAction.openToast({ message: "请在系统中开启定位服务" });
          return;
        }
        let location = await geoLocationManager.getCurrentLocation();
        await this.getCityInfoByCoords(location.longitude, location.latitude);
      } else {
        // 这里需要通过回调来通知View打开弹窗
        // 我们暂时先用Toast代替
        promptAction.openToast({ message: "您拒绝了定位授权，请在设置中开启" });
      }
    } catch (error) {
      promptAction.openToast({ message: "定位失败，请稍后重试" });
    }
  }

  async getCityInfoByCoords(longitude: number, latitude: number) {
    let httpRequest = http.createHttp();
    const locationStr = `${longitude.toFixed(2)},${latitude.toFixed(2)}`;
    const url = `${QWEATHER_CITY_LOOKUP_URL}?location=${locationStr}&key=${QWEATHER_API_KEY}`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as CityLookupApiResponse;
        if (result.code === '200' && result.location.length > 0) {
          const city = result.location[0];
          const newCity: CurrentCityInfo = { id: city.id, name: city.name };
          AppStorage.set<CurrentCityInfo>('currentcity', newCity);
          promptAction.openToast({ message: `已切换到 ${newCity.name}` });
        }
      }
    } catch (err) {
      console.error("逆地理编码失败", err);
    } finally {
      httpRequest.destroy();
    }
  }

  async openAppSettings() {
    if (!this.context) return;
    try {
      let bundleName = this.context.abilityInfo.bundleName;
      let want: Want = {
        action: 'ability.want.action.APP_DETAILS_SETTINGS',
        parameters: { 'bundleName': bundleName }
      };
      await this.context.startAbility(want);
    } catch (error) {
      promptAction.openToast({ message: "无法打开设置页面" });
    }
  }
}