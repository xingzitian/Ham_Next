import {add_log} from './log/add_los'




@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController()
  @Provide('index') index: NavPathStack = new NavPathStack()
  @Builder
  PageMap(name: string) {
    if (name === "add_log") {
      add_log();
    } else if (name === "NavDestinationTitle2") {
      // pageTwoTmp();
    } else if (name === "NavDestinationTitle3") {
      // pageThreeTmp();
    }
  }
  build() {
    Navigation(this.index) {
      Column(){
        Tabs({ barPosition: BarPosition.End, controller: this.controller }){
          TabContent(){
            Column(){
              Row(){
                Text("当前时区时间：")
                  .fontSize(20)
                  .textAlign(TextAlign.Start)
                TextClock()
                  .format("yyyy年M月d日HH:mm:ss")
              }
              Divider().strokeWidth(5)
              Row(){
                Text("当前UTC时间：")
                  .fontSize(20)
                  .textAlign(TextAlign.Start)
                TextClock({timeZoneOffset:0})
                  .format("yyyy年M月d日HH:mm:ss")
              }
              Row(){
                Text("当前用户呼号：")
                  .fontSize(20)

              }
              Row({ space: 35 }){
                Image($r('app.media.quick_mark'))
                  .width(160)
                  .onClick(()=>{
                    this.index.pushPath({name:'add_log'})
                  })
                Image($r('app.media.some_mark'))
                  .width(160)
              }
            }
            .height("100%")
          }
          .height("100%")
          .tabBar("日志")


          TabContent(){

          }
          .tabBar("工具")
          TabContent(){

          }
          .tabBar("我的")
        }
        .height('100%')
        .barMode(BarMode.Fixed)
        .scrollable(false)
        .borderStyle(BorderStyle.Solid)
        .align(Alignment.Start)
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
    .height('100%')
  }
}