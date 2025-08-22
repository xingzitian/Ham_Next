// MorseCodeConverter.ets
import audio from '@ohos.multimedia.audio';
import promptAction from '@ohos.promptAction';

// 摩尔斯电码映射表
const MORSE_CODE_MAP: Record<string, string> = {
  'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.',
  'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
  'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.',
  'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
  'Y': '-.--', 'Z': '--..', '0': '-----', '1': '.----', '2': '..---',
  '3': '...--', '4': '....-', '5': '.....', '6': '-....', '7': '--...',
  '8': '---..', '9': '----.', ' ': '/', '.': '.-.-.-', ',': '--..--',
  '?': '..--..', "'": '.----.', '!': '-.-.--', '/': '-..-.', '(': '-.--.',
  ')': '-.--.-', '&': '.-...', ':': '---...', ';': '-.-.-.', '=': '-...-',
  '+': '.-.-.', '-': '-....-', '_': '..--.-', '"': '.-..-.', '$': '...-..-',
  '@': '.--.-.'
};

// 时间参数接口
interface MorseTimingParameters {
  dotLength: number;
  dashLength: number;
  intraCharGap: number;
  interCharGap: number;
  wordGap: number;
}


@Component
export struct MorseCodeConverter {
  @Consume('index') index: NavPathStack;
  // 状态变量
  @State inputText: string = '';
  @State morseCode: string = '';
  @State isPlaying: boolean = false;
  @State frequency: number = 600; // 默认频率(Hz)
  @State wpm: number = 15; // 默认速度：15单词/分钟
  @State statusMessage: string = '准备就绪';

  // 音频渲染器和相关状态
  private audioRenderer: audio.AudioRenderer | null = null;
  private isAborted: boolean = false;
  private playbackQueue: string = '';

  // 计算基础点长（毫秒）
  calculateDotLength(wpm: number): number {
    return 60000 / (wpm * 50);
  }

  // 根据WPM获取所有时间参数
  getTimingParameters(wpm: number): MorseTimingParameters {
    const dotLength = this.calculateDotLength(wpm);

    return {
      dotLength: dotLength,
      dashLength: 3 * dotLength,
      intraCharGap: dotLength,
      interCharGap: 3 * dotLength,
      wordGap: 7 * dotLength
    };
  }

  // 生命周期函数
  aboutToAppear() {
    this.initAudioRenderer();
  }

  aboutToDisappear() {
    this.releaseAudioRenderer();
  }

  // 初始化音频渲染器
  async initAudioRenderer() {
    try {
      this.statusMessage = '初始化音频设备...';

      let audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_F32LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };

      let audioRendererOptions: audio.AudioRendererOptions = {
        streamInfo: audioStreamInfo,
        rendererInfo: {
          content: audio.ContentType.CONTENT_TYPE_MUSIC,
          usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
          rendererFlags: 0
        }
      };

      this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);
      await this.audioRenderer.start();

      this.statusMessage = '准备就绪';
    } catch (err) {
      console.error(`初始化音频渲染器失败: ${err.message}`);
      this.statusMessage = '音频初始化失败';
    }
  }

  // 释放音频渲染器
  async releaseAudioRenderer() {
    this.stopPlayback();

    if (this.audioRenderer) {
      try {
        await this.audioRenderer.stop();
        await this.audioRenderer.release();
        this.audioRenderer = null;
      } catch (err) {
        console.error(`释放音频渲染器失败: ${err.message}`);
      }
    }
  }

  // 生成正弦波音频数据
  generateTone(frequency: number, duration: number): ArrayBuffer {
    const sampleRate = 44100;
    const amplitude = 0.3;
    const numSamples = Math.floor(duration / 1000 * sampleRate);
    const buffer = new ArrayBuffer(numSamples * 4);
    const view = new DataView(buffer);

    // 添加淡入淡出效果以减少爆音
    const fadeSamples = Math.min(100, numSamples / 10);

    for (let i = 0; i < numSamples; i++) {
      // 计算淡入淡出系数
      let fade = 1.0;
      if (i < fadeSamples) {
        fade = i / fadeSamples; // 淡入
      } else if (i > numSamples - fadeSamples) {
        fade = (numSamples - i) / fadeSamples; // 淡出
      }

      const value = amplitude * fade * Math.sin(2 * Math.PI * frequency * i / sampleRate);
      view.setFloat32(i * 4, value, true);
    }

    return buffer;
  }

  // 播放单个符号
  async playSymbol(symbol: string, timing: MorseTimingParameters): Promise<boolean> {
    if (!this.audioRenderer || this.isAborted) return false;

    try {
      let buffer: ArrayBuffer;
      let duration: number;

      switch (symbol) {
        case '.':
          buffer = this.generateTone(this.frequency, timing.dotLength);
          duration = timing.dotLength;
          break;

        case '-':
          buffer = this.generateTone(this.frequency, timing.dashLength);
          duration = timing.dashLength;
          break;

        default:
          return true; // 跳过未知符号
      }

      // 写入音频数据
      await this.audioRenderer.write(buffer);

      // 等待音频播放完成
      await this.sleep(duration);

      return true;
    } catch (err) {
      console.error(`播放符号失败: ${err.message}`);
      return false;
    }
  }

  // 播放摩尔斯电码音频
  // 播放摩尔斯电码音频 - 优化版（预生成缓冲区 + 最后一个音调无淡出）
  async playMorseCode() {
    if (!this.audioRenderer || this.morseCode === '') {
      this.statusMessage = '音频设备未就绪或无可播放内容';
      return;
    }

    this.isPlaying = true;
    this.isAborted = false;
    this.statusMessage = '生成音频中...';

    const timing = this.getTimingParameters(this.wpm);
    const sampleRate = 44100;
    const amplitude = 0.3;
    const initialFadeSamples = 22; // 约0.5ms的预热，可根据需要调整

    // 找到最后一个有效音调符号（'.'或'-')的位置
    let lastToneIndex = -1;
    for (let i = this.morseCode.length - 1; i >= 0; i--) {
      if (this.morseCode[i] === '.' || this.morseCode[i] === '-') {
        lastToneIndex = i;
        break;
      }
    }

    // 如果没有找到任何音调符号，直接返回
    if (lastToneIndex === -1) {
      this.statusMessage = '无有效音调可播放';
      this.isPlaying = false;
      return;
    }

    let totalSamples = 0;

    // 计算总样本数（不包括初始预热）
    for (const symbol of this.morseCode) {
      switch (symbol) {
        case '.': totalSamples += Math.floor(timing.dotLength / 1000 * sampleRate); break;
        case '-': totalSamples += Math.floor(timing.dashLength / 1000 * sampleRate); break;
        case ' ': totalSamples += Math.floor(timing.interCharGap / 1000 * sampleRate); break;
        case '/': totalSamples += Math.floor(timing.wordGap / 1000 * sampleRate); break;
      }
    }

    // 分配缓冲区，额外空间用于初始预热
    const buffer = new ArrayBuffer((totalSamples + initialFadeSamples) * 4);
    const view = new DataView(buffer);
    let offset = 0;

    // 1. 插入初始预热静音（消除初始爆音）
    for (let i = 0; i < initialFadeSamples; i++) {
      view.setFloat32(offset, 0, true);
      offset += 4;
    }

    // 2. 生成所有摩尔斯电码音频数据
    for (let i = 0; i < this.morseCode.length; i++) {
      const symbol = this.morseCode[i];
      let duration: number;

      switch (symbol) {
        case '.': duration = timing.dotLength; break;
        case '-': duration = timing.dashLength; break;
        case ' ': duration = timing.interCharGap; break;
        case '/': duration = timing.wordGap; break;
        default: continue; // 跳过未知符号
      }

      const numSamples = Math.floor(duration / 1000 * sampleRate);
      const isLastTone = (i === lastToneIndex); // 检查是否是最后一个音调

      if (symbol === '.' || symbol === '-') {
        // 生成音频
        const fadeSamples = Math.min(100, numSamples / 10);

        for (let j = 0; j < numSamples; j++) {
          // 计算淡入系数
          let fade = 1.0;
          if (j < fadeSamples) {
            fade = j / fadeSamples; // 淡入
          }
          // 只有不是最后一个音调时才应用淡出
          else if (j > numSamples - fadeSamples && !isLastTone) {
            fade = (numSamples - j) / fadeSamples; // 淡出
          }

          const value = amplitude * fade * Math.sin(2 * Math.PI * this.frequency * j / sampleRate);
          view.setFloat32(offset, value, true);
          offset += 4;
        }
      } else {
        // 生成静音（间隔）
        for (let j = 0; j < numSamples; j++) {
          view.setFloat32(offset, 0, true);
          offset += 4;
        }
      }

      // 检查是否被中止
      if (this.isAborted) {
        this.statusMessage = '播放已中止';
        this.isPlaying = false;
        return;
      }
    }

    // 一次性写入所有数据
    try {
      await this.audioRenderer.write(buffer);
      this.statusMessage = '播放完成';
    } catch (err) {
      console.error(`播放失败: ${err.message}`);
      this.statusMessage = `播放错误: ${err.message}`;
    } finally {
      this.isPlaying = false;
    }
  }




  // 停止播放
  stopPlayback() {
    this.isAborted = true;
    this.isPlaying = false;
    this.statusMessage = '已停止';
  }

  // 睡眠函数
  sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // 转换文本为摩尔斯电码
  convertToMorse() {
    if (this.inputText.trim() === '') {
      promptAction.showToast({ message: '请输入文本', duration: 2000 });
      return;
    }

    this.morseCode = '';
    this.statusMessage = '转换中...';

    const text = this.inputText.toUpperCase();

    for (let i = 0; i < text.length; i++) {
      const char = text[i];

      if (char === ' ') {
        this.morseCode += '/ ';
        continue;
      }

      if (MORSE_CODE_MAP[char]) {
        const morseChar = MORSE_CODE_MAP[char];
        // 将字符内的每个符号用空格分隔
        for (let j = 0; j < morseChar.length; j++) {
          this.morseCode += morseChar[j];
          if (j < morseChar.length - 1) {
            this.morseCode += ' ';
          }
        }

        // 添加字符间间隔
        if (i < text.length - 1 && text[i + 1] !== ' ') {
          this.morseCode += '  ';
        }
      } else {
        // 对于不支持的字符，显示问号
        this.morseCode += '?? ';
      }
    }

    this.morseCode = this.morseCode.trim();
    this.statusMessage = '转换完成，可点击播放';
  }

  // 清空所有内容
  clearAll() {
    this.inputText = '';
    this.morseCode = '';
    this.stopPlayback();
    this.statusMessage = '已清空';
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        // 标题
        Text('摩尔斯电码转换器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 状态显示
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ bottom: 10 })

        // 输入区域
        TextInput({ placeholder: '输入要转换的文本（字母、数字、符号）', text: this.inputText })
          .width('90%')
          .height(60)
          .onChange((value: string) => {
            this.inputText = value;
          })

        // 按钮行
        Row({ space: 15 }) {
          Button('转换为摩尔斯电码', { type: ButtonType.Capsule })
            .width(160)
            .onClick(() => {
              this.convertToMorse();
            })

          Button('清空', { type: ButtonType.Capsule })
            .width(80)
            .onClick(() => {
              this.clearAll();
            })
        }

        // 摩尔斯电码显示
        if (this.morseCode) {
          Column() {
            Text('摩尔斯电码:')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 5 })

            Text(this.morseCode)
              .fontSize(18)
              .width('90%')
              .textAlign(TextAlign.Center)
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .border({ width: 1, color: Color.Gray })
          }
          .width('100%')
          .margin({ top: 10, bottom: 10 })
        }

        // 控制按钮
        Button(this.isPlaying ? '停止播放' : '播放音频', { type: ButtonType.Capsule })
          .width(150)
          .height(45)
          .backgroundColor(this.isPlaying ? Color.Red : Color.Blue)
          .opacity(this.morseCode ? 1 : 0.5)
          .enabled(!!this.morseCode)
          .onClick(() => {
            if (this.isPlaying) {
              this.stopPlayback();
            } else if (this.morseCode) {
              this.playMorseCode();
            }
          })
          .margin({ top: 10, bottom: 10 })

        // 频率调节
        Text(`频率: ${this.frequency}Hz`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        Slider({
          value: this.frequency,
          min: 300,
          max: 1200,
          step: 50,
          style: SliderStyle.OutSet
        })
          .width('85%')
          .onChange((value: number) => {
            this.frequency = value;
          })

        // WPM速度调节
        Text(`速度: ${this.wpm} WPM (单词/分钟)`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15 })

        Slider({
          value: this.wpm,
          min: 5,
          max: 30,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('85%')
          .onChange((value: number) => {
            this.wpm = value;
          })

        // 时间参数显示
        Text(`当前时间参数: 点=${this.calculateDotLength(this.wpm).toFixed(0)}ms, 划=${(3 *
        this.calculateDotLength(this.wpm)).toFixed(0)}ms`)
          .fontSize(12)
          .fontColor(Color.Gray)
          .margin({ top: 5 })

        // 使用说明
        Text('使用说明: 输入文本后点击转换，然后播放音频。支持字母、数字和常用符号。')
          .fontSize(12)
          .fontColor(Color.Gray)
          .width('85%')
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FA')
      .alignItems(HorizontalAlign.Center)
      .padding(10)
    }
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}