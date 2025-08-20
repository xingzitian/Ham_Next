import { http_once_logs, res_once_log } from '../http_server/httpService';

import { LoadingDialog } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';


@Component
export struct log_info {
  context = getContext(this) as common.UIAbilityContext;
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '操作中',
    }),
  })
  //以下需要调用其他组件
  @Consume('index') index: NavPathStack;
  @StorageProp('token') token: string = '';

  @StorageLink('log_code') log_code: number = 0;
  @State log_info: res_once_log = {
    success: true,
    message: '',
    data: {
      id: 0,
      contactCallsign: '',
      timestamp: '',
      frequency: 0,
      mode: '',
      sentReport:'',
      receivedReport: '',
      notes: '',
      user_id: 0,
      createdAt: '',
      updatedAt:'',

    }
  }


  aboutToAppear(): void {
    this.http_get_log_info(String(this.log_code),this.token);
  }

  async http_get_log_info(log_id: string,token:string) {
    try {
      const response: res_once_log = await http_once_logs.httpRequest(log_id,token);
      console.log("http_once_logs" + response.message)
      this.log_info=response


      // this.petalMapWant.parameters = {
      //   linkSource: 'com.dada.xingzitian',
      //   destinationLatitude: this.latitude,
      //   destinationLongitude: this.longitude,
      //   destinationName: this.locationName,
      // }
    } catch (error) {
      this.index.pop()
      console.error('Error occurred during request:', error);
    }
  }


  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Text('日志时间(UTC时间)：'+this.log_info.data.timestamp)
          .borderRadius(15)
          .backgroundColor('#ffffffff')
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('模式：'+this.log_info.data.mode)
          .borderRadius(15)
          .backgroundColor('#ffffffff')
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('频率：'+this.log_info.data.frequency+'MHz')
          .borderRadius(15)
          .backgroundColor('#ffffffff')
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('对方呼号：'+this.log_info.data.contactCallsign)
          .borderRadius(15)
          .backgroundColor('#ffffffff')
          .width('100%')
          .height(50)
          .fontSize(20)
        Text('信号报告：')
          .fontSize(20)
        Row() {
          Text('收方：' + this.log_info.data.receivedReport)
            .fontSize(20)
          Text('收方：' + this.log_info.data.sentReport)
            .fontSize(20)
        }
        .borderRadius(15)
        .backgroundColor('#ffffffff')
        .width('100%')
        .height(50)
        Text('备注：')
          .fontSize(20)
        Text(this.log_info.data.notes)
          .borderRadius(15)
          .backgroundColor('#ffffffff')
          .width('100%')
          .height(50)
          .fontSize(20)

      }
      .alignItems(HorizontalAlign.Start)
      .width('90%')
    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('日志详情')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}