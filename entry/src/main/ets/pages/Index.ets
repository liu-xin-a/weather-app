import { promptAction, UIContext } from '@kit.ArkUI'
import {
  QWEATHER_24H_URL,
  QWEATHER_3D_URL, QWEATHER_7D_URL, QWEATHER_API_KEY,
  QWEATHER_CITY_LOOKUP_URL,
  QWEATHER_NOW_URL } from '../common/Constants';
import {
  CityLookupApiResponse,
  CurrentCityInfo,
  DailyForecast,
  ForecastApiResponse,
  HourlyApiResponse,
  HourlyForecast,
  initialNowWeatherData, NowWeatherData, WeatherApiResponse } from '../model/WeatherModels';
import { http } from '@kit.NetworkKit';
import { formatForecastDate, formatTime, ICON_MAP } from '../utils/WeatherIconMapper';
import { geoLocationManager } from '@kit.LocationKit';
import {
  ability, abilityAccessCtrl, common, PermissionRequestResult, Permissions, Want} from '@kit.AbilityKit';
import { PermissionDialog } from '../view/PermissionDialog';


@Entry
@Component
struct Index {

  @State nowWeather:NowWeatherData = initialNowWeatherData;
  @State forecastDays: DailyForecast[] = []; // 新增：用于存储未来几天预报的数组
  @State hourlyForecasts: HourlyForecast[] = []; // 新增：存储逐小时预报数据
  @State updateTime: string = ''; // <-- 新增：用于存储格式化后的更新时间
  @State isRefreshing: boolean = false; // <-- 新增：控制刷新动画的显示状态
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
  aboutToAppear(): void {
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
  }
  async getweather(){
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
          console.info('Weather data updated successfully.');
          this.updateTime = formatTime(new Date());
        } else {
          // API 返回了错误信息，例如key不正确
          console.error(`Weather API Error: ${result.code}`);

        }
      } else {
        // 网络请求本身失败
        console.error(`Http request failed, code: ${response.responseCode}`);
      }
    } catch (err) {
      // 其他异常，例如网络不通
      console.error(`Http request error: ${JSON.stringify(err)}`);
    } finally {
      // 无论成功失败，最后都销毁请求实例，释放资源
      httpRequest.destroy();
    }
  }
  async get3dForecast() {
    // 这个函数结构和 getweather 几乎一模一样
    let httpRequest = http.createHttp();
    // 注意！URL现在是 QWEATHER_3D_URL
    const url = `${QWEATHER_3D_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;

    try {
      const response = await httpRequest.request(url); // Method 默认是 GET
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ForecastApiResponse;
        if (result.code === '200') {
          // 当数据获取成功，更新存储预报数据的 State 变量
          this.forecastDays = result.daily;
          console.info('7-day forecast updated successfully.');
        } else {
          console.error(`Forecast API Error: ${result.code}`);
        }
      } else {
        console.error(`Forecast http request failed, code: ${response.responseCode}`);
      }
    } catch (err) {
      // ... 错误处理 ...
      console.error('Forecast request caught an error.', err);
    } finally {
      httpRequest.destroy();
    }
  }
  async get24hForecast() {
    let httpRequest = http.createHttp();
    const url = `${QWEATHER_24H_URL}?location=${this.currentCity.id}&key=${QWEATHER_API_KEY}`;
    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as HourlyApiResponse;
        if (result.code === '200') {
          this.hourlyForecasts = result.hourly;
          console.info('Hourly forecast updated successfully.');
        }
      }
    } catch (err) {
      console.error('Hourly forecast request failed.', err);
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
      this.get24hForecast()
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
        promptAction.openToast({ message: "正在获取当前位置..." });

        let isLocationEnabled = await geoLocationManager.isLocationEnabled();
        if (!isLocationEnabled) {
          promptAction.openToast({ message: "请在系统中开启定位服务" });
          return;
        }

        let location = await geoLocationManager.getCurrentLocation();
        console.log('经度：' + location.longitude);
        console.log('纬度：' + location.latitude);
        await this.getCityInfoByCoords(location.longitude, location.latitude);

      } else {
        // --- 权限被拒绝 ---
        console.warn("定位权限被用户拒绝。");
        promptAction.openToast({ message: "您拒绝了定位授权，无法获取位置" });
        this.permissionDialogController.open();

      }

    } catch (error) {
      console.error('定位过程中发生异常：' + JSON.stringify(error));
      promptAction.openToast({ message: "定位失败，请稍后重试" });
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
          promptAction.openToast({ message: `已切换到 ${newCity.name}` });

        } else {
          // API业务失败
          promptAction.openToast({ message: `无法识别当前位置，错误码: ${result.code}` });
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
      promptAction.openToast({ message: "“去设置”按钮被点击了！" });

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
      promptAction.openToast({ message: "无法打开设置页面" });
    }
  }
  onCityChange() {
    this.getweather();
    this.get3dForecast();
    this.get24hForecast();
  }


  build() {
    // 用 Refresh 组件包裹最外层的 Column
    Navigation(this.pageStack){
      Refresh({refreshing:this.isRefreshing,promptText:'正在加载中...'}) {
        Column() {
          //第一部分的实时天气
          Column(){
            Row(){
              Row({space:10}){
                Image($r('app.media.local_fill')) // 准备一个定位图标 ic_location_on.png
                  .width(24).height(24)
                  .onClick(() => {
                    this.getLocation();
                  })
                Text(this.currentCity.name)
                  .fontSize(25)
              }

              Image($r('app.media.ic_public_search_filled'))
                .width(30)
                .onClick(()=>{
                  this.pageStack.pushPath({name:'CitySearchPage'});
                })
              Text(`更新于${this.updateTime}`)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({left:20,right:20})
            Row(){
              Column({space:10}){
                Text(ICON_MAP[this.nowWeather.icon])
                  .fontSize(40)
                  .fontFamily('myfont')
                  .margin(10)
                Text(this.nowWeather.text)
                  .fontSize(20)
                Text('体感温度: '+this.nowWeather.feelsLike+'°')
                  .fontSize(20)
              }
              Text('温度: '+this.nowWeather.temp+'°')
                .fontSize(20)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            Column({space:10}){
              Row(){
                Text('湿度')
                  .fontSize(20)
                Text(this.nowWeather.humidity+'%')
                  .fontSize(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              Row(){
                Text('风向/风力')
                  .fontSize(20)
                Text(this.nowWeather.windDir+this.nowWeather.windScale+'级')
                  .fontSize(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              Row(){
                Text('气压')
                  .fontSize(20)
                Text(this.nowWeather.pressure+'hPa')
                  .fontSize(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              Row(){
                Text('能见度')
                  .fontSize(20)
                Text(this.nowWeather.vis+'km')
                  .fontSize(20)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)

            }
            .borderRadius(20)
            .backgroundColor('#ffb9bfcc')
            .padding(20)
          }
          .borderRadius(20)
          .backgroundColor('#ffd2dbf0')
          .padding(20)
          .margin(10)

          //中间的24h天气预报
          Column() {
            Text("未来24小时预报")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 5 })

            // 关键：使用List并设置其方向为横向
            List({ space: 10 }) { // space是每个元素间的间距
              ForEach(this.hourlyForecasts, (item: HourlyForecast) => {
                ListItem() {
                  // 这里是每个小时预报项的UI
                  Column({ space: 8 }) {
                    // 时间，例如 "14:00"
                    Text(formatTime(new Date(item.fxTime)))
                      .fontSize(14)
                    // 天气图标
                    Text(ICON_MAP[item.icon])
                      .fontFamily('myfont')
                      .fontSize(24)
                    // 温度
                    Text(`${item.temp}°`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                  }
                  .width(50) // 给每一项一个固定的宽度
                  .padding({ top: 10, bottom: 10 })
                }
              })
            }
            .listDirection(Axis.Horizontal) // <-- 设置列表为水平方向！
            .edgeEffect(EdgeEffect.Spring)   // 设置滚动到边缘时的回弹效果
            .width('100%')
            .scrollBar(BarState.Off)

          }
          .padding(20)
          .borderRadius(20)
          .backgroundColor('#ffd2dbf0') // 使用您喜欢的主题色
          .margin({left: 10, right: 10}) // 与其他卡片保持间距
          .height(150)

          //底部的三天天气
          List({space:10}){
            ForEach(this.forecastDays,(item:DailyForecast)=>{
              ListItem(){
                Row(){
                  Text(item.fxDate)
                    .fontSize(20)
                  Text(formatForecastDate(item.fxDate))
                    .fontSize(20)
                  Text(ICON_MAP[item.iconDay])
                    .fontSize(20)
                    .fontFamily('myfont')

                  Text(`${item.tempMin}° / ${item.tempMax}°`)
                    .fontSize(20)
                }
                .justifyContent(FlexAlign.SpaceAround)
                .width('100%')
              }
            })
          }
          .borderRadius(20)
          .backgroundColor('#ffd2dbf0')
          .padding(20)
          .margin(10)

        }
        .height('100%')
        .width('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
      }
      .onRefreshing(()=>{
        this.handleRefresh();
      })
    }
  }


}