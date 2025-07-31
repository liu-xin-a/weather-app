// 文件路径: entry/src/main/ets/view/AirQualityCard.ets

import { AirQualityNow } from '../model/WeatherModels';

@Component
export struct AirQualityCard {
  // @Prop 允许父组件传入 null
  @Prop airQuality: AirQualityNow | null;

  build() {
    // 使用 if 确保在有数据时才显示卡片
    if (this.airQuality) {
      Column({ space: 10 }) {
        Text("空气质量")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Start)
        Divider().color(Color.White).opacity(0.2).margin({ top: 5, bottom: 5 })
        Row({ space: 15 }) {
          Column({ space: 8 }) {
            Text(this.airQuality.aqi)
              .fontSize(40)
              .fontWeight(FontWeight.Lighter) // 使用您设定的Lighter
            Row({ space: 5 }) {
              Text(this.airQuality.category)
                .fontSize(16)
                .fontColor(Color.White)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(6)
                .backgroundColor(this.airQuality.category === '优' ? '#4CAF50' : '#FFC107')
            }
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
          Column({ space: 8 }) {
            Text(`PM2.5: ${this.airQuality.pm2p5}`)
            Text(`PM10: ${this.airQuality.pm10}`)
          }
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1.2)
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
      }
      .padding(20)
      .borderRadius(20)
      .backgroundColor('#ffd2dbf0') // 使用您设定的背景色
      .margin(10)
    }
  }
}