import { cw, morseCodeTable, phonetic, phoneticAlphabet, q, q_phrases } from './base_resource';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct base_info_1 {
  @Consume('index') index: NavPathStack;
  @State morseCodeTable: Array<cw> = morseCodeTable

  build() {
    NavDestination() {
      List({ space: 10 }) {
        ForEach(this.morseCodeTable, (item: cw) => {
          ListItem() {
            Text(item.字符 + '  ' + item.电码)
              .backgroundColor($r('sys.color.comp_background_primary'))
              .padding({ left: 10 })
              .borderRadius(15)
              .width('100%')
              .height(50)
              .fontSize(20)
          }
        })
      }
      .width("90%")
    }
    .title('字母解释法')
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}

@Component
export struct base_info_2 {
  @Consume('index') index: NavPathStack;
  @State q_phrases: Array<q> = q_phrases

  build() {
    NavDestination() {
      List({ space: 10 }) {
        ForEach(this.q_phrases, (item: q) => {
          ListItem() {
            Text(item.Q简语 + '  ' + item.含义)
              .padding({ left: 10 })
              .borderRadius(15)
              .backgroundColor($r('sys.color.comp_background_primary'))
              .width('100%')
              .height(50)
              .fontSize(20)
          }
        })
      }
      .width("90%")
    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('常用 Q 简语')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}


// let soundPool: media.SoundPool;
// let audioRendererInfo: audio.AudioRendererInfo = {
//   usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
//   rendererFlags: 1
// }
// media.createSoundPool(5, audioRendererInfo, (error: BusinessError, soundPool_: media.SoundPool) => {
//   if (error) {
//     console.error(`Failed to createSoundPool`);
//     return;
//   } else {
//     soundPool = soundPool_;
//     console.info(`Succeeded in createSoundPool`);
//     let soundID: number = 0;
//     let streamID: number = 0;
//     let playParameters: media.PlayParameters = {
//       loop: 3, // 循环4次。
//       rate: audio.AudioRendererRate.RENDER_RATE_NORMAL, // 正常倍速。
//       leftVolume: 0.5, // range = 0.0-1.0。
//       rightVolume: 0.5, // range = 0.0-1.0。
//       priority: 0, // 最低优先级。
//     }
//
//     soundPool.play(soundID, playParameters).then((streamId: number) => {
//       console.info('Succeeded in playing soundpool');
//       streamID = streamId;
//     },(err: BusinessError) => {
//       console.error('Failed to play soundpool and catch error is ' + err.message);
//     });
//   }
// });

// @Component
// export struct base_info_4 {
//
//   @Consume('index') index: NavPathStack;
//   @State phoneticAlphabet:Array<phonetic> = phoneticAlphabet
//   build() {
//     NavDestination() {
//       List({ space: 10 }){
//         ForEach(this.phoneticAlphabet,(item:phonetic)=>{
//           ListItem(){
//             Text(item.letter+'  '+item.phonetic)
//
//               .borderRadius(15)
//               .backgroundColor('#ffffffff')
//               .width('100%')
//               .height(50)
//               .fontSize(20)
//           }
//         })
//       }
//       .width("90%")
//     }
//     .backgroundColor($r('sys.color.container_modal_unfocus_background'))
//     .title('常用 Q 简语')
//     .onBackPressed(() => {
//       this.index.pop() // 弹出路由栈栈顶元素
//       return true
//     })
//   }
// }

@Component
export struct base_info_3 {
  @Consume('index') index: NavPathStack;
  private phoneticAlphabet: Array<phonetic> = phoneticAlphabet
  private soundPool: media.SoundPool | undefined = undefined;
  private soundId: Map<string, number> = new Map();
  private streamId: number = 0;

  async aboutToAppear(): Promise<void> {
    this.create()
  }

  async aboutToDisappear() {
    this.release()
  }

  build() {
    NavDestination() {
      List({ space: 10 }) {
        ForEach(this.phoneticAlphabet, (item: phonetic) => {
          ListItem() {
            Row() {
              Text(item.letter + '  ' + item.phonetic)
                .padding({ left: 10 })
                .borderRadius(15)
                .backgroundColor($r('sys.color.comp_background_primary'))
                .width('80%')
                .height(50)
                .fontSize(20)
              Text() {
                SymbolSpan($r('sys.symbol.play_circle_fill'))
                  .fontWeight(FontWeight.Normal)
                  .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                  .fontColor(['#ff64bb5c', Color.White])
                  .fontSize(48)
              }
              .onClick(() => {
                this.PlaySoundPool(item.phonetic + '.mp3')
              })
              .id('playSoundPoolButton')
            }
          }
        })
      }
      .width("90%")
    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('常用 Q 简语')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }

  async create() {
    try {
      // audioRenderInfo中的参数usage取值为STREAM_USAGE_UNKNOWN，STREAM_USAGE_MUSIC，STREAM_USAGE_MOVIE。
      // STREAM_USAGE_AUDIOBOOK时，SoundPool播放短音时为混音模式，不会打断其他音频播放。
      let audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC, // 音频流使用类型：音乐。根据业务场景配置，参考StreamUsage。
        rendererFlags: 1 // 音频渲染器标志。
      }
      //创建soundPool实例。
      this.soundPool = await media.createSoundPool(32, audioRendererInfo);
      //注册监听。
      // 加载完成回调。
      this.soundPool!.on('loadComplete', (soundId_: number) => {
        // this.soundId.set(id,soundId_) ;
        console.info('loadComplete soundId: ' + soundId_);
      })
      //设置播放完成监听。
      this.soundPool!.on('playFinished', () => {
        console.info('receive play finished message');
        // 可进行下次播放。
      })
      //设置错误类型监听。
      this.soundPool!.on('error', (error: BusinessError) => {
        console.error('error happened,message is :' + error.code);
        console.error('error happened,message is :' + error.message);
      })

      let context = this.getUIContext().getHostContext();
      ;
      for (let index = 0; index < this.phoneticAlphabet.length; index++) {
        let id = this.phoneticAlphabet[index].phonetic + '.mp3'
        let fileDescriptor = await context!.resourceManager.getRawFd(id);
        let soundId_ = await this.soundPool!.load(fileDescriptor.fd, fileDescriptor.offset, fileDescriptor.length);
        this.soundId.set(id, soundId_);
        console.log('string:' + this.phoneticAlphabet[index].phonetic)
      }
      // 加载音频资源。
      // let context = this.getUIContext().getHostContext();;
      // let fileDescriptor = await context!.resourceManager.getRawFd(id);
      // await this.soundPool!.load(fileDescriptor.fd, fileDescriptor.offset, fileDescriptor.length);
      console.info(`load soundPool soundId: ${this.soundId}`)
    } catch (e) {
      console.error('createSoundPool error: ' + e);
    }
  }

  async PlaySoundPool(id: string) {
    let playParameters: media.PlayParameters = {};
    // 开始播放，这边play也可带播放播放的参数PlayParameters，请在音频资源加载完毕，即收到loadComplete回调之后再执行play操作。
    this.soundPool!.play(this.soundId.get(id), playParameters, (error, streamID: number) => {
      console.log(id + String(this.soundId.get(id)))
      if (error) {
        console.error(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
      } else {
        this.streamId = streamID;
        console.info('play success soundid:' + this.streamId);
      }
    });
  }

  async release() {
    // 终止指定流的播放。
    // await this.soundPool!.stop(this.streamId);
    // 卸载音频资源。
    for (let index = 0; index < this.phoneticAlphabet.length; index++) {
      let id = this.phoneticAlphabet[index].phonetic + '.mp3'
      await this.soundPool!.unload(this.soundId.get(id));
    }
    //关闭监听。
    this.setOffCallback();
    // 释放SoundPool。
    await this.soundPool!.release();
  }

  async setOffCallback() {
    this.soundPool!.off('loadComplete');
    this.soundPool!.off('playFinished');
    this.soundPool!.off('error');
  }
}