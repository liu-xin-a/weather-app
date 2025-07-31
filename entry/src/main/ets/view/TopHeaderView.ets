// 文件路径: entry/src/main/ets/view/TopHeaderView.ets

import { CurrentCityInfo, NowWeatherData } from '../model/WeatherModels';
import { ICON_MAP } from '../utils/WeatherIconMapper';

@Component
export struct TopHeaderView {
  // --- 数据接收区：接收所有需要“展示”的状态 ---
  @Prop nowWeather: NowWeatherData;
  @Prop currentCity: CurrentCityInfo;
  @Prop updateTime: string;
  @Prop cacheInfoMessage: string;

  // --- 动作回调区：接收所有需要“执行”的动作 ---
  onLocationClick: () => void = () => {};
  onSearchClick: () => void = () => {};

  build() {
    // --- 以下所有UI代码，都精确地复制自您最后提供的 Index.ets ---
    Column() {
      // 1. 顶部栏
      Row() {
        Row({ space: 10 }) {
          Image($r('app.media.local_fill'))
            .width(24).height(24)
            .onClick(() => this.onLocationClick()) // 调用回调
          Text(this.currentCity.name)
            .fontSize(25)
        }
        Image($r('app.media.ic_public_search_filled'))
          .width(30)
          .onClick(() => this.onSearchClick()) // 调用回调
        if (this.cacheInfoMessage) {
          Text(this.cacheInfoMessage).fontSize(12).fontColor(Color.White)
            .backgroundColor(Color.Red).padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
        } else {
          Text(`更新于${this.updateTime}`)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })

      // 2. 主天气信息
      Row() {
        Column({ space: 10 }) {
          // 这里没有使用我之前建议的 Circle 背景，完全忠于您的简洁设计
          Text(ICON_MAP[this.nowWeather.icon])
            .fontSize(40) // 使用您设定的 40
            .fontFamily('myfont')
            .margin(10) // 使用您设定的 10
          Text(this.nowWeather.text)
            .fontSize(20)
          Text('体感温度: ' + this.nowWeather.feelsLike + '°')
            .fontSize(20)
        }
        Text('温度: ' + this.nowWeather.temp + '°')
          .fontSize(20)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // 3. 详细信息卡片 (湿度、风力等)
      Column({ space: 10 }) {
        Row() {
          Text('湿度').fontSize(20)
          Text(this.nowWeather.humidity + '%').fontSize(20)
        }.width('100%').justifyContent(FlexAlign.SpaceAround)
        Row() {
          Text('风向/风力').fontSize(20)
          Text(this.nowWeather.windDir + this.nowWeather.windScale + '级').fontSize(20)
        }.width('100%').justifyContent(FlexAlign.SpaceAround)
        Row() {
          Text('气压').fontSize(20)
          Text(this.nowWeather.pressure + 'hPa').fontSize(20)
        }.width('100%').justifyContent(FlexAlign.SpaceAround)
        Row() {
          Text('能见度').fontSize(20)
          Text(this.nowWeather.vis + 'km').fontSize(20)
        }.width('100%').justifyContent(FlexAlign.SpaceAround)
      }
      .borderRadius(20)
      // *** 关键：使用您设定的、正确的背景色 ***
      .backgroundColor('#ffd2dbf0')
      .padding(20)
      .margin({ top: 10 })
    }
    .borderRadius(20)
    .padding(10)
  }
}