import { http_id } from '../http_server/httpService';
import { LoadingDialog, PromptAction } from '@kit.ArkUI';

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
  @State password: string = '';
  @StorageLink('token') token: string = '';
  @StorageLink('callsign') callsign: string = '';

  async http_login_request() {
    try {
      const response =
        await http_id.httpRequest(2, this.password, this.callsign);

      setTimeout(() => {
        this.dialogControllerProgress.close()
          this.promptAction.showToast({
            message: response.message
          });
          this.token = response.data.token
          this.callsign = response.data.callsign
          console.log("获取到的呼号：" + this.callsign)
          this.index.pop()
      }, 500);

    } catch (error) {
      setTimeout(() => {
        this.dialogControllerProgress.close()
        this.promptAction.showToast({
          message: error
        });

      }, 500);


    }
  }

  build() {
    NavDestination() {
      Column({ space: 25 }) {

        Row() {
          Text('请输入呼号：')
            .fontSize(18)
          TextInput({ placeholder: '请输入呼号' })
            .type(InputType.Normal)
            .onChange((callsign: string) => {
              this.callsign = callsign;
            });
        }
        .width('50%')

        Row() {
          Text('请输入密码：')
            .fontSize(18)
          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .onChange((password: string) => {
              this.password = password;
            });
        }
        .width('50%')

      }
      .alignItems(HorizontalAlign.Start)
      .width('90%')

      Column({ space: 25 }) {
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
      .margin({ top: 25 })
      .alignItems(HorizontalAlign.Center)

    }
    .title('注册/登录')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}


@Component
export struct register {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在提交中',
    }),
  })
  @Consume('index') index: NavPathStack;
  @State password: string = '';
  @State email: string = ''
  @StorageLink('token') token: string = '';
  @StorageLink('callsign') callsign: string = '';

  async http_register_request(email?: string) {
    try {
      const response =
        await http_id.httpRequest(1, this.password, this.callsign, this.email);

      setTimeout(() => {
        this.dialogControllerProgress.close()
          this.promptAction.showToast({
            message: response.message
          });
          this.token = response.data.token
          this.index.clear();
      }, 500);

    } catch (error) {
      setTimeout(() => {
        this.dialogControllerProgress.close()
        this.promptAction.showToast({
          message: error
        });
      }, 500);

    }
  }

  build() {
    NavDestination() {
      Column({ space: 25 }) {
        Row() {
          Text('请输入呼号：')
            .fontSize(18)
          TextInput({ placeholder: '请输入呼号' })
            .type(InputType.Normal)
            .onChange((callsign: string) => {
              this.callsign = callsign;
            });
        }
        .width('50%')

        Row() {
          Text('请输入密码：')
            .fontSize(18)
          TextInput({ placeholder: '请输入密码' })
            .type(InputType.Password)
            .onChange((password: string) => {
              this.password = password;
            });
        }
        .width('50%')

        Row() {
          Text('请输入邮箱：')
            .fontSize(18)
          TextInput({ placeholder: '请输入邮箱' })
            .type(InputType.Email)
            .onChange((email: string) => {
              this.email = email;
            });
        }
        .width('50%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('90%')

      Column() {
        Row() {
          Button('注册')
            .width(150)
            .onClick(() => {
              this.http_register_request();
              this.dialogControllerProgress.open()
            })
        }
      }
      .margin({ top: 25 })
      .alignItems(HorizontalAlign.Center)
    }
    .title('注册/登录')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}