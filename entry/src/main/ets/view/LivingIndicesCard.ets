// 文件路径: entry/src/main/ets/view/LivingIndicesCard.ets

import { LivingIndex } from '../model/WeatherModels';

@Component
export struct LivingIndicesCard {
  @Prop livingIndices: LivingIndex[];

  build() {
    // 使用 if 确保在有数据时才显示卡片
    if (this.livingIndices.length > 0) {
      Column({ space: 10 }) {
        Text("生活指数")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Start)
        Divider().color(Color.White).opacity(0.2).margin({ top: 5, bottom: 5 })
        ForEach(this.livingIndices.slice(0, 5), (item: LivingIndex, index: number) => {
          Column({ space: 6 }) {
            Text(`${item.name} - ${item.category}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text(item.text)
              .fontSize(14)
              .opacity(0.8)
              .width('100%')
              .lineHeight(18)
          }
          if (index < 4) {
            Divider().color(Color.White).opacity(0.1).margin({ top: 10, bottom: 10 })
          }
        })
      }
      .padding(20)
      .borderRadius(20)
      .backgroundColor('#ffd2dbf0')
      .margin(10)
    }
  }
}