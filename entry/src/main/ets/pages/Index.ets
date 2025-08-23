import { add_log } from './log/add_logs'
import { login } from './user/login'
import { register } from './user/register'
import { log_search } from './log/search_log_list'
import { log_info } from './log/log_info'
import { about } from './about/about'
import { base_info,base_info2 } from './cw/base_info'
import { base_info_1, base_info_2, base_info_3 } from './cw/cq_info'
import { MaidenheadLocator } from './cw/base_resource'
import { MorseCodeConverter } from './cw/MorseCodeConverter'
import { MorseMinimalPractice } from './cw/MorseMinimalPractice'

import {MorseTraining} from './cw/MorseTraining'

import { beian_web_page, private_cq_web_page, private_huawei_web_page, } from './about/Web_page'

import { sceneMap } from '@kit.MapKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { PromptAction } from '@kit.ArkUI'
let locationChoosingOptions: sceneMap.LocationChoosingOptions = {
  // 地图中心点坐标
  //location: { latitude: 39.92194051376904, longitude: 116.3971836796932 },
  language: 'cn',
  // 展示搜索控件
  searchEnabled: true,
  // 展示附近Poi
  showNearbyPoi: true
};


//初始化持久存储
PersistentStorage.persistProp('token', '');
PersistentStorage.persistProp('callsign', '');

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController()
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @Provide('index') index: NavPathStack = new NavPathStack()
  @StorageLink('token') token: string = ''
  @StorageLink('callsign') callsign: string = '';

  @State locator:string=''
  @State locationName:string=''

  @Builder
  PageMap(name: string) {
    if (name === "add_log") {
      add_log();
    } else if (name === "register") {
      register()
    } else if (name === "login") {
      login()
    }else if (name === "log_search") {
      log_search()
    }else if (name === "log_info") {
      log_info()
    }else if (name === "beian_web_page") {
      beian_web_page()
    }else if (name === "private_huawei_web_page") {
      private_huawei_web_page()
    }else if (name === "private_cq_web_page") {
      private_cq_web_page()
    }else if (name === "about") {
      about()
    }else if (name === "base_info") {
      base_info()
    }else if (name === "base_info2") {
      base_info2()
    }else if (name === "base_info_1") {
      base_info_1()
    }else if (name === "base_info_2") {
      base_info_2()
    }else if (name === "base_info_3") {
      base_info_3()
    }else if (name === "MorseCodeConverter") {
      MorseCodeConverter()
    }else if (name === "MorseMinimalPractice") {
      MorseMinimalPractice()
    }else if (name === "MorseTraining") {
      MorseTraining()
    }
  }


  build() {
    Navigation(this.index) {
      Column(){
        Tabs({ barPosition: BarPosition.End, controller: this.controller }){
          TabContent(){
            Column(){
              Divider().strokeWidth(5).color('#fff1f3f5')
              Row(){
                Text("当前时区时间：")
                  .fontSize(20)
                  .textAlign(TextAlign.Start)
                TextClock()
                  .format("yyyy年M月d日HH:mm:ss")
              }
              Divider().strokeWidth(5).color('#fff1f3f5')
              Row(){
                Text("当前UTC时间：")
                  .fontSize(20)
                  .textAlign(TextAlign.Start)
                TextClock({timeZoneOffset:0})
                  .format("yyyy年M月d日HH:mm:ss")
              }
              Divider().strokeWidth(5).color('#fff1f3f5')

              Text('当前用户呼号：'+this.callsign)
                .fontSize(20)
              Divider().strokeWidth(5).color('#fff1f3f5')
              Row({ space: 35 }){
                Image($r('app.media.quick_mark'))
                  .width(160)
                  .onClick(()=>{
                    this.index.pushPath({name:'add_log'})
                  })
                Image($r('app.media.some_mark'))
                  .width(160)
                  .onClick(()=>{
                    this.index.pushPath({name:'log_search'})
                  })
              }
            }
            .height("100%")
          }
          .height("100%")
          .tabBar("日志")


          TabContent(){
            Column({ space: 5 }){
              Divider().strokeWidth(5).color('#fff1f3f5')
              Text('基础知识')
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  this.index.pushPath({ name: 'base_info' })
                })
              Divider().strokeWidth(3).color('#fff1f3f5')
              Text('梅登海德网格定位系统(点我选点计算)')
                .borderRadius(15)
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  sceneMap.chooseLocation(getContext(this) as common.UIAbilityContext, locationChoosingOptions)
                    .then((data) => {
                      console.info("ChooseLocation", "Succeeded in choosing location.");
                      console.log(data.siteId)
                      console.log(data.name)
                      console.log(data.address)
                      console.log("long:" + String(data.location.longitude) + "lat:" + String(data.location.latitude))
                      console.log(data.addressComponent?.adminLevel5)
                      console.log(String(data.zoom))
                      const locator = new MaidenheadLocator(data.location.longitude, data.location.latitude);
                      this.locator=locator.toString()
                      this.locationName = data.name as string;
                    })
                    .catch((err: BusinessError) => {
                      console.error("ChooseLocation",
                        `Failed to choose location, code: ${err.code}, message: ${err.message}`);
                    });
                })
              if(this.locator!==''){
                Row(){
                  Text('选择的位置:')
                  Text(this.locationName)
                }
                Text('梅登海德网格定位结果:')
                Text(this.locator)
              }
              Divider().strokeWidth(2).color('#fff1f3f5')
              Text('摩尔斯电码工具及训练')
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  this.index.pushPath({ name: 'base_info2' })
                })
              Divider().strokeWidth(2).color('#fff1f3f5')
            }
            .height('100%')
            .width("90%")
          }
          .tabBar("工具")

          TabContent() {
            Column() {
              Divider().strokeWidth(5).color('#fff1f3f5')
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
                  Text(this.callsign)
                    .fontSize(30)
                    .margin({left:10})
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
                  this.callsign = '';
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