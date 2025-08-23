
@Component
export struct base_info {
  @Consume('index') index: NavPathStack;

  build() {
    NavDestination() {
      Column({ space: 10 }){
        Text('CW电码表')
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'base_info_1' })
          })
        Divider().strokeWidth(3).color('#fff1f3f5')
        Text('常见q短语')
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

@Component
export struct base_info2 {
  @Consume('index') index: NavPathStack;

  build() {
    NavDestination() {
      Column({ space: 10 }){
        Text('文字转摩尔斯电码音频')
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'MorseCodeConverter' })
          })
        Divider().strokeWidth(3).color('#fff1f3f5')
        Text('摩尔斯电码输入练习')
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'MorseMinimalPractice' })
          })
        Divider().strokeWidth(3).color('#fff1f3f5')
        Text('摩尔斯电码听力练习')
          .width('100%')
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.index.pushPath({ name: 'MorseTraining' })
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
