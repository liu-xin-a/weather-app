@CustomDialog
export struct PermissionDialog {
  // controller 由系统自动注入，用于关闭弹窗
  controller?: CustomDialogController;
  // “取消”按钮的回调函数
  onCancel: () => void = () => {};
  // “去设置”按钮的回调函数
  onConfirm: () => void = () => {};

  build() {
    Column() {
      // 1. 弹窗标题
      Text("需要定位权限")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24, bottom: 12 })

      // 2. 弹窗消息内容
      Text("为了获取您当前位置的天气，我们需要您的定位授权。请在系统设置中手动开启。")
        .fontSize(16)
        .lineHeight(22)
        .opacity(0.8)
        .textAlign(TextAlign.Start)
        .margin({ left: 24, right: 24, bottom: 24 })

      // 3. 分隔线
      Divider().width('100%').color('#000000').opacity(0.1)

      // 4. 底部按钮区域
      Row() {
        // 取消按钮
        Button('取消')
          .onClick(() => {
            this.onCancel(); // 执行外部传入的 onCancel 逻辑
            this.controller?.close(); // 关闭弹窗
          })
          .fontColor(Color.Gray)
          .backgroundColor(Color.Transparent) // 透明背景，更现代
          .layoutWeight(1)

        // 垂直分隔线
        Divider().vertical(true).height('60%').color('#000000').opacity(0.1)

        // 去设置按钮
        Button('去设置')
          .onClick(() => {
            this.onConfirm(); // 执行外部传入的 onConfirm 逻辑（即跳转设置）
            this.controller?.close(); // 关闭弹窗
          })
          .fontColor('#007DFF')
          .fontWeight(FontWeight.Medium)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
      }
      .height(55) // 固定按钮区域高度
      .width('100%')
    }
    .width('85%') // 弹窗宽度为屏幕的85%
    .borderRadius(20)
    .backgroundColor(Color.White)
  }
}