import { http_list_logs, res_log_list, rx_log } from '../http_server/httpService';
import { UIPagination } from '@hw-agconnect/ui-pagination';
import { PromptAction } from '@kit.ArkUI';
@Component
export struct log_search {

  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

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
  @Consume('index') index: NavPathStack;
  @StorageProp('token') token: string = '';
  @StorageLink('log_code') log_code: number = 0;
  @State minFrequency: number = -1
  @State maxFrequency: number = -1
  @State start_page: number = 1
  @State date: string = '获取时间';
  @State mode: string = '选择模式';
  @State contactCallsign: string = '';

  @State total:number=0
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

  aboutToAppear(): void {
    this.http_log_search(0,this.start_page,this.token);
  }

  async http_log_search(use:number,page:number, token: string,date?:string,mode?:string,contactCallsign?:string,minFrequency?:number,maxFrequency?:number) {
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

      let extar:string=''
      if (date!=='获取时间'){
        extar=extar+'&date='+date
      }
      if (mode!=='选择模式'){
        extar=extar+'&mode='+mode
      }
      if (minFrequency!==-1){
        extar=extar+'&minFrequency='+minFrequency
      }
      if (maxFrequency!==-1){
        extar=extar+'&maxFrequency='+maxFrequency
      }
      if (contactCallsign!==''){
        extar=extar+'&contactCallsign='+contactCallsign
      }
      console.log("查询请求时的页码："+page)
      console.log("查询请求时的url："+extar)
      const response =
        await http_list_logs.httpRequest(use,page, token,extar);
      this.log_list = response
      this.total=this.log_list.data.pagination.totalCount

      this.promptAction.showToast({
        message: '查询成功，共计'+this.total+"条",
        duration: 2000
      })

    } catch (error) {
      console.error('Error occurred during request:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        Column({ space: 6 }) {
          TextInput({ placeholder: '输入对方呼号或选择简单筛选' })
            .borderRadius(20)
            .backgroundColor('#ffe5e5ea')
            .height(50)
            .width('90%')
            .fontSize(16)
            .onChange((contactCallsign: string) => {
              this.contactCallsign = contactCallsign;
            });

          Row() {
            Button(this.date)
              .margin(8)
              .width('40%')
              .onClick(() => {
                CalendarPickerDialog.show({
                  onAccept: (date: Date) => {
                    const year = date.getFullYear();
                    const month = ("0" + (date.getMonth() + 1)).slice(-2); // 月份从0开始，需要加1并补0
                    const day = ("0" + date.getDate()).slice(-2); // 日期补0
                    console.log("搜索页面获取的时间：" + year + "-" + month + "-" + day)
                    this.date = String(year) + "-" + String(month) + "-" + String(day)
                  }
                })
              })

            Button(this.mode)
              .margin(8)
              .width('40%')
              .onClick(() => {
                this.getUIContext().showTextPickerDialog({
                  range: this.fruits,
                  selected: this.select,
                  onAccept: (value: TextPickerResult) => {
                    this.select = value.index as number
                    console.log("选择的模式：" + value.value)
                    this.mode = value.value[1]
                  }
                });
              })
          }

          Row() {
            TextInput({ placeholder: "频率下限" })
              .backgroundColor('#ffe5e5ea')
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .margin(8)
              .width('40%')
              .onChange((minFrequency: string) => {
                this.minFrequency = Number(minFrequency)
              })

            TextInput({ placeholder: "频率上限" })
              .backgroundColor('#ffe5e5ea')
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .margin(8)
              .width('40%')
              .onChange((maxFrequency: string) => {
                this.maxFrequency = Number(maxFrequency)
              })
          }

          Row() {
            Button("清空条件")
              .width('40%')
              .margin(8)
              .onClick(() => {
                this.date = '获取时间';
                this.mode = '选择模式';
                this.start_page=1
                this.minFrequency=-1
                this.maxFrequency=-1
                this.contactCallsign=''
                this.http_log_search(0,this.start_page,this.token);
              })

            Button("搜索")
              .width('40%')
              .margin(8)
              .onClick(() => {
                this.http_log_search(1, this.start_page, this.token, this.date, this.mode, this.contactCallsign,
                  this.minFrequency, this.maxFrequency)
              })
          }

          List({ space: 10 }) {
            ForEach(this.log_list.data.logs, (item: rx_log) => {
              ListItem() {
                Column() {
                  Text(item.timestamp)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .textAlign(TextAlign.Start)
                  Row() {
                    Text('模式' + item.mode)
                      .width("40%")
                    Text('频率' + String(item.frequency) + 'Mhz')
                      .width("40%")
                  }

                }
                .alignItems(HorizontalAlign.Start)
              }
              .borderRadius(10)
              .backgroundColor('#ffe5e5ea')
              .height(50)
              .width('90%')
              .onClick(() => {
                this.index.pushPath({ name: 'log_info' })
                this.log_code = item.id
              })
            })
          }
        }
        .height("92%")

        UIPagination({
          currentPage: this.start_page,
          total:this.total ,
          pageSize:5,
          change: (currentV: number) => {
            this.start_page = currentV;
            this.http_log_search(1, this.start_page, this.token, this.date, this.mode, this.contactCallsign,this.minFrequency, this.maxFrequency)
            console.log("页面切换")
          }
        })
        // Row(){
        //   Column(){
        //     Text('总计'+this.log_list.data.pagination.totalCount+'条')
        //     Text('总计'+this.log_list.data.pagination.totalPages+'页')
        //   }
        //   .width('50%')
        //
        //   Button({ type: ButtonType.Circle, stateEffect: true }){
        //     Image($r('app.media.chevron_left')).width(25).height(25)
        //   }.height(50).width(50)
        //   .onClick(()=>{
        //     if(this.log_list.data.pagination.hasPrev===true){
        //       console.log("成功跳转到上一页")
        //       this.start_page=this.start_page-1
        //       this.http_log_search(1, this.start_page, this.token, this.date, this.mode, this.contactCallsign,this.minFrequency, this.maxFrequency)
        //     }else{
        //       console.log("没有上一页了")
        //     }
        //   })
        //
        //   Text(String(this.log_list.data.pagination.currentPage)+'/'+String(this.log_list.data.pagination.totalPages))
        //     .fontSize(25)
        //
        //   Button({ type: ButtonType.Circle, stateEffect: true }){
        //     Image($r('app.media.chevron_right')).width(25).height(25)
        //   }.height(50).width(50)
        //   .onClick(()=>{
        //     if(this.log_list.data.pagination.hasNext===true){
        //       console.log("成功跳转到下一页")
        //       this.start_page=this.start_page+1
        //       this.http_log_search(1, this.start_page, this.token, this.date, this.mode, this.contactCallsign,this.minFrequency, this.maxFrequency)
        //     }else{
        //       console.log("没有上一页了")
        //     }
        //   })
        // }
        // .justifyContent(FlexAlign.Start)
      }
      .width('90%')
    }
    .height('100%')
    .title('日志检索(条件可选)')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}