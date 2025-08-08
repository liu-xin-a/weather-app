

import {ICON_EMOJI_MAP} from '../../utils/WeatherIconMapper';


const storage = new LocalStorage();

@Entry(storage) // 2. 将 storage 实例注入到UI中
@Component
export struct WeatherCard {
  // 3. 使用 @LocalStorageLink (或 @LocalStorageProp) 订阅指定键名的数据
  @LocalStorageProp('city') city: string = '点击刷新';
  @LocalStorageProp('temp') temp: string = '--';
  @LocalStorageProp('text') text: string = '...';
  @LocalStorageProp('iconCode') iconCode: string = '999';

  build() {
    Button() {
      Column() {
        Text(this.city)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })

        Text(this.text)
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 2 })

        Text(this.temp + '°C')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height('100%')
      .padding(12)
      .backgroundColor('#ffffff')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%').height('100%')
    .backgroundColor('#F7F8FA')
    .borderRadius(24)
    .onClick(() => {
      console.info(`WIDGET_UI_DEBUG: 卡片被点击！发送 "refresh" message 事件。`);
      // 4. 发送交互事件，通知后台服务去获取新数据
      postCardAction(this, {
        action: 'message',
        params: {
          'message': 'refresh'
        }
      });
    })
  }
}