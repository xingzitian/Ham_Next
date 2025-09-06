// MorseTraining.ets
import audio from '@ohos.multimedia.audio';

import {  PromptAction } from '@kit.ArkUI';
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
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
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

  // 音频渲染器和相关状态（根据原始示例优化）
  private audioRenderer: audio.AudioRenderer | null = null;
  private isAborted: boolean = false; // 新增：中止标志

  private stateChangeCallback: (state: audio.AudioState) => void = () => {};
  private currentAudioState: audio.AudioState = audio.AudioState.STATE_NEW;

  // PCM数据管理（根据原始示例优化）
  private fullPcmData: ArrayBuffer | null = null;
  private pcmDataOffset: number = 0;
  private isPlaybackComplete: boolean = false;
  private allDataProvided: boolean = false;
  private timerId: number = 0;
  private currentDirection: number = 0; // 本次播放的固定变调方向（-1: 向下, 0: 不变, 1: 向上）



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

  // 清除定时器
  private clearTimer() {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }
  }

  // 初始化音频渲染器（根据原始示例优化）
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
      this.isAborted = false;
      this.isPlaybackComplete = false;
      this.allDataProvided = false;

      console.log('音频渲染器创建成功');
      this.statusMessage = '准备就绪';

    } catch (err) {
      console.error('初始化音频渲染器失败:', err.message, err.code);
      this.statusMessage = '音频初始化失败';
    }
  }

  // 设置状态变化监听器（根据原始示例优化）
  private setupStateChangeListener() {
    if (!this.audioRenderer) return;

    // 设置状态变化监听器
    this.stateChangeCallback = (state: audio.AudioState) => {
      console.log('音频渲染器状态变化:', this.currentAudioState, '->', state);
      this.currentAudioState = state;

      // 根据状态变化执行相应操作
      this.handleStateChange(state);
    };

    this.audioRenderer.on('stateChange', this.stateChangeCallback);
    console.log('状态变化监听器设置成功');
  }

  // 处理状态变化（根据原始示例优化）
  private handleStateChange(state: audio.AudioState) {
    switch (state) {
      case audio.AudioState.STATE_RUNNING:
        console.log('音频渲染器已启动');
        break;

      case audio.AudioState.STATE_STOPPED:
        console.log('音频渲染器已停止');
        // 停止播放后清理资源
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

  // 停止后清理资源（根据原始示例优化）
  private cleanupAfterStop() {
    this.isPlaying = false;
    this.isPlaybackComplete = true;
    this.allDataProvided = false;

    // 释放PCM数据内存
    this.fullPcmData = null;
    this.pcmDataOffset = 0;

    this.clearTimer();
    console.log('播放资源已清理');
  }

  // 生成完整的PCM音频数据（修改：固定方向，每个符号独立随机变化）
  private generateFullPcmData(): ArrayBuffer {
    console.log('生成PCM数据，当前内容:', this.currentContent);
    const timing = this.getTimingParameters(this.wpm);
    const sampleRate = 48000; // 音频采样率（固定）
    const amplitude = 0.5;    // 音量（0-1，避免过载）

    // --------------------------
    // 关键修复1：正确构建摩尔斯符号数组（含所有符号和间隔）
    // --------------------------
    const morseSymbols: string[] = [];
    const upperText = this.currentContent.toUpperCase();

    for (let i = 0; i < upperText.length; i++) {
      const char = upperText[i];

      // 1. 处理空格（单词间隔）
      if (char === ' ') {
        morseSymbols.push('/'); // 空格对应单词间隔符'/'
        continue;
      }

      // 2. 处理已知字符（转换为摩尔斯符号+字符内间隔）
      const charMorse = MORSE_CODE_MAP[char];
      if (charMorse) {
        // 拆分单个字符的摩尔斯符号（如 ".-" → [".", "-"]）
        const charSymbols = charMorse.split('');
        for (let j = 0; j < charSymbols.length; j++) {
          morseSymbols.push(charSymbols[j]); // 添加符号（. 或 -）
          // 字符内符号间隔：除了最后一个符号，都加间隔符' '
          if (j < charSymbols.length - 1) {
            morseSymbols.push(' ');
          }
        }

        // 字符间间隔：除了最后一个字符，都加间隔符' '
        if (i < upperText.length - 1 && upperText[i + 1] !== ' ') {
          morseSymbols.push(' ');
        }
      } else {
        // 3. 处理未知字符（跳过，避免截断后续符号）
        console.warn(`未知字符: ${char}，已跳过`);
      }
    }

    // 日志验证：确保符号数组完整（如HELLO应包含23个符号+间隔）
    console.log('完整符号数组:', morseSymbols, '总符号数:', morseSymbols.length);

    // --------------------------
    // 关键修复2：正确计算总样本数（毫秒→秒，避免截断）
    // --------------------------
    let totalSamples = 0;
    for (const symbol of morseSymbols) {
      let durationMs = 0;
      // 根据符号类型获取对应时长（ms）
      switch (symbol) {
        case '.': durationMs = timing.dotLength; break;
        case '-': durationMs = timing.dashLength; break;
        case ' ': durationMs = timing.intraCharGap; break; // 字符内/间间隔都是同一个时长
        case '/': durationMs = timing.wordGap; break;
      }

      // 毫秒转秒，计算样本数（四舍五入避免累积误差）
      const durationSec = durationMs / 1000;
      const symbolSamples = Math.round(durationSec * sampleRate);
      totalSamples += symbolSamples;

      // 日志验证：每个符号的时长和样本数
      console.log(`符号: ${symbol}，时长: ${durationMs}ms，样本数: ${symbolSamples}`);
    }

    // 验证总时长（确保与预期一致，如HELLO≈1.5秒）
    const totalDurationSec = totalSamples / sampleRate;
    console.log(`总样本数: ${totalSamples}，总时长: ${totalDurationSec.toFixed(2)}秒`);

    // --------------------------
    // 生成PCM数据（无逻辑修改，仅用修复后的符号数组）
    // --------------------------
    const buffer = new ArrayBuffer(totalSamples * 4); // F32LE：4字节/样本
    const view = new DataView(buffer);
    let sampleOffset = 0;

    for (const symbol of morseSymbols) {
      let durationMs = 0;
      let isTone = false;

      // 确定当前符号的时长和是否为音调（.和-是音调，空格和/是静音）
      switch (symbol) {
        case '.':
          durationMs = timing.dotLength;
          isTone = true;
          break;
        case '-':
          durationMs = timing.dashLength;
          isTone = true;
          break;
        case ' ':
          durationMs = timing.intraCharGap;
          isTone = false;
          break;
        case '/':
          durationMs = timing.wordGap;
          isTone = false;
          break;
        default:
          continue; // 跳过未知符号
      }

      if (durationMs <= 0) continue;

      // 计算当前符号的样本数
      const durationSec = durationMs / 1000;
      const numSamples = Math.round(durationSec * sampleRate);
      // 计算当前符号的频率（随机音调逻辑不变）
      let symbolFrequency = this.frequency;
      if (isTone && this.isRandomFrequencyEnabled) {
        const maxOffset = 50;
        const randomOffset = 5 + Math.floor(Math.random() * 46); // 5~50Hz
        symbolFrequency = this.frequency + (this.currentDirection * randomOffset);
        symbolFrequency = Math.max(300, Math.min(1200, symbolFrequency)); // 边界保护
      }

      // 生成单个符号的音频数据
      this.generateSymbolAudio(view, sampleOffset, numSamples, sampleRate, amplitude, isTone, symbolFrequency);
      sampleOffset += numSamples;
    }

    console.log(`PCM数据生成完成，大小: ${buffer.byteLength}字节（预期: ${totalSamples*4}字节）`);
    // 关键校验：确保生成的缓冲区大小与预期一致（避免数据截断）
    if (buffer.byteLength !== totalSamples * 4) {
      console.error('PCM数据大小不匹配！预期:', totalSamples*4, '实际:', buffer.byteLength);
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

  // writeData事件回调（根据原始示例优化）
  private writeDataCallback = (buffer: ArrayBuffer): audio.AudioDataCallbackResult => {
    if (!this.fullPcmData || this.isPlaybackComplete) {
      console.log('无PCM数据或已播放完成');
      return audio.AudioDataCallbackResult.INVALID;
    }

    const outputView = new DataView(buffer);
    const remainingBytes = this.fullPcmData.byteLength - this.pcmDataOffset;
    const bytesToCopy = Math.min(remainingBytes, buffer.byteLength);

    if (bytesToCopy > 0) {
      // 复制数据到输出缓冲区
      const sourceView = new DataView(this.fullPcmData, this.pcmDataOffset, bytesToCopy);
      for (let i = 0; i < bytesToCopy; i += 4) {
        outputView.setFloat32(i, sourceView.getFloat32(i, true), true);
      }
      this.pcmDataOffset += bytesToCopy;
      console.log(`已提供 ${bytesToCopy} 字节，进度: ${(this.pcmDataOffset / this.fullPcmData.byteLength * 100).toFixed(1)}%`);
      return audio.AudioDataCallbackResult.VALID;
    } else {
      // 所有数据已复制到系统缓冲区，等待系统播放完成（延迟100ms再标记完成）
      setTimeout(() => {
        if (!this.isPlaybackComplete) {
          this.finishPlayback();
        }
      }, 100); // 给系统100ms播放缓冲区剩余数据
      return audio.AudioDataCallbackResult.INVALID;
    }
  };

  // 完成播放处理（根据原始示例优化）
  private finishPlayback(): void {
    // 确保只执行一次完成操作
    if (this.isPlaybackComplete) return;

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

    // 清除定时器
    this.clearTimer();
  }

  // 播放内容（根据原始示例优化）
  // 播放内容（修改：固定变调方向和基本大小）
  // 播放内容（修改：确定固定变调方向，每个符号独立随机变化）
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
        // 随机选择变调方向（-1 或 1）
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

  // 停止播放（根据原始示例优化）
  async stopPlayback() {
    console.log('停止播放');

    if (!this.audioRenderer) {
      console.log('音频渲染器不存在，无需停止');
      this.cleanupAfterStop();
      return;
    }

    // 根据当前状态决定如何停止
    console.log('当前音频状态:', this.currentAudioState);

    if (this.currentAudioState === audio.AudioState.STATE_RUNNING) {
      try {
        console.log('停止音频渲染器');
        await this.audioRenderer.stop();
        // flush操作会在停止后自动执行
      } catch (error) {
        console.error('停止播放失败:', error);
        // 即使停止失败，也执行清理操作
        this.cleanupAfterStop();
      }
    } else {
      // 如果不在运行状态，直接执行清理
      this.cleanupAfterStop();
    }

    this.statusMessage = '已停止';
    console.log('播放已停止');
  }

  // 释放音频渲染器（根据原始示例优化）
  async releaseAudioRenderer() {
    console.log('释放音频渲染器');

    // 先停止播放
    await this.stopPlayback();

    if (this.audioRenderer) {
      try {
        // 移除事件监听器
        this.audioRenderer.off('stateChange');
        this.audioRenderer.off('writeData');

        // 检查当前状态，只有在非RELEASED状态下才调用release
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

  // 将文本转换为摩尔斯电码字符串
  convertToMorseString(text: string): string {
    let morseString = '';
    const upperText = text.toUpperCase();
    for (let i = 0; i < upperText.length; i++) {
      const char = upperText[i];
      if (char === ' ') {
        morseString += '/ ';
      } else if (MORSE_CODE_MAP[char]) {
        morseString += MORSE_CODE_MAP[char] + ' ';
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

    // 停止定时器
    this.clearTimer();

    // 标记已提交答案
    this.isAnswerSubmitted = true;

    // 计算所用时间
    const endTime = new Date().getTime();
    this.elapsedTime = Math.floor((endTime - this.startTime) / 1000);
    this.elapsedTimeDisplay = `${this.elapsedTime}秒`;

    // 比较用户输入和正确答案
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

    // 使用showDialog显示结果
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

    // 显示简短提示
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
}
