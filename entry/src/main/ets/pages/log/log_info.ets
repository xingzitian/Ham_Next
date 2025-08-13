import { Request,res_user,user_data,user,tx_log,rx_log,log_message,res_add_log,res_log_list_data,res_log_list,res_once_log,log_delete_res,
  http_id,http_log_add,http_list_logs,http_once_logs,http_logs_manage } from '../http_server/httpService';
import { http_admin_teams_change } from '../http_server/http_admin'
import { LoadingDialog } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit';


@Component
export struct team_info {
  context = getContext(this) as common.UIAbilityContext;
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '操作中',
    }),
  })
  @State team_info: Array<rx_log> = [];
  //以下需要调用其他组件
  @Consume('index') index: NavPathStack;

  @State log_id:number=0;
  @State log_date:string='';
  @State log_time:string='';
  @State frequency:number=0;
  @State other_username:string='';
  @State rx_report:number=0;
  @State tx_report:number=0;
  @State summary:string='';
@State user_id:number=0;

  @State petalMapWant: Want = {
    bundleName: 'com.huawei.hmos.maps.app',
    uri: 'maps://routes',
  }

  aboutToAppear(): void {
    // this.http_get_log_info(String(this.log_id),this.token);
  }

  async http_get_log_info(log_id: string,token:string) {
    try {
      const response: Array<res_once_log> = await http_once_logs.httpRequest(log_id,token);
      console.log("team_info_get_resoly" + response[0].message)

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


    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('日志详情')
  }
}