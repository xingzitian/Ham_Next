import { http_once_logs, res_once_log } from '../http_server/httpService';

import { PromptAction } from '@kit.ArkUI';

@Component
export struct log_info {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  //以下需要调用其他组件
  @Consume('index') index: NavPathStack;
  @StorageProp('token') token: string = '';
  @StorageLink('log_code') log_code: number = 0;
  @State log_info: res_once_log = {
    success: true,
    message: '',
    code: 0,
    data: {
      id: 0,
      contactCallsign: '',
      date: '',
      frequency: 0,
      mode: '',
      sentReport: '',
      receivedReport: '',
      description: '',
    }
  }

  aboutToAppear(): void {
    this.http_get_log_info(String(this.log_code), this.token);
  }

  async http_get_log_info(log_id: string, token: string) {
    try {
      const response: res_once_log = await http_once_logs.httpRequest(log_id, token);
      console.log("http_once_logs" + response.message)
      this.log_info = response
      // this.petalMapWant.parameters = {
      //   linkSource: 'com.dada.xingzitian',
      //   destinationLatitude: this.latitude,
      //   destinationLongitude: this.longitude,
      //   destinationName: this.locationName,
      // }
    } catch (error) {
      this.promptAction.showToast({
        message: '进入失败',
        duration: 2000
      })
      this.index.pop()

      console.error('Error occurred during request:', error);
    }
  }

  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Column() {
          Text('日志时间(UTC时间)：')
            .fontSize(20)
          Text(this.log_info.data.date)
            .fontSize(20)
        }
        .borderRadius(15)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .width('100%')
        .height(50)

        Text('模式：' + this.log_info.data.mode)
          .borderRadius(15)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('频率：' + this.log_info.data.frequency + 'MHz')
          .borderRadius(15)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('对方呼号：' + this.log_info.data.contactCallsign)
          .borderRadius(15)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('信号报告：' + '收方：' + this.log_info.data.receivedReport + '发方：' + this.log_info.data.sentReport)
          .borderRadius(15)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .width('100%')
          .height(50)
          .fontSize(20)
        Column() {
          Text('备注：')
            .fontSize(20)
          Text(this.log_info.data.description)
            .fontSize(20)
        }
        .borderRadius(15)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .width('100%')
        .height(50)
        .alignItems(HorizontalAlign.Start)

      }
      .alignItems(HorizontalAlign.Start)
      .width('90%')
    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('日志详情')
    .onBackPressed(() => {
      this.index.pop()
      return true
    })
  }
}