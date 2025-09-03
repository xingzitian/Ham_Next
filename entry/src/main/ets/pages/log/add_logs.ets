import { http_log_add, tx_log } from '../http_server/httpService';
import { sceneMap } from '@kit.MapKit';
import { LoadingDialog, promptAction, PromptAction } from '@kit.ArkUI';
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

  private fruits: TextCascadePickerRangeContent[] = [
    {
      text: '语音模式',
      children: [{ text: 'SSB' },{ text: 'FM' },{ text: 'AM' },{ text: 'FSK' }]
    },    {
    text: 'CW'
  },    {
    text: '数字模式',
    children: [{ text: 'FT8' },{ text: 'RTTY' },{ text: 'APRS' }]
  },
    {
      text: '图像模式',
      children: [{ text: 'SSTV' }]
    },
  ];
  private select : number  = 0;

  @Consume('index') index: NavPathStack;
  @StorageProp('token') token: string = '';
  @State timestamp:string='';
  @State frequency:number=0;
  @State contactCallsign:string='';
  @State receivedReport:string='';
  @State sentReport:string='';
  @State notes:string='';
  @State mode :string=''

  @State mode_0:string='模式选择'

  @State hours:string='';
  @State minute:string='';




  async http_add_log_request( token: string) {
    try {
      const tx_log: tx_log = {
        contactCallsign: this.contactCallsign,
        timestamp: this.timestamp, // ISO 8601 格式的日期字符串
        frequency: this.frequency,
        mode: this.mode,
        sentReport: this.sentReport,
        receivedReport:this.receivedReport,
        notes: this.notes // 可选字段
      };
      console.log(String(tx_log))
      const response =
        await http_log_add.httpRequest(tx_log, token);
      setTimeout(() => {
        this.dialogControllerProgress.close()
      }, 500);
      if (response.success === true) {
        this.promptAction.showToast({
          message:'提交成功'
        });
        this.index.pop()
      }

    } catch (error) {
      setTimeout(() => {
        this.dialogControllerProgress.close()
      }, 500);
      if(error===400){
        this.promptAction.showToast({
          message:'参数提交不完整，请重新提交'
        });
      }
    }
  }

  build() {
    NavDestination() {
      Column({ space: 25 }) {
        Row(){
          Button('选择日期')
            .width('40%')
            .margin(15)
            .onClick(() => {
              this.getUIContext().showDatePickerDialog({
                start: new Date("2000-1-1"),
                end: new Date("2100-12-31"),
                showTime: true,
                useMilitaryTime:true,
                onDateAccept: (date: Date) => {
                  const year = date.getFullYear();
                  const month = ("0" + (date.getMonth() + 1)).slice(-2); // 月份从0开始，需要加1并补0
                  const day = ("0" + date.getDate()).slice(-2); // 日期补0
                  console.log("获取的时间："+year+"-"+month+"-"+day)
                  console.log("获取的时间1："+date.getTime())
                  console.log("获取的时间2："+date.toISOString())
                  console.log("获取的时间3："+date.toUTCString())
                  this.timestamp=date.toISOString()

                },
              });
            })

          Button(this.mode_0+this.mode)
            .margin(15)
            .width('40%')
            .onClick(() => {
              this.getUIContext().showTextPickerDialog({
                range: this.fruits,
                selected: this.select,
                onAccept: (value: TextPickerResult) => {
                  this.select = value.index as number
                  console.log("选择的模式："+value.value)
                  this.mode_0=value.value[0]
                  this.mode=value.value[1]
                }
              });
            })
        }
        .width('100%')

        Column(){
          Text('已经选择的日期(UTC时间)：')
            .fontSize(18)
          if(this.timestamp!==''){
            Text(this.timestamp)
              .fontSize(18)
          }
        }
        .width('100%')
        .backgroundColor($r('sys.color.background_tertiary'))

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
            .onChange((contactCallsign: string) => {
              this.contactCallsign=contactCallsign
            });
        }
        .width('50%')

        Row() {
          Column(){
            Text('信号报告：')
              .fontSize(18)
          }
          TextInput({ placeholder: '收方' })
            .width('30%')
            .type(InputType.Number)
            .onChange((receivedReport: string) => {
              this.receivedReport=receivedReport
            });

          TextInput({ placeholder: '发方' })
            .width('30%')
            .type(InputType.Number)
            .onChange((sentReport: string) => {
              this.sentReport=sentReport
            });
        }
        .width('100%')

        Row() {
          Text('备注：')
            .fontSize(18)
          TextArea({ placeholder: '请输入备注' })
            .onChange((notes: string) => {
              this.notes=notes
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