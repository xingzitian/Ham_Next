// MorseMinimalPractice.ets
import { inputConsumer, KeyCode, KeyEvent } from '@kit.InputKit';
import media from '@ohos.multimedia.media';
import common from '@ohos.app.ability.common';

import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';


@Component
export struct MorseMinimalPractice {
  // 状态变量
  @State inputText: string = 'HELLO WORLD' // 默认文本
  @State currentCharIndex: number = 0
  @State userInput: string = ''
  @State isCompleted: boolean = false
  @State accuracy: number = 100
  @State startTime: number = 0
  @State elapsedTime: number = 0
  @State timer: number = 0
  @State isProcessingSpace: boolean = false
  @Consume('index') index: NavPathStack;
  // 摩尔斯电码映射表
  private morseMap: Map<string, string> = new Map([
    ['A', '.-'], ['B', '-...'], ['C', '-.-.'], ['D', '-..'], ['E', '.'],
    ['F', '..-.'], ['G', '--.'], ['H', '....'], ['I', '..'], ['J', '.---'],
    ['K', '-.-'], ['L', '.-..'], ['M', '--'], ['N', '-.'], ['O', '---'],
    ['P', '.--.'], ['Q', '--.-'], ['R', '.-.'], ['S', '...'], ['T', '-'],
    ['U', '..-'], ['V', '...-'], ['W', '.--'], ['X', '-..-'], ['Y', '-.--'],
    ['Z', '--..'], ['0', '-----'], ['1', '.----'], ['2', '..---'], ['3', '...--'],
    ['4', '....-'], ['5', '.....'], ['6', '-....'], ['7', '--...'], ['8', '---..'],
    ['9', '----.'], [' ', '/']
  ])
  // SoundPool相关
  private soundPool: media.SoundPool | undefined = undefined;
  private dotSoundId: number = 0;
  private dashSoundId: number = 0;
  private streamId: number = 0;

  // 生命周期函数
  aboutToAppear(): void {
    this.setupKeyListeners()
    this.startTimer()
    this.initSoundPool()
  }

  aboutToDisappear(): void {
    this.removeKeyListeners()
    this.stopTimer()
    this.releaseSoundPool()
  }

  // 构建UI
  build() {
    NavDestination() {
      Column() {
        // 标题
        Text('摩尔斯电码练习')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })

        // 输入区域
        Row() {
          TextInput({ placeholder: '输入英文文本', text: this.inputText })
            .width('70%')
            .height(50)
            .onChange((value: string) => {
              this.inputText = value.toUpperCase()
              this.restart()
            })

          Button('随机句子')
            .onClick(() => this.useRandomSentence())
            .width('25%')
            .margin({ left: 10 })
        }
        .width('90%')
        .margin({ bottom: 20 })

        // 当前句子显示
        Text('当前句子:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('90%')
          .textAlign(TextAlign.Start)

        Text(this.inputText)
          .fontSize(18)
          .width('90%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        // 摩尔斯码显示
        Text('摩尔斯码:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('90%')
          .textAlign(TextAlign.Start)

        Text(this.textToMorse(this.inputText))
          .fontSize(16)
          .width('90%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 30 })

        // 进度和统计信息
        Row() {
          Column() {
            Text(`进度: ${this.currentCharIndex}/${this.inputText.length}`)
              .fontSize(14)
            Text(`准确率: ${this.accuracy}%`)
              .fontSize(14)
          }
          .layoutWeight(1)

          Column() {
            Text('用时:')
              .fontSize(14)
            Text(`${Math.floor(this.elapsedTime / 60)}:${(this.elapsedTime % 60).toString().padStart(2, '0')}`)
              .fontSize(14)
          }
          .layoutWeight(1)
        }
        .padding(10)
        .width('90%')
        .margin({ bottom: 20 })

        // 当前字符和输入状态
        Text('当前字符:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .width('90%')
          .textAlign(TextAlign.Start)

        // 显示当前字符
        if (this.currentCharIndex < this.inputText.length) {
          if (this.isProcessingSpace) {
            Text('[SPACE]')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFA500')
              .margin({ bottom: 10 })

            Text('自动处理中...')
              .fontSize(20)
              .fontColor('#FFA500')
              .margin({ bottom: 10 })
          } else {
            Text(this.inputText[this.currentCharIndex])
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })

            // 当前字符的摩尔斯码提示
            Text(this.charToMorse(this.inputText[this.currentCharIndex]))
              .fontSize(20)
              .margin({ bottom: 10 })
          }
        }

        // 用户输入显示
        Text(this.userInput)
          .fontSize(24)
          .margin({ top: 10, bottom: 20 })
          .fontColor(this.userInput ? '#1890FF' : '#00000040')

        // 完成状态或操作按钮
        if (this.isCompleted) {
          Column() {
            Text('练习完成!')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#52C41A')
              .margin({ bottom: 8 })

            Text(`用时: ${Math.floor(this.elapsedTime / 60)}:${(this.elapsedTime % 60).toString().padStart(2, '0')}`)
              .fontSize(16)
              .margin({ bottom: 8 })

            Text(`准确率: ${this.accuracy}%`)
              .fontSize(16)
              .margin({ bottom: 16 })

            Button('重新开始')
              .onClick(() => this.restart())
              .width('60%')
          }
          .margin({ top: 20 })
        } else {
          Row() {
            Button('跳过当前字符')
              .onClick(() => {
                if (this.currentCharIndex < this.inputText.length && !this.isProcessingSpace) {
                  this.currentCharIndex++
                  this.userInput = ''
                  this.accuracy = Math.max(0, this.accuracy - 5)
                  this.processNextChar()
                }
              })
              .layoutWeight(1)
              .margin({ right: 8 })
              .opacity(this.isProcessingSpace ? 0.5 : 1)
              .enabled(!this.isProcessingSpace)

            Button('新句子')
              .onClick(() => this.useRandomSentence())
              .layoutWeight(1)
              .margin({ left: 8 })
          }
          .width('90%')
          .margin({ top: 20 })
        }

        // 使用说明
        Text('使用说明: 音量减键 = 点(.), 音量加键 = 划(-), 空格自动处理')
          .fontSize(12)
          .fontColor(Color.Gray)
          .margin({ top: 30 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('日志创建')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }

  // 音量键回调函数
  private volumeUpCallBackFunc: (event: KeyEvent) => void = () => {
  }

  private volumeDownCallBackFunc: (event: KeyEvent) => void = () => {
  }

  // 初始化SoundPool
  private async initSoundPool() {
    try {
      let audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 1
      }

      // 创建SoundPool实例
      this.soundPool = await media.createSoundPool(2, audioRendererInfo)

      // 注册监听器
      this.soundPool!.on('loadComplete', (soundId: number) => {
        console.info('loadComplete soundId: ' + soundId)
      })

      this.soundPool!.on('playFinished', () => {
        console.info('receive play finished message')
      })

      this.soundPool!.on('error', (error: BusinessError) => {
        console.error('error happened,message is :' + error.message)
      })

      // 获取上下文并加载音频文件
      let context = this.getUIContext().getHostContext() as common.Context

      // 加载dot.mp3（点的声音）
      let dotFileDescriptor = await context.resourceManager.getRawFd('dot.mp3')
      this.dotSoundId =
        await this.soundPool!.load(dotFileDescriptor.fd, dotFileDescriptor.offset, dotFileDescriptor.length)

      // 加载dash.mp3（划的声音）
      let dashFileDescriptor = await context.resourceManager.getRawFd('dash.mp3')
      this.dashSoundId =
        await this.soundPool!.load(dashFileDescriptor.fd, dashFileDescriptor.offset, dashFileDescriptor.length)

      console.info(`SoundPool loaded - dot: ${this.dotSoundId}, dash: ${this.dashSoundId}`)
    } catch (error) {
      console.error('initSoundPool error: ' + error)
    }
  }

  // 释放SoundPool
  private async releaseSoundPool() {
    if (this.soundPool) {
      try {
        // 卸载音频资源
        await this.soundPool.unload(this.dotSoundId)
        await this.soundPool.unload(this.dashSoundId)

        // 关闭监听器
        this.soundPool.off('loadComplete')
        this.soundPool.off('playFinished')
        this.soundPool.off('error')

        // 释放SoundPool
        await this.soundPool.release()
      } catch (error) {
        console.error('releaseSoundPool error: ' + error)
      }
    }
  }

  // 播放声音
  private async playSound(type: 'dot' | 'dash') {
    if (!this.soundPool) {
      return
    }

    try {
      let playParameters: media.PlayParameters = {}

      if (type === 'dot') {
        this.soundPool.play(this.dotSoundId, playParameters, (error, streamID: number) => {
          if (error) {
            console.error(`play dot sound Error: ${error.message}`)
          } else {
            this.streamId = streamID
          }
        })
      } else {
        this.soundPool.play(this.dashSoundId, playParameters, (error, streamID: number) => {
          if (error) {
            console.error(`play dash sound Error: ${error.message}`)
          } else {
            this.streamId = streamID
          }
        })
      }
    } catch (error) {
      console.error('playSound error: ' + error)
    }
  }

  // 计时器函数 - 修复版本
  private startTimer() {
    // 先停止可能存在的旧计时器
    this.stopTimer();

    this.startTime = new Date().getTime();
    this.elapsedTime = 0;

    this.timer = setInterval(() => {
      // 只有在未完成状态下才更新时间
      if (!this.isCompleted) {
        this.elapsedTime = Math.floor((new Date().getTime() - this.startTime) / 1000);
      }
    }, 1000);
  }

  private stopTimer() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = 0;
    }
  }

  // 设置按键监听器
  private setupKeyListeners(): void {
    try {
      // 音量加键配置
      let options1: inputConsumer.KeyPressedConfig = {
        key: KeyCode.KEYCODE_VOLUME_UP,
        action: 1,
        isRepeat: false,
      }

      // 音量减键配置
      let options2: inputConsumer.KeyPressedConfig = {
        key: KeyCode.KEYCODE_VOLUME_DOWN,
        action: 1,
        isRepeat: false,
      }

      // 音量加键回调函数
      this.volumeUpCallBackFunc = (event: KeyEvent) => {
        if (!this.isProcessingSpace) {
          this.addMorseChar('-')
          this.playSound('dash')
        }
      }

      // 音量减键回调函数
      this.volumeDownCallBackFunc = (event: KeyEvent) => {
        if (!this.isProcessingSpace) {
          this.addMorseChar('.')
          this.playSound('dot')
        }
      }

      // 注册监听事件
      inputConsumer.on('keyPressed', options1, this.volumeUpCallBackFunc)
      inputConsumer.on('keyPressed', options2, this.volumeDownCallBackFunc)
    } catch (error) {
      console.error(`Subscribe execute failed, error: ${JSON.stringify(error, ["code", "message"])}`)
    }
  }

  // 移除按键监听器
  private removeKeyListeners(): void {
    try {
      inputConsumer.off('keyPressed', this.volumeUpCallBackFunc)
      inputConsumer.off('keyPressed', this.volumeDownCallBackFunc)
    } catch (error) {
      console.error(`Unsubscribe execute failed, error: ${JSON.stringify(error, ["code", "message"])}`)
    }
  }

  // 将字符转换为摩尔斯电码
  private charToMorse(char: string): string {
    const upperChar = char.toUpperCase()
    return this.morseMap.get(upperChar) || ''
  }

  // 将文本转换为摩尔斯电码
  private textToMorse(text: string): string {
    let result = ''
    for (let i = 0; i < text.length; i++) {
      const char = text[i]
      const morse = this.charToMorse(char)
      if (i > 0 && morse !== '') {
        result += ' '
      }
      result += morse
    }
    return result
  }

  // 处理下一个字符

  // 处理空格字符
  private async processSpace() {
    if (this.currentCharIndex >= this.inputText.length) {
      return
    }

    const currentChar = this.inputText[this.currentCharIndex]

    // 如果当前字符是空格，自动处理
    if (currentChar === ' ') {
      this.isProcessingSpace = true
      this.userInput = '[SPACE]'

      // 等待标准时间间隔
      await this.sleep(700)

      // 移动到下一个字符
      this.currentCharIndex++
      this.userInput = ''
      this.isProcessingSpace = false

      // 递归处理下一个字符
      this.processNextChar()
    }
  }

  // 处理下一个字符函数 - 修复版本
  private processNextChar() {
    if (this.currentCharIndex >= this.inputText.length) {
      this.isCompleted = true
      this.stopTimer() // 确保完成时停止计时
      return
    }

    // 检查是否需要处理空格
    this.processSpace()
  }

  // 睡眠函数
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // 添加摩尔斯字符
  private addMorseChar(char: string) {
    if (this.isCompleted || this.isProcessingSpace) {
      return
    }

    this.userInput += char

    // 获取当前字符的摩尔斯码
    const currentChar = this.inputText[this.currentCharIndex]
    const currentMorse = this.charToMorse(currentChar)

    // 检查输入是否正确
    if (this.userInput === currentMorse) {
      // 正确，移动到下一个字符
      this.userInput = ''
      this.currentCharIndex++

      // 处理下一个字符
      this.processNextChar()
    } else if (!currentMorse.startsWith(this.userInput)) {
      // 输入错误，重置并降低准确率
      this.userInput = ''
      this.accuracy = Math.max(0, this.accuracy - 2)
    }
  }

  // 重新开始函数 - 修复版本
  private restart() {
    // 先停止当前计时器
    this.stopTimer();

    this.currentCharIndex = 0;
    this.userInput = '';
    this.isCompleted = false;
    this.isProcessingSpace = false;
    this.accuracy = 100;
    this.startTime = new Date().getTime();
    this.elapsedTime = 0;

    // 开始处理第一个字符
    this.processNextChar();

    // 重新启动计时器
    this.startTimer();
  }

  // 生成随机练习句子
  private generatePracticeSentence(): string {
    // 呼号前缀
    const callSignPrefixes: string[] = ['W', 'K', 'N', 'AA', 'AB', 'AC']
    // 呼号数字部分
    const callSignNumbers: string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
    // 呼号后缀
    const callSignSuffixes: string[] = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
    // Q简语
    const qCodes: string[] = ['QSL', 'QRZ', 'QTH', 'QSY', 'QRM', 'QRN', 'QSB']
    // 常用单词
    const commonWords: string[] = ['CQ', 'DE', 'TEST', 'SIGNAL', 'REPORT', 'NAME', 'QTH', 'RIG']
    // 信号报告
    const signalReports: string[] = ['599', '579', '559', '539', '519', '499']

    let sentenceParts: string[] = []

    // 生成呼号
    const generateCallSign = (): string => {
      const prefix = callSignPrefixes[Math.floor(Math.random() * callSignPrefixes.length)]
      const number = callSignNumbers[Math.floor(Math.random() * callSignNumbers.length)]
      const suffix = callSignSuffixes[Math.floor(Math.random() * callSignSuffixes.length)]
      return `${prefix}${number}${suffix}`
    }

    // 80%的概率以CQ开头
    if (Math.random() < 0.8) {
      sentenceParts.push('CQ')
      sentenceParts.push('CQ')
      sentenceParts.push('CQ')
    }

    // 添加呼号
    sentenceParts.push(generateCallSign())

    // 添加DE和另一个呼号
    sentenceParts.push('DE')
    sentenceParts.push(generateCallSign())

    // 添加信号报告
    if (Math.random() < 0.7) {
      sentenceParts.push('RST')
      sentenceParts.push(signalReports[Math.floor(Math.random() * signalReports.length)])
    }

    // 添加Q简语
    if (Math.random() < 0.5) {
      sentenceParts.push(qCodes[Math.floor(Math.random() * qCodes.length)])
    }

    // 添加其他单词
    const extraWords = Math.floor(Math.random() * 2) + 1
    for (let i = 0; i < extraWords; i++) {
      sentenceParts.push(commonWords[Math.floor(Math.random() * commonWords.length)])
    }

    // 10%的概率以73结束
    if (Math.random() < 0.1) {
      sentenceParts.push('73')
    }

    return sentenceParts.join(' ')
  }

  // 使用随机生成的句子
  private useRandomSentence() {
    this.inputText = this.generatePracticeSentence()
    this.restart()
  }
}
