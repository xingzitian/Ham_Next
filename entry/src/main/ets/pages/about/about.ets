@Component
export struct about {
  @Consume('index') index: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        Image($r('app.media.cq_logo_update'))
          .height(100)
          .margin({ top: 40, bottom: 10 });
        Text('版本信息：' + '1.0.0')
          .fontSize(30);
        Text('隐私政策')
          .fontSize(30)
          .onClick(() => {
            this.index.pushPath({ name: 'private_dada_web_page' })
          })
      }
    }
    .title('关于我们')
  }
}
