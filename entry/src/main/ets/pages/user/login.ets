import { Request,res_user,user_data,user,tx_log,rx_log,log_message,res_add_log,res_log_list_data,res_log_list,res_once_log,log_delete_res,
  http_id,http_get_id,res_user_id,http_log_add,http_list_logs,http_once_logs,http_logs_manage } from '../http_server/httpService';

import { LoadingDialog } from '@kit.ArkUI'
import { PromptAction } from '@kit.ArkUI';

//单文件项目标识login
//完成



@Component
export struct login {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在提交中',
    }),
  })
  @Consume('index') index: NavPathStack;
  @State phone:string='';
  @State pass_num:string='';


  @StorageLink('token') token: string = '';
  @StorageLink('username') username: string = '';
  async http_login_request() {
    try {
      const response =
        await http_id.httpRequest(2,this.phone,this.pass_num);

      setTimeout(() => {
        if (response.success === true) {
          this.token=response.data.token
          this.http_get_username_request(this.token)
        }
      }, 500);

    } catch (error) {
    }
  }

  async http_get_username_request(token:string) {
    try {
      const response =
        await http_get_id.httpRequest(token);

      setTimeout(() => {
        this.dialogControllerProgress.close()
        if (response.success === true) {
          console.log("获取到的呼号："+response.data.user.username)
          this.username=response.data.user.username
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
          Text('请输入手机号：')
            .fontSize(18)
          TextInput({ placeholder: '请输入手机号' })
            .type(InputType.Number)
            .onChange((phone: string) => {
              this.phone = phone;
            });
        }
        .width('50%')

        Row() {
          Text('请输入密码：')
            .fontSize(18)
          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .onChange((pass_num: string) => {
              this.pass_num = pass_num;
            });
        }
        .width('50%')

      }
      .alignItems(HorizontalAlign.Start)
      .width('90%')

      Column({space:25}) {
        Row() {
          Button('登录')
            .width(150)
            .onClick(() => {
              this.http_login_request();
              this.dialogControllerProgress.open()
            })
        }
        Row() {
          Button('前往注册')
            .width(150)
            .onClick(() => {
              this.index.pushPath({ name: 'register' })
            })
        }
      }
      .margin({top:25})
      .alignItems(HorizontalAlign.Center)

    }
    .title('注册/登录')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}