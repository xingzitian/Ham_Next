import { res_user,user_data,tx_log,rx_log,res_add_log,res_log_list,res_once_log,
  http_id,http_log_add,http_list_logs,http_once_logs, } from '../http_server/httpService';

@Component
export struct log_search {
  @State log_list: res_log_list = {
    success: true,
    message: '',
    data: {
      logs: [{
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
      }],
      pagination:{
        currentPage: 0,
        totalPages: 0,
        totalCount: 0,
        hasNext: true,
        hasPrev: true
      }
    }
  }
  @State search: string = ''
  @Consume('index') index: NavPathStack;
  @StorageLink('log_code') log_code: number = 0;
  @State min_frequency: number = 0
  @State max_frequency: number = 0
  @State log_date: string = '';
  @State other_username: string = '';

  async http_log_search(date: string, page: number, token: string, other_username?: string, min_frequency?: number,
    max_frequency?: number) {
    try {
      this.log_list = {
        success: true,
        message: '',
        data: {
          logs: [{
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
          }],
          pagination:{
            currentPage: 0,
            totalPages: 0,
            totalCount: 0,
            hasNext: true,
            hasPrev: true
          }
        }
      }
      const response =
        await http_list_logs.httpRequest(date, page, token, other_username, min_frequency, max_frequency);
      this.log_list = response
    } catch (error) {
      console.error('Error occurred during request:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          Row() {
            Image($r('app.media.ic_search'))
              .width(20)
              .height(20)
              .objectFit(ImageFit.Contain)
              .margin({ left: 11 })

            TextInput({ placeholder: '输入想要搜索的对方呼号或简单筛选即可' })
              .width('70%')
              .fontSize(16)
              .lineHeight(21)
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi')
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .margin({ left: 6 })
              .backgroundColor('#ffe5e5ea')
              .onChange((other_username: string) => {
                this.other_username = other_username;
              });
            Button('搜索/筛选', { type: ButtonType.Capsule, stateEffect: true })
              .onClick(() => {
                this.log_list
              })
          }
          .borderRadius(20)
          .backgroundColor('#ffe5e5ea')
          .height(40)
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Button("选择日期")
              .onClick(() => {
                console.info("CalendarDialog.show")
                CalendarPickerDialog.show({
                  onAccept: (date: Date) => {
                    const year = date.getFullYear();
                    const month = ("0" + (date.getMonth() + 1)).slice(-2); // 月份从0开始，需要加1并补0
                    const day = ("0" + date.getDate()).slice(-2); // 日期补0
                    console.log("获取的时间：" + year + "-" + month + "-" + day)

                    this.log_date = String(year) + "-" + String(month) + "-" + String(day)
                  }
                }
                )
              })
              .width('50%')
            TextInput({ placeholder: "频率下限(可选)" })
              .onChange((min_frequency: string) => {
                this.min_frequency = Number(min_frequency)
              })
            Text("-")
            TextInput({ placeholder: "频率上限(可选)" })
              .onChange((max_frequency: string) => {
                this.max_frequency = Number(max_frequency)
              })

          }
        }

        List({ space: 20 }) {
          ForEach(this.log_list.data.logs, (item: rx_log) => {
            ListItem() {
              Column() {
                Text(item.timestamp)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Start)
              }
              .width('90%')
              .alignItems(HorizontalAlign.Start)
            }
            .onClick(() => {
              this.index.pushPath({ name: 'team_info' })
              // this.log_code = item.log_id
            })
          })
        }
        .height('100%')
      }
      .backgroundColor('#fff1f3f5')
      .width('80%')
    }
    .title('日志检索')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}