import {add_log} from './log/add_logs'
import {login} from './user/login'
import {register} from './user/register'

import { PromptAction } from '@kit.ArkUI';
//初始化持久存储
PersistentStorage.persistProp('token', '');
PersistentStorage.persistProp('username', '');

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController()
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @Provide('index') index: NavPathStack = new NavPathStack()
  @StorageLink('token') token: string = ''
  @StorageLink('username') username: string = ''
  @Builder
  PageMap(name: string) {
    if (name === "add_log") {
      add_log();
    } else if (name === "register") {
      register()
    } else if (name === "login") {
      login()
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
                  .onClick(()=>{
                    this.index.pushPath({name:'add_log'})
                  })
              }
            }
            .height("100%")
          }
          .height("100%")
          .tabBar("日志")


          TabContent(){

          }
          .tabBar("工具")

          TabContent() {
            Column() {
              //用户信息行
              Row() {
                if (this.token === '') {
                  Image($r('app.media.cq_logo_update'))
                    .height(50)
                    .width(50)
                    .margin({ right: 20 })
                  Column() {
                    Text('亲爱的用户')
                      .fontSize(25)
                    Text('请先登录')
                      .fontSize(15)
                  }
                  .alignItems(HorizontalAlign.Start)
                } else {
                  Text(this.username)
                    .fontSize(20)
                    .margin({left:10})
                    .fontSize(20)
                }
              }
              .onClick(() => {
                if (this.token === '') {
                  this.index.pushPath({ name: 'login' })
                }
              })

              Divider().strokeWidth(5).color('#fff1f3f5')
              //其他行信息
              Column() {

                Row() {
                  Text('关于我们')
                    .fontSize(18)
                    .margin(15)
                }
                .height(50)
                .borderRadius(15)
                .backgroundColor('#ffffffff')
                .width('100%')
                .onClick(() => {
                  this.index.pushPath({ name: 'about' })
                })

                Divider().strokeWidth(2).color('#fff1f3f5')
                Row() {
                  Text('应用ICP备案：' + '宁ICP备2024006429号')
                    .fontSize(18)
                    .margin(15)
                }
                .height(50)
                .borderRadius(15)
                .backgroundColor('#ffffffff')
                .width('100%')
                .onClick(() => {
                  this.index.pushPath({ name: 'beian_web_page' })
                })

                Divider().strokeWidth(2).color('#fff1f3f5')
                Row() {
                  Text('退出登录')
                    .fontSize(18)
                    .margin(15)
                }
                .onClick(() => {
                  this.username = '';
                  this.token = '';
                  this.promptAction.showToast({
                    message: '退出成功！'
                  });
                })
                .height(50)
                .borderRadius(15)
                .backgroundColor('#ffffffff')
                .width('100%')
              }
              .width('90%')
            }
            .height('100%')
          }
          .tabBar('我的')
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