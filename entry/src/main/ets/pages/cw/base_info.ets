
@Component
export struct base_info {
  @Consume('index') index: NavPathStack;

  build() {
    NavDestination() {
      Column({ space: 10 }){
        Text('CW电码表')

          .borderRadius(15)
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'base_info_1' })
          })
        Divider().strokeWidth(3).color('#fff1f3f5')
        Text('常见q短语')

          .borderRadius(15)
          .backgroundColor('#ffffffff')
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'base_info_2' })
          })
        Divider().strokeWidth(3).color('#fff1f3f5')
        Text('字母解释法')
          .borderRadius(15)
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'base_info_3' })
          })

      }
      .width("90%")
    }
    .title('返回')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}
