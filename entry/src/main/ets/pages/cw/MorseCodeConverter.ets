// MorseCodeConverter.ets
import audio from '@ohos.multimedia.audio';
import { PromptAction } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import camera from '@ohos.multimedia.camera';

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

interface MorseCommand {
  type: 'dot' | 'dash' | 'gap';
  duration: number;
}

interface MorseTiming {
  dot: number;
  dash: number;
  gap: number;
}

@Component
export struct MorseCodeConverter {
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @Consume('index') index: NavPathStack;
  // 状态变量
  @State inputText: string = '';
  @State morseCode: string = '';
  @State isPlaying: boolean = false;
  @State frequency: number = 600;
  @State wpm: number = 15;
  @State statusMessage: string = '准备就绪';
  @State isFlashlightOn: boolean = false;

  // 音频渲染器和相关状态
  private audioRenderer: audio.AudioRenderer | null = null;
  private isAborted: boolean = false;

  private stateChangeCallback: (state: audio.AudioState) => void = () => {};
  private currentAudioState: audio.AudioState = audio.AudioState.STATE_NEW;
  //手电筒相关
  private Context: Context | undefined = undefined;
  private torchSupport: boolean = false;

  // PCM数据管理
  private fullPcmData: ArrayBuffer | null = null;
  private pcmDataOffset: number = 0;
  private isPlaybackComplete: boolean = false;
  private allDataProvided: boolean = false;

  // 添加音频缓冲区大小常量
  private readonly BUFFER_SIZE: number = 4096; // 4KB缓冲区

  async init_camera() {
    try {
      this.Context = this.getUIContext().getHostContext();
      let cameraManager = camera.getCameraManager(this.Context);
      this.torchSupport = cameraManager.isTorchSupported();
    } catch (error) {
      console.error('初始化相机失败:', error);
      this.torchSupport = false;
    }
  }

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
    this.init_camera();
  }

  aboutToDisappear() {
    console.log('页面即将消失，释放音频渲染器');
    this.releaseAudioRenderer();
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

      console.log('音频渲染器创建成功');
      this.statusMessage = '准备就绪';

    } catch (err) {
      console.error('初始化音频渲染器失败:', err.message, err.code);
      this.statusMessage = '音频初始化失败';
    }
  }

  // 设置状态变化监听器
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

  // 处理状态变化
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

  // 停止后清理资源
  private cleanupAfterStop() {
    this.isPlaying = false;
    this.isPlaybackComplete = true;
    this.allDataProvided = false;

    // 释放PCM数据内存
    this.fullPcmData = null;
    this.pcmDataOffset = 0;

    console.log('播放资源已清理');
  }

  // 生成单个符号的音频数据
  private generateSymbolAudio(
    view: DataView,
    sampleOffset: number,
    numSamples: number,
    sampleRate: number,
    amplitude: number,
    isTone: boolean
  ): void {
    const byteOffset = sampleOffset * 4;

    for (let i = 0; i < numSamples; i++) {
      const value = isTone
        ? amplitude * Math.sin(2 * Math.PI * this.frequency * i / sampleRate)
        : 0;
      view.setFloat32(byteOffset + i * 4, value, true);
    }
  }

  // writeData事件回调
  private writeDataCallback = (buffer: ArrayBuffer): audio.AudioDataCallbackResult => {
    if (!this.fullPcmData) {
      console.log('没有PCM数据可提供');
      // 填充静音数据
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
    const remainingData = this.fullPcmData.byteLength - this.pcmDataOffset;
    const bytesToCopy = Math.min(remainingData, buffer.byteLength);

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


  // 完成播放处理
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
  }

  // 转换文本为摩尔斯电码
  convertToMorse() {
    if (this.inputText.trim() === '') {
      this.promptAction.showToast({ message: '请输入文本', duration: 2000 });
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
        for (let j = 0; j < morseChar.length; j++) {
          this.morseCode += morseChar[j];
          if (j < morseChar.length - 1) {
            this.morseCode += ' ';
          }
        }

        if (i < text.length - 1 && text[i + 1] !== ' ') {
          this.morseCode += '  ';
        }
      } else {
        this.morseCode += '?? ';
      }
    }

    this.morseCode = this.morseCode.trim();
    this.statusMessage = '转换完成，可点击播放';
  }

  // 打开手电筒
  async turnOnFlashlight() {
    try {
      if (!this.Context) {
        this.Context = this.getUIContext().getHostContext();
      }

      let cameraManager = camera.getCameraManager(this.Context);
      // 设置闪光灯模式为常开
      await cameraManager.setTorchMode(1);
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
      if (!this.Context) {
        this.Context = this.getUIContext().getHostContext();
      }

      let cameraManager = camera.getCameraManager(this.Context);
      // 设置闪光灯模式为关闭
      await cameraManager.setTorchMode(0);
      this.isFlashlightOn = false;
      this.statusMessage = '手电筒已关闭';
      console.log('手电筒已关闭');
    } catch (error) {
      console.error('关闭手电筒失败:', error);
      this.statusMessage = '关闭手电筒失败';
    }
  }

  // 释放音频渲染器
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

  // 同步播放音频和闪光灯的方法 - 最终修复版本
  async syncFlashlightWithAudio(): Promise<void> {
    if (!this.morseCode) {
      this.promptAction.showToast({ message: '请先转换摩尔斯电码', duration: 2000 });
      return;
    }

    if (!this.torchSupport) {
      this.promptAction.showToast({ message: '设备不支持闪光灯', duration: 2000 });
      return;
    }

    if (this.isPlaying) {
      this.promptAction.showToast({ message: '请先停止当前播放', duration: 2000 });
      return;
    }

    this.isPlaying = true;
    this.statusMessage = '音频和闪光灯同步播放中...';

    // 创建一个新的音频渲染器实例，避免状态冲突
    let syncAudioRenderer: audio.AudioRenderer | null = null;

    try {
      // 创建专门的音频渲染器用于同步播放
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

      syncAudioRenderer = await audio.createAudioRenderer(audioRendererOptions);

      if (!syncAudioRenderer) {
        throw new Error('无法创建同步音频渲染器');
      }

      const timing = this.getTimingParameters(this.wpm);

      // 解析摩尔斯电码序列
      const commands: MorseCommand[] = [];

      for (const symbol of this.morseCode) {
        switch (symbol) {
          case '.':
            commands.push({ type: 'dot', duration: timing.dotLength });
            commands.push({ type: 'gap', duration: timing.intraCharGap });
            break;
          case '-':
            commands.push({ type: 'dash', duration: timing.dashLength });
            commands.push({ type: 'gap', duration: timing.intraCharGap });
            break;
          case ' ':
            commands.push({ type: 'gap', duration: timing.interCharGap - timing.intraCharGap });
            break;
          case '/':
            commands.push({ type: 'gap', duration: timing.wordGap - timing.intraCharGap });
            break;
        }
      }

      // 生成完整的PCM数据
      const fullPcmData = this.generateFullPcmData();
      let pcmDataOffset = 0;
      let isPlaybackComplete = false;
      let allDataProvided = false;

      // 创建专门的writeData回调
      const writeDataCallback = (buffer: ArrayBuffer): audio.AudioDataCallbackResult => {
        if (!fullPcmData) {
          this.fillSilence(buffer);
          return audio.AudioDataCallbackResult.INVALID;
        }

        if (isPlaybackComplete) {
          this.fillSilence(buffer);
          return audio.AudioDataCallbackResult.INVALID;
        }

        const outputView = new DataView(buffer);
        const remainingData = fullPcmData.byteLength - pcmDataOffset;
        const bytesToCopy = Math.min(remainingData, buffer.byteLength);

        if (bytesToCopy > 0) {
          const sourceView = new DataView(fullPcmData, pcmDataOffset, bytesToCopy);

          for (let i = 0; i < bytesToCopy; i += 4) {
            outputView.setFloat32(i, sourceView.getFloat32(i, true), true);
          }

          if (bytesToCopy < buffer.byteLength) {
            for (let i = bytesToCopy; i < buffer.byteLength; i += 4) {
              outputView.setFloat32(i, 0, true);
            }
          }

          pcmDataOffset += bytesToCopy;
          console.log(`同步播放已提供 ${bytesToCopy} 字节数据`);

          if (pcmDataOffset >= fullPcmData.byteLength) {
            allDataProvided = true;
          }

          return audio.AudioDataCallbackResult.VALID;
        } else if (allDataProvided) {
          isPlaybackComplete = true;
          this.fillSilence(buffer);
          return audio.AudioDataCallbackResult.INVALID;
        }

        this.fillSilence(buffer);
        return audio.AudioDataCallbackResult.INVALID;
      };

      // 设置writeData回调
      syncAudioRenderer.on('writeData', writeDataCallback);

      // 启动音频播放
      await syncAudioRenderer.start();

      // 关键修复：等待音频渲染器完全启动
      // 添加一个短暂的延迟，确保音频渲染器完全初始化
      await new Promise<void>(resolve => setTimeout(resolve, 50));

      // 同步控制闪光灯
      for (let i = 0; i < commands.length; i++) {
        if (!this.isPlaying) break; // 允许中途停止

        const command = commands[i];

        if (command.type === 'dot' || command.type === 'dash') {
          // 打开闪光灯
          await this.turnOnFlashlight();
          // 等待符号持续时间
          await new Promise<void>(resolve => setTimeout(resolve, command.duration));
          // 关闭闪光灯
          await this.turnOffFlashlight();
        } else if (command.type === 'gap') {
          // 保持闪光灯关闭状态
          await new Promise<void>(resolve => setTimeout(resolve, command.duration));
        }
      }

      // 等待音频播放完成
      let waitCount = 0;
      while (!isPlaybackComplete && this.isPlaying && waitCount < 50) {
        await new Promise<void>(resolve => setTimeout(resolve, 100));
        waitCount++;
      }

      this.statusMessage = '同步播放完成';
    } catch (error) {
      console.error('同步播放失败:', error);
      this.statusMessage = '同步播放失败';
    } finally {
      // 确保最终关闭闪光灯
      if (this.isFlashlightOn) {
        await this.turnOffFlashlight();
      }

      // 停止并释放同步音频渲染器
      if (syncAudioRenderer) {
        try {
          const state = syncAudioRenderer.state;
          if (state === audio.AudioState.STATE_RUNNING) {
            await syncAudioRenderer.stop();
            await syncAudioRenderer.flush(); // 关键修复：刷新缓冲区
          }
          if (state !== audio.AudioState.STATE_RELEASED) {
            await syncAudioRenderer.release();
          }
        } catch (e) {
          console.error('释放同步音频渲染器失败:', e);
        }
      }

      this.isPlaying = false;
    }
  }

  // 播放摩尔斯电码音频 - 最终修复版本
  async playMorseCode() {
    console.log('开始播放摩尔斯电码');

    if (!this.audioRenderer) {
      console.error('音频渲染器未初始化');
      this.statusMessage = '音频设备未就绪';
      return;
    }

    if (this.morseCode === '') {
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
        await this.audioRenderer.flush(); // 关键修复：刷新缓冲区
      } else if (this.currentAudioState === audio.AudioState.STATE_RELEASED) {
        console.log('音频渲染器已释放，需要重新初始化');
        await this.initAudioRenderer();
        if (!this.audioRenderer) {
          console.error('重新初始化音频渲染器失败');
          return;
        }
      }

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

      // 关键修复：等待音频渲染器完全启动
      // 添加一个短暂的延迟，确保音频渲染器完全初始化
      await new Promise<void>(resolve => setTimeout(resolve, 50));

      this.isPlaying = true;
      this.statusMessage = '播放中...';
      console.log('播放开始');

    } catch (error) {
      console.error('播放失败:', error);
      this.statusMessage = '播放失败';
      this.isPlaying = false;
    }
  }

  // 停止播放 - 最终修复版本
  async stopPlayback(): Promise<void> {
    console.log('停止播放');

    // 停止闪光灯播放
    this.isPlaying = false;

    if (this.audioRenderer) {
      // 原有的音频停止逻辑
      console.log('当前音频状态:', this.currentAudioState);

      if (this.currentAudioState === audio.AudioState.STATE_RUNNING) {
        try {
          console.log('停止音频渲染器');
          await this.audioRenderer.stop();
          await this.audioRenderer.flush(); // 关键修复：刷新缓冲区
        } catch (error) {
          console.error('停止播放失败:', error);
        }
      }
    }

    // 确保关闭闪光灯
    if (this.isFlashlightOn) {
      await this.turnOffFlashlight();
    }

    this.statusMessage = '已停止';
    console.log('播放已停止');
  }

  // 生成完整的PCM音频数据 - 改进版本
  private generateFullPcmData(): ArrayBuffer {
    console.log('生成完整的PCM音频数据');
    const timing = this.getTimingParameters(this.wpm);
    const sampleRate = 48000;
    const amplitude = 0.5;

    // 计算总样本数
    let totalSamples = 0;
    for (const symbol of this.morseCode) {
      let duration: number;
      switch (symbol) {
        case '.': duration = timing.dotLength; break;
        case '-': duration = timing.dashLength; break;
        case ' ': duration = timing.interCharGap; break;
        case '/': duration = timing.wordGap; break;
        default: duration = 0;
      }
      totalSamples += Math.floor(duration / 1000 * sampleRate);
    }

    // 关键修复：添加前导静音，确保音频渲染器有足够时间初始化
    const LEAD_SILENCE_SAMPLES = Math.floor(50 / 1000 * sampleRate); // 50ms静音
    totalSamples += LEAD_SILENCE_SAMPLES;

    console.log(`总样本数: ${totalSamples}`);
    const buffer = new ArrayBuffer(totalSamples * 4);
    const view = new DataView(buffer);
    let sampleOffset = 0;

    // 关键修复：添加前导静音
    for (let i = 0; i < LEAD_SILENCE_SAMPLES; i++) {
      view.setFloat32(sampleOffset * 4, 0, true);
      sampleOffset++;
    }

    // 生成所有音频数据
    for (const symbol of this.morseCode) {
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
          duration = 0;
          isTone = false;
      }

      if (duration > 0) {
        const numSamples = Math.floor(duration / 1000 * sampleRate);
        this.generateSymbolAudio(view, sampleOffset, numSamples, sampleRate, amplitude, isTone);
        sampleOffset += numSamples;
      }
    }

    console.log(`PCM数据生成完成，总大小: ${buffer.byteLength} 字节`);
    return buffer;
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
        Text('摩尔斯电码转换器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })

        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ bottom: 5 })

        TextInput({ placeholder: '输入要转换的文本（字母、数字、符号）', text: this.inputText })
          .width('90%')
          .height(60)
          .onChange((value: string) => {
            this.inputText = value;
          })

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

        Row() {
          Button(this.isPlaying ? '停止播放' : '播放音频', { type: ButtonType.Capsule })
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
            .margin({ top: 5, bottom: 5 })

          Button('闪光灯模式')
            .onClick(() => {
              this.syncFlashlightWithAudio();
            })
        }

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

        Text(`速度: ${this.wpm} WPM (单词/分钟)`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

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

        Text(`当前时间参数: 点=${this.calculateDotLength(this.wpm).toFixed(0)}ms, 划=${(3 *
        this.calculateDotLength(this.wpm)).toFixed(0)}ms`)
          .fontSize(12)
          .fontColor(Color.Gray)

        Text('使用说明:第一次播放可能出现错误，请重试一次， 输入文本后点击转换，然后播放音频。支持字母、数字和常用符号。')
          .fontSize(12)
          .fontColor(Color.Gray)
          .width('85%')
          .textAlign(TextAlign.Center)
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
