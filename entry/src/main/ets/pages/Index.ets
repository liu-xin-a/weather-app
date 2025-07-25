import { promptAction, UIContext } from '@kit.ArkUI'
import { QWEATHER_3D_URL, QWEATHER_7D_URL, QWEATHER_API_KEY, QWEATHER_NOW_URL } from '../common/Constants';
import {
  CurrentCityInfo,
  DailyForecast,
  ForecastApiResponse,
  initialNowWeatherData, NowWeatherData, WeatherApiResponse } from '../model/WeatherModels';
import { http } from '@kit.NetworkKit';
import { formatForecastDate, formatTime, ICON_MAP } from '../utils/WeatherIconMapper';

@Entry
@Component
struct Index {

  @State nowWeather:NowWeatherData = initialNowWeatherData;
  @State forecastDays: DailyForecast[] = []; // 新增：用于存储未来几天预报的数组
  @State updateTime: string = ''; // <-- 新增：用于存储格式化后的更新时间
  @State isRefreshing: boolean = false; // <-- 新增：控制刷新动画的显示状态
  @StorageLink('currentcity')
  @Watch('onCityChange')
  currentCity: CurrentCityInfo = { id: '101010100', name: '北京' };
  pageStack: NavPathStack = new NavPathStack();
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
  async handleRefresh() {
    // 1. 开始刷新，显示加载动画
    this.isRefreshing = true;

    // 2. 使用 Promise.all 并发执行两个网络请求，提高效率
    //    这会同时开始获取实时天气和3日预报
    await Promise.all([
      this.getweather(),
      this.get3dForecast()
    ]);
    // 3.等待两秒之后 ，结束刷新，隐藏加载动画
    setTimeout(() => {
      this.isRefreshing = false
    }, 2000)
  }
  onCityChange() {
    this.getweather();
    this.get3dForecast();
  }

  build() {
    // 用 Refresh 组件包裹最外层的 Column
    Navigation(this.pageStack){
      Refresh({refreshing:this.isRefreshing,promptText:'正在加载中...'}) {
        Column() {
          Column(){
            Row(){
              Text(this.currentCity.name)
                .fontSize(25)
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
                  .fontSize(50)
                  .fontFamily('myfont')
                  .margin(40)
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

            Column({space:30}){
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
      }
      .onRefreshing(()=>{
        this.handleRefresh();
      })
    }
  }


}