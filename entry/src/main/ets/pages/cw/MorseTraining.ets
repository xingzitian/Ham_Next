// MorseTraining.ets
import audio from '@ohos.multimedia.audio';
import { PromptAction } from '@kit.ArkUI';

// 摩尔斯电码映射表
const MORSE_CODE_MAP: Record<string, string> = {
  'A': '.-',
  'B': '-...',
  'C': '-.-.',
  'D': '-..',
  'E': '.',
  'F': '..-.',
  'G': '--.',
  'H': '....',
  'I': '..',
  'J': '.---',
  'K': '-.-',
  'L': '.-..',
  'M': '--',
  'N': '-.',
  'O': '---',
  'P': '.--.',
  'Q': '--.-',
  'R': '.-.',
  'S': '...',
  'T': '-',
  'U': '..-',
  'V': '...-',
  'W': '.--',
  'X': '-..-',
  'Y': '-.--',
  'Z': '--..',
  '0': '-----',
  '1': '.----',
  '2': '..---',
  '3': '...--',
  '4': '....-',
  '5': '.....',
  '6': '-....',
  '7': '--...',
  '8': '---..',
  '9': '----.',
  ' ': '/',
  '.': '.-.-.-',
  ',': '--..--',
  '?': '..--..',
  "'": '.----.',
  '!': '-.-.--',
  '/': '-..-.',
  '(': '-.--.',
  ')': '-.--.-',
  '&': '.-...',
  ':': '---...',
  ';': '-.-.-.',
  '=': '-...-',
  '+': '.-.-.',
  '-': '-....-',
  '_': '..--.-',
  '"': '.-..-.',
  '$': '...-..-',
  '@': '.--.-.'
};

// 预定义单词列表和句子模板
const WORD_LIST: string[] = [
  'HELLO', 'WORLD', 'HAM', 'RADIO', 'TEST', 'CODE', 'MORSE',
  'SOS', 'QUICK', 'BROWN', 'FOX', 'JUMP', 'LAZY', 'DOG'
];

const SENTENCE_TEMPLATES: string[] = [
  'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG',
  'SOS IS THE INTERNATIONAL MORSE CODE DISTRESS SIGNAL',
  'HAM RADIO OPERATORS USE MORSE CODE',
  'PRACTICE MAKES PERFECT'
];

// 时间参数接口
interface MorseTimingParameters {
  dotLength: number;
  dashLength: number;
  intraCharGap: number;
  interCharGap: number;
  wordGap: number;
}

@Component
export struct MorseTraining {
  @Consume('index') index: NavPathStack;
  // 状态变量
  @State currentContent: string = '';
  @State userInput: string = '';
  @State isPlaying: boolean = false;
  @State frequency: number = 600;
  @State wpm: number = 15;
  @State mode: string = 'word';
  @State statusMessage: string = '准备就绪';
  @State correctAnswer: string = '';
  @State startTime: number = 0;
  @State elapsedTime: number = 0;
  @State accuracy: number = 0;
  @State isRandomFrequencyEnabled: boolean = false;
  @State elapsedTimeDisplay: string = '0秒';
  @State morseCodeOfAnswer: string = '';
  @State isAnswerSubmitted: boolean = false;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  // 音频渲染器和相关状态
  private audioRenderer: audio.AudioRenderer | null = null;
  private currentAudioState: audio.AudioState = audio.AudioState.STATE_NEW;
  // PCM数据管理
  private fullPcmData: ArrayBuffer | null = null;
  private pcmDataOffset: number = 0;
  private isPlaybackComplete: boolean = false;
  private allDataProvided: boolean = false;
  private timerId: number = 0;
  private currentDirection: number = 0;

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
    console.log('页面即将显示，初始化音频渲染器');
    this.initAudioRenderer();
    this.generateNewContent();
  }

  aboutToDisappear() {
    console.log('页面即将消失，释放音频渲染器');
    this.releaseAudioRenderer();
    this.clearTimer();
  }

  // 初始化音频渲染器
  async initAudioRenderer() {
    try {
      console.log('开始初始化音频渲染器');
      this.statusMessage = '初始化音频设备...';

      let audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_F32LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };
      let audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };
      let audioRendererOptions: audio.AudioRendererOptions = {
        streamInfo: audioStreamInfo,
        rendererInfo: audioRendererInfo
      };

      console.log('创建音频渲染器实例');
      this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);

      if (!this.audioRenderer) {
        console.error('音频渲染器创建失败: 返回值为null');
        this.statusMessage = '音频设备创建失败';
        return;
      }

      // 设置状态变化监听器
      this.setupStateChangeListener();

      // 获取初始状态
      this.currentAudioState = this.audioRenderer.state;
      console.log('音频渲染器初始状态:', this.currentAudioState);

      // 重置状态
      this.isPlaybackComplete = false;
      this.allDataProvided = false;

      console.log('音频渲染器创建成功');
      this.statusMessage = '准备就绪';

    } catch (err) {
      console.error('初始化音频渲染器失败:', err.message, err.code);
      this.statusMessage = '音频初始化失败';
    }
  }

  // 播放内容 - 修复版本
  async playContent() {
    console.log('开始播放内容');

    if (!this.audioRenderer) {
      console.error('音频渲染器未初始化');
      this.statusMessage = '音频设备未就绪';
      return;
    }

    if (this.currentContent === '') {
      console.error('没有可播放的内容');
      this.statusMessage = '无可播放内容';
      return;
    }

    try {
      // 检查当前状态并采取相应措施
      console.log('当前音频渲染器状态:', this.currentAudioState);

      if (this.currentAudioState === audio.AudioState.STATE_RUNNING) {
        console.log('音频渲染器正在运行，先停止并刷新');
        await this.audioRenderer.stop();
        await this.audioRenderer.flush();
      } else if (this.currentAudioState === audio.AudioState.STATE_RELEASED) {
        console.log('音频渲染器已释放，需要重新初始化');
        await this.initAudioRenderer();
        if (!this.audioRenderer) {
          console.error('重新初始化音频渲染器失败');
          return;
        }
      }

      // 如果开启随机音调，确定本次播放的固定变调方向
      if (this.isRandomFrequencyEnabled) {
        this.currentDirection = Math.random() > 0.5 ? 1 : -1;
        console.log(`本次播放固定变调方向: ${this.currentDirection === 1 ? '向上' : '向下'}`);
      } else {
        this.currentDirection = 0;
      }

      // 重置答案提交状态
      this.isAnswerSubmitted = false;

      // 生成完整的PCM数据
      console.log('生成PCM音频数据');
      this.fullPcmData = this.generateFullPcmData();
      this.pcmDataOffset = 0;
      this.isPlaybackComplete = false;
      this.allDataProvided = false;

      // 设置writeData回调
      console.log('设置writeData回调');
      this.audioRenderer.off('writeData');
      this.audioRenderer.on('writeData', this.writeDataCallback);

      // 关键修复1：添加prepare()调用
      console.log('准备音频渲染器');

      // 启动播放
      console.log('启动音频渲染器');
      await this.audioRenderer.start();

      this.isPlaying = true;
      this.statusMessage = '播放中...';
      console.log('播放开始');

      // 记录开始时间并启动定时器
      this.startTime = new Date().getTime();
      this.elapsedTime = 0;
      this.elapsedTimeDisplay = '0秒';

      // 启动定时器，每秒更新用时
      this.clearTimer();
      this.timerId = setInterval(() => {
        const currentTime = new Date().getTime();
        this.elapsedTime = Math.floor((currentTime - this.startTime) / 1000);
        this.elapsedTimeDisplay = `${this.elapsedTime}秒`;
      }, 1000);

    } catch (error) {
      console.error('播放失败:', error);
      this.statusMessage = '播放失败';
    }
  }

  // 停止播放
  async stopPlayback() {
    console.log('停止播放');

    if (!this.audioRenderer) {
      console.log('音频渲染器不存在，无需停止');
      this.cleanupAfterStop();
      return;
    }

    console.log('当前音频状态:', this.currentAudioState);

    if (this.currentAudioState === audio.AudioState.STATE_RUNNING) {
      try {
        console.log('停止音频渲染器');
        await this.audioRenderer.stop();
        await this.audioRenderer.flush();
      } catch (error) {
        console.error('停止播放失败:', error);
        this.cleanupAfterStop();
      }
    } else {
      this.cleanupAfterStop();
    }

    this.statusMessage = '已停止';
    console.log('播放已停止');
  }

  // 释放音频渲染器
  async releaseAudioRenderer() {
    console.log('释放音频渲染器');

    await this.stopPlayback();

    if (this.audioRenderer) {
      try {
        this.audioRenderer.off('stateChange');
        this.audioRenderer.off('writeData');

        if (this.currentAudioState !== audio.AudioState.STATE_RELEASED) {
          await this.audioRenderer.release();
          console.log('音频渲染器已释放');
        } else {
          console.log('音频渲染器已处于释放状态，无需再次释放');
        }

        this.audioRenderer = null;
      } catch (err) {
        console.error('释放音频渲染器失败:', err.message);
      }
    }
  }

  // 生成新的随机内容
  generateNewContent() {
    let newContent = '';
    if (this.mode === 'word') {
      const randomIndex = Math.floor(Math.random() * WORD_LIST.length);
      newContent = WORD_LIST[randomIndex];
    } else {
      const randomIndex = Math.floor(Math.random() * SENTENCE_TEMPLATES.length);
      newContent = SENTENCE_TEMPLATES[randomIndex];
    }
    this.currentContent = newContent;
    this.correctAnswer = newContent;
    this.userInput = '';
    this.accuracy = 0;
    this.elapsedTime = 0;
    this.elapsedTimeDisplay = '0秒';
    this.morseCodeOfAnswer = this.convertToMorseString(newContent);
    this.isAnswerSubmitted = false;
    this.statusMessage = '新内容已生成，点击播放';
    console.log('生成新内容:', newContent);
  }

  private generateFullPcmData(): ArrayBuffer {
    console.log('生成PCM数据，当前内容:', this.currentContent);
    const timing = this.getTimingParameters(this.wpm);
    const sampleRate = 48000;
    const amplitude = 0.5;

    // 关键修复：使用第一个页面的简单逻辑
    // 1. 先转换为摩尔斯电码字符串
    const morseString = this.convertToMorseString(this.currentContent);
    console.log('摩尔斯电码字符串:', morseString);

    // 2. 计算总样本数（模仿第一个页面的逻辑）
    let totalSamples = 0;

    // 添加前导静音（50ms）
    const LEAD_SILENCE_SAMPLES = Math.floor(50 / 1000 * sampleRate);
    totalSamples += LEAD_SILENCE_SAMPLES;

    // 计算摩尔斯符号的样本数
    for (const symbol of morseString) {
      let duration: number;
      switch (symbol) {
        case '.':
          duration = timing.dotLength;
          break;
        case '-':
          duration = timing.dashLength;
          break;
        case ' ':
          duration = timing.interCharGap;
          break;
        case '/':
          duration = timing.wordGap;
          break;
        default:
          duration = 0; // 跳过未知字符
      }

      if (duration > 0) {
        totalSamples += Math.floor(duration / 1000 * sampleRate);
      }
    }

    console.log(`总样本数: ${totalSamples}`);

    // 3. 生成PCM数据
    const buffer = new ArrayBuffer(totalSamples * 4);
    const view = new DataView(buffer);
    let sampleOffset = 0;

    // 添加前导静音
    for (let i = 0; i < LEAD_SILENCE_SAMPLES; i++) {
      view.setFloat32(sampleOffset * 4, 0, true);
      sampleOffset++;
    }

    // 生成摩尔斯符号音频数据
    for (const symbol of morseString) {
      let duration: number;
      let isTone: boolean = false;

      switch (symbol) {
        case '.':
          duration = timing.dotLength;
          isTone = true;
          break;
        case '-':
          duration = timing.dashLength;
          isTone = true;
          break;
        case ' ':
          duration = timing.interCharGap;
          isTone = false;
          break;
        case '/':
          duration = timing.wordGap;
          isTone = false;
          break;
        default:
          continue; // 跳过未知字符
      }

      if (duration > 0) {
        const numSamples = Math.floor(duration / 1000 * sampleRate);

        // 计算当前符号的频率
        let symbolFrequency = this.frequency;
        if (isTone && this.isRandomFrequencyEnabled) {
          const randomOffset = 5 + Math.floor(Math.random() * 46); // 5~50Hz
          symbolFrequency = this.frequency + (this.currentDirection * randomOffset);
          symbolFrequency = Math.max(300, Math.min(1200, symbolFrequency));
        }

        this.generateSymbolAudio(view, sampleOffset, numSamples, sampleRate, amplitude, isTone, symbolFrequency);
        sampleOffset += numSamples;
      }
    }

    // 验证生成的数据大小
    const expectedSize = totalSamples * 4;
    const actualSize = buffer.byteLength;
    console.log(`PCM数据生成完成，大小: ${actualSize}字节（预期: ${expectedSize}字节）`);

    if (actualSize !== expectedSize) {
      console.error('PCM数据大小不匹配！这可能导致音频问题');
    }

    return buffer;
  }

  // 生成单个符号的音频数据
  private generateSymbolAudio(
    view: DataView,
    sampleOffset: number,
    numSamples: number,
    sampleRate: number,
    amplitude: number,
    isTone: boolean,
    frequency: number
  ): void {
    const byteOffset = sampleOffset * 4;
    for (let i = 0; i < numSamples; i++) {
      const value = isTone
        ? amplitude * Math.sin(2 * Math.PI * frequency * i / sampleRate)
        : 0;
      view.setFloat32(byteOffset + i * 4, value, true);
    }
  }

  // 将文本转换为摩尔斯电码字符串 - 确保与第一个页面一致
  private convertToMorseString(text: string): string {
    let morseString = '';
    const upperText = text.toUpperCase();

    for (let i = 0; i < upperText.length; i++) {
      const char = upperText[i];

      if (char === ' ') {
        morseString += '/ ';
        continue;
      }

      if (MORSE_CODE_MAP[char]) {
        const morseChar = MORSE_CODE_MAP[char];
        for (let j = 0; j < morseChar.length; j++) {
          morseString += morseChar[j];
          if (j < morseChar.length - 1) {
            morseString += ' ';
          }
        }

        if (i < upperText.length - 1 && upperText[i + 1] !== ' ') {
          morseString += '  ';
        }
      } else {
        morseString += '?? ';
      }
    }

    return morseString.trim();
  }
  // 检查用户输入
  async checkAnswer() {
    if (this.userInput.trim() === '') {
      this.promptAction.showToast({ message: '请输入内容', duration: 2000 });
      return;
    }

    this.clearTimer();
    this.isAnswerSubmitted = true;

    const endTime = new Date().getTime();
    this.elapsedTime = Math.floor((endTime - this.startTime) / 1000);
    this.elapsedTimeDisplay = `${this.elapsedTime}秒`;

    const userText = this.userInput.toUpperCase().trim();
    const correctText = this.correctAnswer.toUpperCase().trim();
    let correctCount = 0;
    const userWords = userText.split(/\s+/);
    const correctWords = correctText.split(/\s+/);

    for (let i = 0; i < Math.min(userWords.length, correctWords.length); i++) {
      if (userWords[i] === correctWords[i]) {
        correctCount++;
      }
    }

    this.accuracy = Math.round((correctCount / correctWords.length) * 100);
    this.statusMessage = `检查完成，正确率: ${this.accuracy}%`;

    try {
      await this.promptAction.showDialog({
        title: '答题结果',
        message: `正确答案: ${this.correctAnswer}\n\n` +
          `摩尔斯电码: ${this.morseCodeOfAnswer}\n\n` +
          `您的输入: ${this.userInput}\n\n` +
          `正确率: ${this.accuracy}%\n\n` +
          `用时: ${this.elapsedTimeDisplay}`,
        buttons: [
          {
            text: '确定',
            color: '#007DFF'
          }
        ]
      });
    } catch (error) {
      console.error('显示结果弹窗失败:', error);
    }

    this.promptAction.showToast({
      message: `已提交答案，正确率: ${this.accuracy}%`,
      duration: 2000
    });
  }

  // 切换模式
  switchMode(newMode: string) {
    this.mode = newMode;
    this.generateNewContent();
    this.promptAction.showToast({
      message: `已切换到${newMode === 'word' ? '单词' : '句子'}模式`,
      duration: 2000
    });
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        Text('摩尔斯电码听力训练')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 5 })

        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ bottom: 5 })

        // 模式选择
        Row({ space: 10 }) {
          Button('单词模式', { type: ButtonType.Capsule })
            .width(120)
            .backgroundColor(this.mode === 'word' ? Color.Blue : Color.Gray)
            .onClick(() => {
              this.switchMode('word');
            })
          Button('句子模式', { type: ButtonType.Capsule })
            .width(120)
            .backgroundColor(this.mode === 'sentence' ? Color.Blue : Color.Gray)
            .onClick(() => {
              this.switchMode('sentence');
            })
        }
        .margin({ bottom: 5 })

        // 生成新内容按钮
        Button('生成新内容', { type: ButtonType.Capsule })
          .width(160)
          .onClick(() => {
            this.generateNewContent();
          })
          .margin({ bottom: 5 })

        // 播放控制和用时显示
        Row({ space: 10 }) {
          Button(this.isPlaying ? '停止播放' : '播放内容', { type: ButtonType.Capsule })
            .width(120)
            .height(40)
            .backgroundColor(this.isPlaying ? Color.Red : Color.Green)
            .onClick(() => {
              if (this.isPlaying) {
                this.stopPlayback();
              } else {
                this.playContent();
              }
            })
          Text(`用时: ${this.elapsedTimeDisplay}`)
            .fontSize(16)
            .fontColor(Color.Black)
        }
        .margin({ bottom: 5 })

        // 随机音调开关
        Row({ space: 10 }) {
          Text('随机音调:')
            .fontSize(16)
          Toggle({ type: ToggleType.Switch, isOn: this.isRandomFrequencyEnabled })
            .onChange((isOn: boolean) => {
              this.isRandomFrequencyEnabled = isOn;
              this.statusMessage = isOn ? '随机音调已开启' : '随机音调已关闭';
            })
        }
        .margin({ bottom: 5 })

        // 用户输入
        TextInput({ placeholder: '输入您听到的内容', text: this.userInput })
          .width('90%')
          .height(50)
          .onChange((value: string) => {
            this.userInput = value;
          })
          .margin({ bottom: 5 })

        // 提交答案按钮
        Button('提交答案', { type: ButtonType.Capsule })
          .width(120)
          .onClick(() => {
            this.checkAnswer();
          })
          .margin({ bottom: 5 })

        // 音调控制
        Row({ space: 10 }) {
          Text(`频率: ${this.frequency}Hz`)
            .fontSize(16)
        }

        Slider({
          value: this.frequency,
          min: 300,
          max: 1200,
          step: 10,
          style: SliderStyle.OutSet
        })
          .width('85%')
          .onChange((value: number) => {
            this.frequency = value;
          })
          .margin({ bottom: 5 })

        // 速度控制
        Text(`速度: ${this.wpm} WPM (单词/分钟)`)
          .fontSize(16)
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
          .margin({ bottom: 5 })

        // 使用说明
        Text('使用说明: 选择模式后生成内容，播放并输入听到的内容。支持调速和随机音调。')
          .fontSize(12)
          .fontColor(Color.Gray)
          .width('85%')
          .textAlign(TextAlign.Center)
          .margin({ top: 5 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .padding(10)
    }
    .onBackPressed(() => {
      this.index.pop()
      return true
    })
  }

  private stateChangeCallback: (state: audio.AudioState) => void = () => {
  };

  // 清除定时器
  private clearTimer() {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
  }

  // 设置状态变化监听器
  private setupStateChangeListener() {
    if (!this.audioRenderer) {
      return;
    }

    this.stateChangeCallback = (state: audio.AudioState) => {
      console.log('音频渲染器状态变化:', this.currentAudioState, '->', state);
      this.currentAudioState = state;
      this.handleStateChange(state);
    };

    this.audioRenderer.on('stateChange', this.stateChangeCallback);
    console.log('状态变化监听器设置成功');
  }

  // 处理状态变化
  private handleStateChange(state: audio.AudioState) {
    switch (state) {
      case audio.AudioState.STATE_RUNNING:
        console.log('音频渲染器已启动');
        break;

      case audio.AudioState.STATE_STOPPED:
        console.log('音频渲染器已停止');
        this.cleanupAfterStop();
        break;

      case audio.AudioState.STATE_PAUSED:
        console.log('音频渲染器已暂停');
        break;

      case audio.AudioState.STATE_RELEASED:
        console.log('音频渲染器已释放');
        break;

      default:
        console.log('未知音频渲染器状态:', state);
    }
  }

  // 停止后清理资源
  private cleanupAfterStop() {
    this.isPlaying = false;
    this.isPlaybackComplete = true;
    this.allDataProvided = false;

    this.fullPcmData = null;
    this.pcmDataOffset = 0;

    this.clearTimer();
    console.log('播放资源已清理');
  }


  // writeData事件回调 - 关键修复2：移除setTimeout延迟
  // writeData事件回调 - 完全修复版本
  private writeDataCallback = (buffer: ArrayBuffer): audio.AudioDataCallbackResult => {
    if (!this.fullPcmData) {
      console.log('没有PCM数据可提供');
      this.fillSilence(buffer);
      return audio.AudioDataCallbackResult.INVALID;
    }

    // 如果已经标记为播放完成，不再提供数据
    if (this.isPlaybackComplete) {
      console.log('播放已完成，不再提供数据');
      this.fillSilence(buffer);
      return audio.AudioDataCallbackResult.INVALID;
    }

    const outputView = new DataView(buffer);
    const remainingBytes = this.fullPcmData.byteLength - this.pcmDataOffset;
    const bytesToCopy = Math.min(remainingBytes, buffer.byteLength);

    if (bytesToCopy > 0) {
      // 从预生成的PCM数据复制到输出缓冲区
      const sourceView = new DataView(this.fullPcmData, this.pcmDataOffset, bytesToCopy);

      // 使用更高效的数据复制方式
      for (let i = 0; i < bytesToCopy; i += 4) {
        outputView.setFloat32(i, sourceView.getFloat32(i, true), true);
      }

      // 如果缓冲区未填满，剩余部分填充静音
      if (bytesToCopy < buffer.byteLength) {
        for (let i = bytesToCopy; i < buffer.byteLength; i += 4) {
          outputView.setFloat32(i, 0, true);
        }
      }

      this.pcmDataOffset += bytesToCopy;
      console.log(`已提供 ${bytesToCopy} 字节数据，总进度: ${this.pcmDataOffset}/${this.fullPcmData.byteLength}`);

      // 检查是否所有数据都已提供
      if (this.pcmDataOffset >= this.fullPcmData.byteLength) {
        console.log('所有数据已提供，等待播放完成');
        this.allDataProvided = true;
      }

      return audio.AudioDataCallbackResult.VALID;
    } else if (this.allDataProvided) {
      // 所有数据已提供且已复制完毕，现在可以标记为播放完成
      console.log('所有数据已播放完毕');
      this.finishPlayback();
      this.fillSilence(buffer);
      return audio.AudioDataCallbackResult.INVALID;
    }

    // 没有数据可提供时填充静音
    this.fillSilence(buffer);
    return audio.AudioDataCallbackResult.INVALID;
  };

  // 填充静音数据的辅助方法
  private fillSilence(buffer: ArrayBuffer): void {
    const view = new DataView(buffer);
    for (let i = 0; i < buffer.byteLength; i += 4) {
      view.setFloat32(i, 0, true);
    }
  }

  // 完成播放处理 - 确保状态一致性
  private finishPlayback(): void {
    // 确保只执行一次完成操作
    if (this.isPlaybackComplete) {
      return;
    }

    console.log('播放完成');
    this.isPlaying = false;
    this.isPlaybackComplete = true;
    this.allDataProvided = false;
    this.statusMessage = '播放完成';

    // 释放PCM数据内存
    this.fullPcmData = null;
    this.pcmDataOffset = 0;

    // 移除writeData回调，避免后续调用
    if (this.audioRenderer) {
      this.audioRenderer.off('writeData');
    }

    this.clearTimer();
  }

}
