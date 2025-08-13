import { Request,res_user,user_data,user,tx_log,rx_log,log_message,res_add_log,res_log_list_data,res_log_list,res_once_log,log_delete_res,
  http_id,http_log_add,http_list_logs,http_once_logs,http_logs_manage } from '../http_server/httpService';
import { promptAction } from '@kit.ArkUI';
import { sceneMap } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { LoadingDialog } from '@kit.ArkUI'
import { PromptAction } from '@kit.ArkUI';

//单文件项目标识add_logs
//完成



let locationChoosingOptions: sceneMap.LocationChoosingOptions = {
  // 地图中心点坐标
  //location: { latitude: 39.92194051376904, longitude: 116.3971836796932 },
  language: 'cn',
  // 展示搜索控件
  searchEnabled: true,
  // 展示附近Poi
  showNearbyPoi: true
};

@Component
export struct add_log {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在提交中',
    }),
  })
  @Consume('index') index: NavPathStack;
  @State log_date:string='';
  @State log_time:string='';
  @State frequency:number=0;
  @State other_username:string='';
  @State rx_report:number=0;
  @State tx_report:number=0;
  @State summary:string='';

  @State hours:string='';
  @State minute:string='';
  @State second:string='';

  @StorageProp('token') token: string = '';

  async http_add_log_request( token: string) {
    try {
      const tx_log: tx_log = {
        log_date: this.log_date,
        log_time: this.hours+":"+this.minute+":"+this.second,
        frequency: this.frequency,
        other_username: this.other_username,
        rx_report: this.rx_report,
        tx_report: this.tx_report,
        summary: this.summary
      };
      console.log(String(tx_log))
      const response =
        await http_log_add.httpRequest(tx_log, token);


      setTimeout(() => {
        this.dialogControllerProgress.close()
        if (response.success === true) {
          this.index.pop()
        }
      }, 500);

    } catch (error) {
    }
  }

  build() {
    NavDestination() {
        Column({ space: 25 }) {
          Row() {
            Text('选择日期：')
              .fontSize(18)
            Button("选择日期")
              .onClick(()=>{
                console.info("CalendarDialog.show")
                CalendarPickerDialog.show({
                  onAccept:(date:Date)=>{
                    const year = date.getFullYear();
                    const month = ("0" + (date.getMonth() + 1)).slice(-2); // 月份从0开始，需要加1并补0
                    const day = ("0" + date.getDate()).slice(-2); // 日期补0
                    console.log("获取的时间："+year+"-"+month+"-"+day)

                    this.log_date=String(year)+"-"+String(month)+"-"+String(day)
                  }
                }
                )
              })
          }

          Row() {
            Text('已经选择的日期：')
              .fontSize(18)
            Text(this.log_date)
              .fontSize(18)
          }

          Column(){
            Text('详细时间：(24小时制)')
              .fontSize(18)
            Row(){
              TextInput({ placeholder: '时(24小时制)' })
                .width("20%")
                .type(InputType.Number)
                .onChange((hours_get: string) => {
                  const hours = ("0" + hours_get).slice(-2);
                  if (Number(hours)>24 || Number(hours)<0){
                    this.promptAction.showToast({
                      message: "时间越界",
                      duration: 2000
                    })
                  }else{
                    this.hours=hours
                  }
                  console.log("获取到的时："+this.hours)
                });

              Text('时')
                .fontSize(18)

              TextInput({ placeholder: '分' })
                .width("20%")
                .type(InputType.Number)
                .onChange((minute_get: string) => {
                  const minute = ("0" + minute_get).slice(-2);
                  if (Number(minute)>60 || Number(minute)<0){
                    this.promptAction.showToast({
                      message: "时间越界",
                      duration: 2000
                    })
                  }else{
                    this.minute=minute
                  }
                  console.log("获取到的分："+this.minute)
                });

              Text('分')
                .fontSize(18)

              TextInput({ placeholder: '秒' })
                .width("20%")
                .type(InputType.Number)
                .onChange((second_get: string) => {
                  const second = ("0" + second_get).slice(-2);
                  if (Number(second)>60 || Number(second)<0){
                    this.promptAction.showToast({
                      message: "时间越界",
                      duration: 2000
                    })
                  }else{
                    this.second=second
                  }
                  console.log("获取到的秒："+this.second)
                });

              Text('秒')
                .fontSize(18)
            }
          }

          Row() {
            Text('频率：')
              .fontSize(18)
            TextInput({ placeholder: '请输入频率' })
              .type(InputType.NUMBER_DECIMAL)
              .onChange((frequency: string) => {
                this.frequency=Number(frequency)
              });
            Text('MHz')
              .fontSize(18)
          }
          .width('50%')

          Row() {
            Text('对方呼号：')
              .fontSize(18)
            TextInput({ placeholder: '请输入对方呼号' })
              .type(InputType.Normal)
              .onChange((other_username: string) => {
                this.other_username=other_username
              });
          }
          .width('50%')

          Row() {
            Column(){
              Text('信号报告：')
                .fontSize(18)
            }
            Column(){
              TextInput({ placeholder: '收方信号报告' })
                .type(InputType.Number)
                .onChange((rx_report: string) => {
                  this.rx_report=Number(rx_report)
                });

              TextInput({ placeholder: '发方信号报告' })
                .type(InputType.Number)
                .onChange((tx_report: string) => {
                  this.tx_report=Number(tx_report)
                });
            }

          }
          .width('50%')

          Row() {
            Text('备注：')
              .fontSize(18)
            TextArea({ placeholder: '请输入备注' })
              .onChange((summary: string) => {
                this.summary=summary
              });
          }
          .width('50%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('90%')

      Column() {
        Row() {
          Button('提交')
            .width(150)
            .onClick(() => {
              if (this.token === '') {
                this.promptAction.showToast({
                  message: "用户未登录",
                  duration: 2000
                })
              } else {
                this.http_add_log_request(this.token);
                this.dialogControllerProgress.open()
              }
            })
        }
      }
      .margin({top:25})
      .alignItems(HorizontalAlign.Center)



          // Row() {
          //   Button('选择地点')
          //     .width(150)
          //     .onClick(() => {
          //       sceneMap.chooseLocation(getContext(this) as common.UIAbilityContext, locationChoosingOptions)
          //         .then((data) => {
          //           console.info("ChooseLocation", "Succeeded in choosing location.");
          //           console.log(data.siteId)
          //           console.log(data.name)
          //           console.log(data.address)
          //           console.log("long:" + String(data.location.longitude) + "lat:" + String(data.location.latitude))
          //           console.log(data.addressComponent?.adminLevel5)
          //           console.log(String(data.zoom))
          //         })
          //         .catch((err: BusinessError) => {
          //           console.error("ChooseLocation",
          //             `Failed to choose location, code: ${err.code}, message: ${err.message}`);
          //         });
          //     })
          // }
          // .justifyContent(FlexAlign.Start)
    }
    .title('日志创建')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}