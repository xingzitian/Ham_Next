// Flashlight.ets
import camera from '@ohos.multimedia.camera';


@Component
export struct Flashlight {
  // 状态变量
  @State isFlashlightOn: boolean = false;
  @State statusMessage: string = '点击按钮打开手电筒';
  // 相机和闪光灯相关状态
  @Consume('index') index: NavPathStack;
  private Context: Context | undefined = undefined
  private torchSupport: boolean = false;

  // 生命周期函数
  async aboutToAppear() {
    console.log('手电筒页面即将显示');
    this.init
  }

  aboutToDisappear() {
    console.log('手电筒页面即将消失');
    this.turnOffFlashlight();
  }

  async init() {
    let cameraManager = camera.getCameraManager(this.Context);
    this.Context = this.getUIContext().getHostContext();
    this.torchSupport = cameraManager.isTorchSupported();
  }

  // 打开手电筒
  async turnOnFlashlight() {
    try {
      let cameraManager = camera.getCameraManager(this.Context);
      // 设置闪光灯模式为常开
      cameraManager.setTorchMode(1);
      this.isFlashlightOn = true;
      this.statusMessage = '手电筒已打开';
      console.log('手电筒已打开');
    } catch (error) {
      console.error('打开手电筒失败:', error);
      this.statusMessage = '打开手电筒失败';
    }
  }

  // 关闭手电筒
  async turnOffFlashlight() {

    try {
      let cameraManager = camera.getCameraManager(this.Context);
      // 设置闪光灯模式为关闭
      cameraManager.setTorchMode(0);
      this.isFlashlightOn = false;
      this.statusMessage = '手电筒已关闭';
      console.log('手电筒已关闭');
    } catch (error) {
      console.error('关闭手电筒失败:', error);
      this.statusMessage = '关闭手电筒失败';
    }
  }

  // 切换手电筒状态
  async toggleFlashlight() {
    if (this.isFlashlightOn) {
      await this.turnOffFlashlight();
    } else {
      await this.turnOnFlashlight();
    }
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Text('手电筒')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 40, bottom: 20 })

        Text(this.statusMessage)
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ bottom: 40 })

        // 手电筒开关按钮
        Circle({ width: 150, height: 150 })
          .fill(this.isFlashlightOn ? Color.Yellow : Color.Blue)
          .onClick(() => {
            this.toggleFlashlight();
          })
          .margin({ bottom: 40 })


        Text('使用说明: 点击中央按钮打开或关闭手电筒。')
          .fontSize(14)
          .fontColor(Color.Gray)
          .width('80%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
  }
}
