import { UIContext } from '@kit.ArkUI'
import { QWEATHER_API_KEY, QWEATHER_NOW_URL } from '../common/Constants';
import { initialNowWeatherData, NowWeatherData, WeatherApiResponse } from '../model/WeatherModels';
import { http } from '@kit.NetworkKit';


@Entry
@Component
struct Index {
  @State nowWeather:NowWeatherData = initialNowWeatherData;
  aboutToAppear(): void {
    // 在组件中获取 UIContext
    let uiContext: UIContext = this.getUIContext();
    // 注册字体
    uiContext.getFont().registerFont({
      familyName: 'myfont',
      familySrc: '/fonts/iconfont.ttf'
    });
    this.getweather();
  }
  async getweather(){
    // 创建 http request 实例
    let httpRequest = http.createHttp()
    // 拼接请求的 URL，location=101010100 是北京的城市ID，你可以换成其他的
    const url = `${QWEATHER_NOW_URL}?location=101010100&key=${QWEATHER_API_KEY}`;

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

  build() {
    Column() {
      Column(){
        Row(){
          Text('北京市')
            .fontSize(25)
          Text(`更新于时间10:35`)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({left:20,right:20})
        Row(){
          Column({space:10}){
            Text('\uf101')
              .fontSize(80)
              .fontFamily('myfont')
              .margin(40)
            Text(this.nowWeather.text)
              .fontSize(20)
            Text('体感温度 26')
              .fontSize(20)
          }
          Text(this.nowWeather.temp)
            .fontSize(20)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .borderRadius(20)
      .backgroundColor('#ffd2dbf0')
      .padding(20)
      .margin(10)


      Column({space:30}){
        Row(){
          Text('湿度')
            .fontSize(20)
          Text('72%')
            .fontSize(20)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        Row(){
          Text('风向/风力')
            .fontSize(20)
          Text('东南风1级')
            .fontSize(20)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        Row(){
          Text('气压')
            .fontSize(20)
          Text('1003hPa')
            .fontSize(20)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        Row(){
          Text('能见度')
            .fontSize(20)
          Text('16km')
            .fontSize(20)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)

      }
      .borderRadius(20)
      .backgroundColor('#ffd2dbf0')
      .padding(20)
      .margin(10)
    }
    .height('100%')
    .width('100%')
  }
}