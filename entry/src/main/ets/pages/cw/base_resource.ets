interface cw{
  字符: string,
  电码: string
}

interface q{
  Q简语:string,
  含义:string
}

interface phonetic{
  letter:string,
  phonetic:string
}

let morseCodeTable:Array<cw> = [
// 数字（0-9）
  { "字符": "0", "电码": "-----" },       // 原电码多了一个点，标准为5个短横线
  { "字符": "1", "电码": ".----" },
  { "字符": "2", "电码": "..---" },
  { "字符": "3", "电码": "...--" },
  { "字符": "4", "电码": "....-" },
  { "字符": "5", "电码": "....." },
  { "字符": "6", "电码": "-...." },
  { "字符": "7", "电码": "--..." },
  { "字符": "8", "电码": "---.." },
  { "字符": "9", "电码": "----." },       // 原电码多了一个点，标准为4个短横线加1个点

  // 字母（A-Z）
  { "字符": "A", "电码": ".-" },
  { "字符": "B", "电码": "-..." },
  { "字符": "C", "电码": "-.-." },
  { "字符": "D", "电码": "-.." },
  { "字符": "E", "电码": "." },           // 原电码为"-"，标准为单个点
  { "字符": "F", "电码": "..-." },
  { "字符": "G", "电码": "--." },
  { "字符": "H", "电码": "...." },
  { "字符": "I", "电码": ".." },
  { "字符": "J", "电码": ".---" },
  { "字符": "K", "电码": "-.-" },
  { "字符": "L", "电码": ".-.." },
  { "字符": "M", "电码": "--" },
  { "字符": "N", "电码": "-." },
  { "字符": "O", "电码": "---" },
  { "字符": "P", "电码": ".--." },
  { "字符": "Q", "电码": "--.-" },
  { "字符": "R", "电码": ".-." },
  { "字符": "S", "电码": "..." },
  { "字符": "T", "电码": "-" },
  { "字符": "U", "电码": "..-" },
  { "字符": "V", "电码": "...-" },
  { "字符": "W", "电码": ".--" },
  { "字符": "X", "电码": "-..-" },
  { "字符": "Y", "电码": "-.--" },
  { "字符": "Z", "电码": "--.." },

  // 特殊字符
  { "字符": "/", "电码": "-..-." },
  { "字符": "?", "电码": "..--.." }
];


let q_phrases:Array<q> = [
  {"Q简语": "QRA", "含义": "你的电台名称是？"},
  {"Q简语": "QRB", "含义": "你台离我台多远？"},
  {"Q简语": "QRG", "含义": "我的准确频率是多少？"},
  {"Q简语": "QRI", "含义": "我的音调如何？"},
  {"Q简语": "QRJ", "含义": "我的信号小吗？"},
  {"Q简语": "QRK", "含义": "我的信号可辩度是多少？"},
  {"Q简语": "QRL", "含义": "你忙吗？"},
  {"Q简语": "QRM", "含义": "你受到他台干扰吗？"},
  {"Q简语": "QRN", "含义": "你受到天电干扰吗？"},
  {"Q简语": "QRO", "含义": "要我增加发信功率吗？"},
  {"Q简语": "QRP", "含义": "要我减低发信功率吗？"},
  {"Q简语": "QRQ", "含义": "要我发得快些吗？"},
  {"Q简语": "QRS", "含义": "要我发得慢些吗？"},
  {"Q简语": "QRT", "含义": "要我停止拍发吗？"},
  {"Q简语": "QRU", "含义": "你有事吗？"},
  {"Q简语": "QRV", "含义": "你准备好了吗？"},
  {"Q简语": "QRW", "含义": "需要我转告吗？"},
  {"Q简语": "QRX", "含义": "要我等多长时间？"},
  {"Q简语": "QRZ", "含义": "谁在呼叫我？"},
  {"Q简语": "QSA", "含义": "我的信号强度是多少？"},
  {"Q简语": "QSB", "含义": "我的信号有衰落吗？"},
  {"Q简语": "QSD", "含义": "我的信号不完整吗？"},
  {"Q简语": "QSL", "含义": "你确认收妥/QSL卡片吗？"},
  {"Q简语": "QSO", "含义": "你能否和...直接（或转接）通信？"},
  {"Q简语": "QSP", "含义": "你能中转到...吗？"},
  {"Q简语": "QSU", "含义": "能在这个频率（或某个频率）回复吗？"},
  {"Q简语": "QSV", "含义": "有天电干扰要我在此频率发一串V字吗？"},
  {"Q简语": "QSW", "含义": "你将在此频率（或某频率）发吗？"},
  {"Q简语": "QSX", "含义": "你将在某频率收听吗？"},
  {"Q简语": "QSY", "含义": "要我改用其他频率拍发吗？"},
  {"Q简语": "QSZ", "含义": "要我每组发两遍吗？"},
  {"Q简语": "QTB", "含义": "要我查对组数吗？"},
  {"Q简语": "QTC", "含义": "你有几分报要发？"},
  {"Q简语": "QTH", "含义": "你的地理位置是？"},
  {"Q简语": "QTR", "含义": "你的标准时间是？"}
]

let phoneticAlphabet:Array<phonetic> = [
  { letter: 'A', phonetic: 'Alpha' },
  { letter: 'B', phonetic: 'Bravo' },
  { letter: 'C', phonetic: 'Charlie' },
  { letter: 'D', phonetic: 'Delta' },
  { letter: 'E', phonetic: 'Echo' },
  { letter: 'F', phonetic: 'Foxtrot' },
  { letter: 'G', phonetic: 'Golf' },
  { letter: 'H', phonetic: 'Hotel' },
  { letter: 'I', phonetic: 'India' },
  { letter: 'J', phonetic: 'Juliett' },
  { letter: 'K', phonetic: 'Kilo' },
  { letter: 'L', phonetic: 'Lima' },
  { letter: 'M', phonetic: 'Mike' },
  { letter: 'N', phonetic: 'November' },
  { letter: 'O', phonetic: 'Oscar' },
  { letter: 'P', phonetic: 'Papa' },
  { letter: 'Q', phonetic: 'Quebec' },
  { letter: 'R', phonetic: 'Romeo' },
  { letter: 'S', phonetic: 'Sierra' },
  { letter: 'T', phonetic: 'Tango' },
  { letter: 'U', phonetic: 'Uniform' },
  { letter: 'V', phonetic: 'Victor' },
  { letter: 'W', phonetic: 'Whiskey' },
  { letter: 'X', phonetic: 'Xray' },
  { letter: 'Y', phonetic: 'Yankee' },
  { letter: 'Z', phonetic: 'Zulu' }
];


export {cw,morseCodeTable,
  q_phrases,q,
  phoneticAlphabet,phonetic
}

export class MaidenheadLocator {
  private longitude: number;
  private latitude: number;
  private readonly letters: string = 'ABCDEFGHIJKLMNOPQR'; // 18个基础字母
  private readonly subLetters: string = 'abcdefghijklmnopqrstuvwx'; // 24个子方格字母

  /**
   * 初始化梅登海德定位器
   * @param longitude - 经度（-180 至 180）
   * @param latitude - 纬度（-90 至 90）
   * @throws {Error} 当经纬度超出有效范围时抛出错误
   */
  constructor(longitude: number, latitude: number) {
    // 验证经纬度有效性
    if (longitude < -180 || longitude > 180) {
      throw new Error('经度必须在 -180 到 180 之间');
    }
    if (latitude < -90 || latitude > 90) {
      throw new Error('纬度必须在 -90 到 90 之间');
    }

    this.longitude = longitude;
    this.latitude = latitude;
  }

  /**
   * 计算梅登海德网格编码
   * @returns 6字符网格编码
   */
  calculate(): string {
    // 计算字段（前两个大写字母）
    const lonFieldIdx: number = Math.floor((this.longitude + 180) / 20);
    const latFieldIdx: number = Math.floor((this.latitude + 90) / 10);
    const field: string = this.letters[lonFieldIdx] + this.letters[latFieldIdx];

    // 计算方格（中间两个数字）
    const lonSquare: number = Math.floor((this.longitude - (lonFieldIdx * 20 - 180)) / 2);
    const latSquare: number = Math.floor(this.latitude - (latFieldIdx * 10 - 90));
    const square: string = lonSquare.toString() + latSquare.toString();

    // 计算子方格（最后两个小写字母）
    const lonDecimal: number = this.longitude % 1;
    const lonMinutes: number = lonDecimal * 60;
    const lonSubIdx: number = Math.floor(lonMinutes / 5);

    const latDecimal: number = this.latitude % 1;
    const latMinutes: number = latDecimal * 60;
    const latSubIdx: number = Math.floor(latMinutes / 2.5);

    const subsquare: string = this.subLetters[lonSubIdx] + this.subLetters[latSubIdx];

    // 组合完整编码
    return field + square + subsquare;
  }

  /**
   * 格式化输出结果
   * @returns 包含经纬度和网格编码的格式化字符串
   */
  toString(): string {
    return `经纬度 (${this.longitude.toFixed(4)}, ${this.latitude.toFixed(4)}) 对应的梅登海德网格编码为: ${this.calculate()}`;
  }

  /**
   * 更新经纬度并重新计算
   * @param longitude - 新的经度值
   * @param latitude - 新的纬度值
   */
  updateCoordinates(longitude: number, latitude: number): void {
    if (longitude < -180 || longitude > 180) {
      throw new Error('经度必须在 -180 到 180 之间');
    }
    if (latitude < -90 || latitude > 90) {
      throw new Error('纬度必须在 -90 到 90 之间');
    }

    this.longitude = longitude;
    this.latitude = latitude;
  }
}