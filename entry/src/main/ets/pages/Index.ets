import { sceneMap } from '@kit.MapKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { LoadingDialog, PromptAction } from '@kit.ArkUI'

import { login, register } from './user/user_ctrl'

import { add_log } from './log/add_logs'
import { log_search } from './log/search_log_list'
import { log_info } from './log/log_info'

import { base_index1, base_index2, base_index3 } from './cw/base_info'
import { base_info_1, base_info_2, base_info_3 } from './cw/cq_info'
import { MaidenheadLocator } from './cw/base_resource'

import { MorseCodeConverter } from './cw/MorseCodeConverter'
import { MorseMinimalPractice } from './cw/MorseMinimalPractice'
import { MorseTraining } from './cw/MorseTraining'

import { Satellite_index } from './Satellite/Satellite_index'
import { SatelliteRadar } from './Satellite/Radar'
import { SatelliteService } from '../pages/http_server/SatelliteService'
import { satellite_db_control } from './Satellite/Satellite_db'

import { sstv_1 } from './cw/sstv/1'

import { beian_web_page, private_cq_web_page, private_huawei_web_page, } from './about/Web_page'
import { about } from './about/about'


let locationChoosingOptions: sceneMap.LocationChoosingOptions = {
  // 地图中心点坐标
  //location: { latitude: 39.92194051376904, longitude: 116.3971836796932 },
  language: 'cn',
  // 展示搜索控件
  searchEnabled: true,
  // 展示附近Poi
  showNearbyPoi: true
};

PersistentStorage.persistProp('token', '');
PersistentStorage.persistProp('callsign', '');
PersistentStorage.persistProp('selectedSatellites', []);
PersistentStorage.persistProp('total_satellite', 0);
PersistentStorage.persistProp('total_trans', 0);
PersistentStorage.persistProp('first_lunch', true);

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController()
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在下载中',
    }),
  })
  @Provide('index') index: NavPathStack = new NavPathStack()
  @StorageLink('token') token: string = ''
  @StorageLink('callsign') callsign: string = '';
  @StorageLink('total_satellite') total_satellite: number = 0
  @StorageLink('total_trans') total_trans: number = 0
  @State locator: string = ''
  @State locationName: string = ''

  onPageShow(): void {
    this.checkFirstLaunch()
  }
  async checkFirstLaunch() {
    try {
      if(AppStorage.get('first_lunch') ===true){
        AppStorage.setOrCreate('first_lunch',false);
        console.log("首次启动")
        this.promptAction.showToast({
          message: '首次启动会下载卫星数据，请稍等',
          duration: 2000
        })
      }
      await satellite_db_control.db_get_count(this.context)
        .then((total_satellite)=>{
          AppStorage.setOrCreate('total_satellite',total_satellite);
        })
      await satellite_db_control.db_get_transmitters_count(this.context)
        .then((total_trans)=>{
          AppStorage.setOrCreate('total_trans',total_trans);
        })
    } catch (err) {
    }
  }

  private async fetchSatelliteList() {
    try {
      // 1. 打开进度弹窗
      this.dialogControllerProgress.open();

      // 2. 并行下载数据（同时发起两个请求）
      console.log("开始下载卫星和收发器数据...");
      const results = await Promise.all([
        SatelliteService.get_transmitters(),
        SatelliteService.getSatelliteList()
      ]);

      // 3. 分别获取结果
      const res_trans = results[0];
      const res_sat = results[1];

      // 3. 先存储卫星数据
      console.log("存储卫星数据...");
      await satellite_db_control.db_put(this.context, res_sat.data);

      // 4. 获取并更新卫星数量
      const total_satellite = await satellite_db_control.db_get_count(this.context);
      AppStorage.setOrCreate('total_satellite', total_satellite);
      console.log("卫星数据下载完成，总数:", total_satellite);

      // 5. 存储收发器数据
      console.log("存储收发器数据...");
      await satellite_db_control.db_put_transmitters(this.context, res_trans.data);

      // 6. 获取并更新收发器数量
      const total_trans = await satellite_db_control.db_get_transmitters_count(this.context);
      AppStorage.setOrCreate('total_trans', total_trans);
      console.log("收发器数据下载完成，总数:", total_trans);

      // 7. 所有操作完成后关闭弹窗
      this.dialogControllerProgress.close();

      // 8. 显示成功提示
      this.promptAction.showToast({message:`数据更新成功！卫星: ${total_satellite} 颗，收发器: ${total_trans} 个`})

    } catch (error) {
      // 9. 统一错误处理
      console.error("数据下载失败:", error);
      this.dialogControllerProgress.close(); // 确保弹窗关闭
      this.promptAction.showToast({message:"数据下载失败，请检查网络连接"})

    }
  }

  private async db_clear_all(){
    await satellite_db_control.db_clear_all(this.context)
    this.total_satellite = await satellite_db_control.db_get_count(this.context);
    this.total_trans = await satellite_db_control.db_get_transmitters_count(this.context);
  }
  @Builder
  PageMap(name: string) {
    if (name === "add_log") {
      add_log();
    } else if (name === "register") {
      register()
    } else if (name === "login") {
      login()
    } else if (name === "log_search") {
      log_search()
    } else if (name === "log_info") {
      log_info()
    } else if (name === "beian_web_page") {
      beian_web_page()
    } else if (name === "private_huawei_web_page") {
      private_huawei_web_page()
    } else if (name === "private_cq_web_page") {
      private_cq_web_page()
    } else if (name === "about") {
      about()
    } else if (name === "base_index1") {
      base_index1()
    } else if (name === "base_index2") {
      base_index2()
    } else if (name === "base_index3") {
      base_index3()
    } else if (name === "base_info_1") {
      base_info_1()
    } else if (name === "base_info_2") {
      base_info_2()
    } else if (name === "base_info_3") {
      base_info_3()
    } else if (name === "MorseCodeConverter") {
      MorseCodeConverter()
    } else if (name === "MorseMinimalPractice") {
      MorseMinimalPractice()
    } else if (name === "MorseTraining") {
      MorseTraining()
    } else if (name === "sstv_1") {
      sstv_1()
    } else if (name === "Satellite_index") {
      Satellite_index()
    } else if (name === "SatelliteRadar") {
      SatelliteRadar()
    }
  }

  build() {
    Navigation(this.index) {
      Column() {
        Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
          TabContent() {
            Column() {
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))

              Text("当前时区时间：")
                .fontSize(20)
              TextClock()
                .fontSize(20)
                .format("yyyy年M月d日HH:mm:ss")

              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))

              Text("当前UTC时间：")
                .fontSize(20)
              TextClock({ timeZoneOffset: 0 })
                .fontSize(20)
                .format("yyyy年M月d日HH:mm:ss")

              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              Row({ space: 35 }) {
                Image($r('app.media.quick_mark'))
                  .width(160)
                  .onClick(() => {
                    this.index.pushPath({ name: 'add_log' })
                  })
                Image($r('app.media.some_mark'))
                  .width(160)
                  .onClick(() => {
                    this.index.pushPath({ name: 'log_search' })
                  })
              }

              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              Row({ space: 35 }) {
                Image($r('app.media.sos'))
                  .width(160)
                  .onClick(() => {
                    try {
                      this.promptAction.showDialog({
                        title: '注意',
                        message: '你可以前往页面在输入框输入SOS，并点击闪光灯模式，即可同时播放音频和调用闪光灯进行闪烁',
                        buttons: [
                          {
                            text: '确认',
                            color: $r('sys.color.font_primary')
                          }
                        ]
                      }, (err, data) => {
                        if (err) {
                          console.error('showDialog err: ' + err);
                          return;
                        }
                        console.info('showDialog success callback, click button: ' + data.index);
                        if (data.index === 0) {
                          this.index.pushPath({ name: 'MorseCodeConverter' })
                        }
                      });
                    } catch (error) {
                      let message = (error as BusinessError).message;
                      let code = (error as BusinessError).code;
                      console.error(`showDialog args error code is ${code}, message is ${message}`);
                    }
                  })

                Image($r('app.media.sate'))
                  .width(160)
                  .onClick(() => {
                    this.index.pushPath({ name: 'Satellite_index' })
                  })
              }
            }
            .height("100%")
          }
          .height("100%")
          .tabBar("首页")

          TabContent() {
            Column({ space: 5 }) {
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              Text('基础知识')
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  this.index.pushPath({ name: 'base_index1' })
                })
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              Text('梅登海德网格定位系统(点我选点计算)')
                .borderRadius(15)
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  sceneMap.chooseLocation(this.context, locationChoosingOptions)
                    .then((data) => {
                      console.info("ChooseLocation", "Succeeded in choosing location.");
                      console.log(data.siteId)
                      console.log(data.name)
                      console.log(data.address)
                      console.log("long:" + String(data.location.longitude) + "lat:" + String(data.location.latitude))
                      console.log(data.addressComponent?.adminLevel5)
                      console.log(String(data.zoom))
                      const locator = new MaidenheadLocator(data.location.longitude, data.location.latitude);
                      this.locator = locator.toString()
                      this.locationName = data.name as string;
                    })
                    .catch((err: BusinessError) => {
                      console.error("ChooseLocation",
                        `Failed to choose location, code: ${err.code}, message: ${err.message}`);
                    });
                })
              if (this.locator !== '') {
                Row() {
                  Text('选择的位置:')
                  Text(this.locationName)
                }

                Text('梅登海德网格定位结果:')
                Text(this.locator)
              }
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              Text('摩尔斯电码工具及训练')
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  this.index.pushPath({ name: 'base_index2' })
                })
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              Text('SSTV(慢扫描电视)工具')
                .width('100%')
                .height(50)
                .fontSize(20)
                .onClick(() => {
                  this.index.pushPath({ name: 'base_index3' })
                })
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
            }
            .height('100%')
            .width("90%")
          }
          .tabBar("工具")

          TabContent() {
            Column() {
              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
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
                    .margin({ left: 10 })
                }
              }
              .onClick(() => {
                if (this.token === '') {
                  this.index.pushPath({ name: 'login' })
                }
              })

              Divider().strokeWidth(3).color($r('sys.color.background_fourth'))
              //其他行信息
              Column() {
                Row() {
                  Text('当前版本：1.0.15')
                    .fontSize(20)
                    .margin(15)
                }
                .height(50)
                .borderRadius(15)
                .backgroundColor($r('sys.color.comp_background_primary'))
                .width('100%')

                Divider().strokeWidth(2).color($r('sys.color.background_fourth'))
                Row() {
                  Text('ICP备案：' + '宁ICP备2025009768号-2A')
                    .fontSize(15)
                    .margin(15)
                }
                .height(50)
                .borderRadius(15)
                .backgroundColor($r('sys.color.comp_background_primary'))
                .width('100%')
                .onClick(() => {
                  this.index.pushPath({ name: 'beian_web_page' })
                })

                Divider().strokeWidth(2).color($r('sys.color.background_fourth'))
                Row() {
                  Text('退出登录')
                    .fontSize(20)
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
                .backgroundColor($r('sys.color.comp_background_primary'))
                .width('100%')

                Divider().strokeWidth(2).color($r('sys.color.background_fourth'))
                Column() {
                  Text("卫星数据管理")
                    .fontSize(22)
                  Row(){
                    Text('存储的卫星数量：' + String(this.total_satellite)+" " )
                      .fontSize(16)
                    Text('存储的收发器数量：' + String(this.total_trans) )
                      .fontSize(16)
                  }
                  Button("重新拉取数据")
                    .onClick(() => {
                      this.promptAction.showDialog({
                        title: '重新拉取数据',
                        message:"确认？这将会清空本地已经下载的数据并重新下载，请确保链接到网络",
                        buttons: [
                          {
                            text: '确认',
                            color: '#000000'
                          },
                          {
                            text: '取消',
                            color: '#000000'
                          }
                        ]
                      }, (err, data) => {
                        if (err) {
                          console.error('showDialog err: ' + err);
                          return;
                        }
                        if(data.index===0){
                          this.db_clear_all()
                          this.fetchSatelliteList()
                        }
                        console.info('showDialog success callback, click button: ' + data.index);
                      })

                    })
                }
                .borderRadius(15)
                .backgroundColor($r('sys.color.comp_background_primary'))
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