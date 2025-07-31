// 文件路径: entry/src/main/ets/view/DailyForecastView.ets

import { DailyForecast } from '../model/WeatherModels';
import { ICON_MAP } from '../utils/WeatherIconMapper';
import { formatForecastDate } from '../utils/WeatherIconMapper';

@Component
export struct DailyForecastView {
  @Prop forecastDays: DailyForecast[];

  build() {
    // 将之前在 Index.ets 中构建这部分UI的代码，原封不动地搬到这里
    List({ space: 10 }) {
      ForEach(this.forecastDays, (item: DailyForecast) => {
        ListItem() {
          Row() {
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
}