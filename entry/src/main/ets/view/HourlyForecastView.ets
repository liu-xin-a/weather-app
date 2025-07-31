// 文件路径: entry/src/main/ets/view/HourlyForecastView.ets

import { HourlyForecast } from '../model/WeatherModels';
import { ICON_MAP } from '../utils/WeatherIconMapper';
import { formatTime } from '../utils/WeatherIconMapper';

@Component
export struct HourlyForecastView {
  // 1. 使用 @Prop 接收父组件传递过来的“逐小时预报”数组
  @Prop hourlyForecasts: HourlyForecast[];

  build() {
    // 2. 将之前在 Index.ets 中构建这部分UI的代码，原封不动地搬到这里
    Column() {
      Text("未来24小时预报")
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: 5 })

      List({ space: 10 }) {
        ForEach(this.hourlyForecasts, (item: HourlyForecast) => {
          ListItem() {
            Column({ space: 8 }) {
              Text(formatTime(new Date(item.fxTime)))
                .fontSize(14)
              Text(ICON_MAP[item.icon])
                .fontFamily('myfont')
                .fontSize(24)
              Text(`${item.temp}°`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
            }
            .width(50)
            .padding({ top: 10, bottom: 10 })
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .scrollBar(BarState.Off) // 隐藏滚动条，更美观

    }
    .padding(20)
    .borderRadius(20)
    .backgroundColor('#ffd2dbf0')
    .margin({ left: 10, right: 10 })
    .height(150)
  }
}