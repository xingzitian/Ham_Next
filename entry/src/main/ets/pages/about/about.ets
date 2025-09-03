@Component
export struct about {
  @Consume('index') index: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        Image($r('app.media.cq_logo_update'))
          .height(100)
          .margin({ top: 40, bottom: 10 });
        Text('版本信息：' + '1.0.6')
          .fontSize(30);
      }
    }
    .title('关于我们')
  }
}
