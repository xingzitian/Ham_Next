// SatelliteRadar.ets
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { SatelliteService,trans ,transmitters_info} from '../http_server/SatelliteService';
import { PromptAction } from '@kit.ArkUI';
// 定义轨迹点接口
interface TrajectoryPoint {
  x: number;
  y: number;
  azimuth: number;
  elevation: number;
  isFuture: boolean;
}

// 定义坐标接口
interface Coordinate {
  x: number;
  y: number;
}

interface TransmitterWithDisplay extends transmitters_info {
  displayDownlink: string;
  displayUplink: string;
}

interface TransWithDisplay extends trans {
  transmitters: TransmitterWithDisplay[];
}

@Component
export struct SatelliteRadar {
  // 使用RenderingContextSettings创建Canvas上下文
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  // 雷达尺寸和位置
  private radarRadius: number = 0;
  private centerX: number = 0;
  private centerY: number = 0;

  // 传感器数据
  @State private azimuth: number = 0; // 方位角（0-360度）
  @State private pitch: number = 0;   // 俯仰角
  @State private roll: number = 0;    // 横滚角

  // 卫星数据
  @State private trajectoryPoints: TrajectoryPoint[] = [];
  @State private currentElevation: number = 0; // 当前卫星仰角
  @State private currentAzimuth: number = 0; // 当前卫星方位角
  @State private currentRange: number = 0; // 当前卫星距离
  @State private pageTitle: string = '卫星轨迹雷达图'; // 动态标题
  @State private showTrajectoryPoints: boolean = true; // 是否显示轨迹点

  // 权限管理
  private atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

  // 卫星信息 - 通过StorageProp同步
  @StorageProp('NORAD_ID') noradId: number = 0;
  @StorageProp('SATELLITE_NAME') satelliteName: string = '';
  @StorageProp('NEXT_PASS_TIME') nextPassStartTime: string = '';
  @StorageProp('lat') lat: number = 0;
  @StorageProp('lng') lng: number = 0;
  @StorageProp('alt') alt: number = 0;
  @StorageProp('duration') duration: number = 0;
  @StorageProp('start_time') start_time: string = '';
  @State isSatelliteVisible:boolean=false
  @State rad_trans:trans={
    success:false,
    satellite:{
      norad_id:-1,
      name:'',
      status:'',
    },
    transmitters:[{
      description: '',
      downlink_frequency: -1,
      downlink_mode: '',
      uplink_frequency: -1,
      uplink_mode: '',
      invert: false
    }],
    count:-1,
  }


  @State new_rad_trans: TransWithDisplay = {
    success: false,
    satellite: {
      norad_id: -1,
      name: '',
      status: ''
    },
    transmitters: [],
    count: -1
  };

  // 导航控制器
  @Consume('index') index: NavPathStack;

  // 定时器用于实时获取卫星位置
  private positionTimer: number = 0;
  private countdownTimer: number = 0;

  // 组件生命周期
  aboutToAppear() {
    console.info(`接收到的卫星数据: NORAD ID=${this.noradId}, 名称=${this.satelliteName}`);
    console.info(`用户位置: 纬度=${this.lat}, 经度=${this.lng}, 高度=${this.alt}`);

    // 申请传感器权限
    this.requestSensorPermissions();

    // 设置定时获取卫星位置（每10秒一次）
    this.positionTimer = setInterval(() => {
      this.fetchSatellitePosition();
    }, 5000);

    // 启动倒计时更新
    this.startCountdown();

    // 立即获取轨迹数据和卫星位置
    this.get_transmitters()
    this.fetchTrajectoryData();
    this.fetchSatellitePosition();
  }

  // 启动倒计时更新
  private startCountdown(): void {
    // 清除之前的计时器
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
    }

    // 设置新的计时器，每秒更新一次
    this.countdownTimer = setInterval(() => {
      this.updateCountdown();
    }, 1000) as number;

    // 立即更新一次
    this.updateCountdown();
  }

  // 更新倒计时显示
  private updateCountdown(): void {
    if (!this.nextPassStartTime) {
      this.pageTitle = '卫星轨迹雷达图';
      return;
    }

    // 获取当前时间
    const now = new Date();
    const nextPassTime = new Date(this.nextPassStartTime);

    // 计算距离开始的时间差
    const timeDiff = nextPassTime.getTime() - now.getTime();

    if (timeDiff <= 0) {
      this.pageTitle = '卫星正在过境中';
      return;
    }

    // 转换为天、小时、分钟、秒
    const days = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000);

    // 格式化显示 - 总是显示到秒
    if (days > 0) {
      this.pageTitle = `下次过境: ${days}天${hours}小时${minutes}分${seconds}秒`;
    } else if (hours > 0) {
      this.pageTitle = `下次过境: ${hours}小时${minutes}分${seconds}秒`;
    } else if (minutes > 0) {
      this.pageTitle = `下次过境: ${minutes}分${seconds}秒`;
    } else {
      this.pageTitle = `下次过境: ${seconds}秒`;
    }
  }

  // 申请传感器权限
  private requestSensorPermissions(): void {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.atManager.requestPermissionsFromUser(context, [
        'ohos.permission.ACCELEROMETER'
      ]).then((data) => {
        console.info('权限申请结果: ' + JSON.stringify(data));

        // 权限申请成功后初始化传感器
        if (data.authResults[0] === 0) {
          this.initSensors();
        } else {
          console.error('传感器权限申请失败');
          this.promptAction.showToast({ message: '传感器权限申请失败，部分功能可能受限' });
        }
      }).catch((error: BusinessError) => {
        console.error('权限申请失败: ' + JSON.stringify(error));
        this.promptAction.showToast({ message: '权限申请失败，请检查权限设置' });
      });
    } catch (error) {
      console.error('创建权限管理器失败: ' + JSON.stringify(error));
      this.promptAction.showToast({ message: '权限管理器初始化失败' });
    }
  }

  // 初始化传感器 - 使用方向传感器
  private initSensors(): void {
    try {
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        // 方向传感器直接提供三个角度
        this.azimuth = data.alpha;   // 方位角（0-360度）
        this.pitch = data.beta;      // 俯仰角（前后倾斜）
        this.roll = data.gamma;      // 横滚角（左右倾斜')

        this.drawRadar();
      }, { interval: 200 });

      console.info("使用方向传感器");
    } catch (error) {
      console.error("方向传感器不可用: " + JSON.stringify(error));
      this.promptAction.showToast({ message: '方向传感器不可用，雷达功能受限' });
    }
  }

  aboutToDisappear() {
    // 取消传感器订阅
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (error) {
      // 忽略错误，可能没有订阅
    }

    // 清除定时器
    if (this.positionTimer) {
      clearInterval(this.positionTimer);
    }
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
    }
  }

  // 获取轨迹数据
  private async fetchTrajectoryData(): Promise<void> {
    try {
      this.promptAction.showToast({ message: '正在获取卫星轨迹数据...' });

      // 调用API获取轨迹数据
      const response = await SatelliteService.getPassTrajectory(
        this.noradId,
        this.lat,
        this.lng,
        this.alt,
        this.duration,
        this.start_time
      );

      console.info('轨迹API响应:', JSON.stringify(response));

      if (response && response.success && response.trajectory) {
        // 处理轨迹数据
        this.processTrajectoryData(response.trajectory);
        this.promptAction.showToast({ message: '轨迹数据获取成功' });
      } else {
        console.error('获取轨迹数据失败，响应:', response);
        this.promptAction.showToast({ message: '获取轨迹数据失败，请重试' });
      }
    } catch (error) {
      console.error('获取轨迹数据失败:', error);
      this.promptAction.showToast({ message: '获取轨迹数据失败，请检查网络连接' });
    }
  }

  private async get_transmitters(): Promise<void> {
    try {
      this.promptAction.showToast({ message: '正在获取卫星轨迹数据...' });

      // 调用API获取轨迹数据
      const response = await SatelliteService.get_transmitters(
        this.noradId
      );

      console.info('轨迹API响应:', JSON.stringify(response));

      if (response && response.success) {
        // 处理轨迹数据
        this.rad_trans=response
        this.new_rad_trans = this.processTransmittersWithDoppler(
          this.rad_trans,
          0,
          false
        );
        this.promptAction.showToast({ message: '卫星收发器获取成功' });
      } else {
        console.error('卫星收发器失败，响应:', response);
        this.promptAction.showToast({ message: '卫星收发器数据失败，请重试' });
      }
    } catch (error) {
      console.error('卫星收发器失败:', error);
      this.promptAction.showToast({ message: '卫星收发器失败，请检查网络连接' });
    }
  }

  // 获取卫星实时位置
  // 在获取卫星位置的地方
  private async fetchSatellitePosition(): Promise<void> {
    try {
      const response = await SatelliteService.calculateOrbit(
        this.noradId,
        this.lat,
        this.lng,
        this.alt
      );

      if (response && response.success && response.data) {
        // 更新当前卫星数据
        this.currentElevation = response.data.observer?.elevation || 0;
        this.currentAzimuth = response.data.observer?.azimuth || 0;
        this.currentRange = response.data.observer?.range || 0;

        // 获取 range_rate (公里/秒)
        const rangeRate = response.data.observer?.range_rate || 0;

        // 检查卫星是否可见
        this.isSatelliteVisible = response.data.observer.is_visible;

        // 处理收发器数据并赋值给 new_rad_trans
        this.new_rad_trans = this.processTransmittersWithDoppler(
          this.rad_trans,
          rangeRate,
          true
        );
        console.log(String(this.isSatelliteVisible));
        console.log(String(rangeRate));
        this.drawRadar();
      }
    } catch (error) {
      console.error('获取卫星位置失败:', error);
    }
  }

  // 处理轨迹数据
  private processTrajectoryData(trajectory: number[][]): void {
    // 清空现有数据
    this.trajectoryPoints = [];

    // 检查轨迹数据是否有效
    if (!trajectory || trajectory.length === 0) {
      console.error("无效的轨迹数据");
      return;
    }

    // 处理轨迹点
    for (let i = 0; i < trajectory.length; i++) {
      const point = trajectory[i];

      // 确保点数据格式正确
      if (!point || point.length < 2) {
        console.warn(`跳过无效轨迹点 ${i}`);
        continue;
      }

      const azimuth = point[0];  // 第一个元素是方位角
      const elevation = point[1]; // 第二个元素是仰角

      // 将方位角和仰角转换为雷达坐标
      const coords = this.convertAzElToRadarCoords(azimuth, elevation);

      // 添加到轨迹点
      this.trajectoryPoints.push({
        x: coords.x,
        y: coords.y,
        azimuth: azimuth,
        elevation: elevation,
        isFuture: i >= Math.floor(trajectory.length / 2) // 后半部分为未来轨迹
      } as TrajectoryPoint);
    }

    // 重绘雷达
    this.drawRadar();
  }

  // 仰角到坐标的转换函数（使用线性映射）
  private convertAzElToRadarCoords(azimuth: number, elevation: number): Coordinate {
    // 确保仰角在有效范围内
    const clampedElevation = Math.max(-90, Math.min(90, elevation));

    // 使用线性映射：0°仰角=最大半径，90°仰角=0半径
    let distance = this.radarRadius * (1 - clampedElevation / 90);

    // 确保距离不超过雷达半径
    distance = Math.min(distance, this.radarRadius);

    // 计算角度（基于方位角）
    const normalizedAzimuth = ((azimuth % 360) + 360) % 360; // 规范化到0-360度
    const angleRad = normalizedAzimuth * Math.PI / 180;

    // 计算坐标
    const x = this.centerX + distance * Math.sin(angleRad);
    const y = this.centerY - distance * Math.cos(angleRad);

    return {x, y};
  }

  // 绘制平滑的轨迹曲线
  private drawSmoothedTrajectory(): void {
    if (this.trajectoryPoints.length < 2) return;

    // 使用二次贝塞尔曲线拟合轨迹
    this.context.beginPath();
    this.context.moveTo(this.trajectoryPoints[0].x, this.trajectoryPoints[0].y);

    for (let i = 1; i < this.trajectoryPoints.length - 2; i++) {
      const xc = (this.trajectoryPoints[i].x + this.trajectoryPoints[i + 1].x) / 2;
      const yc = (this.trajectoryPoints[i].y + this.trajectoryPoints[i + 1].y) / 2;

      this.context.quadraticCurveTo(
        this.trajectoryPoints[i].x,
        this.trajectoryPoints[i].y,
        xc,
        yc
      );
    }

    // 曲线到最后一点
    this.context.quadraticCurveTo(
      this.trajectoryPoints[this.trajectoryPoints.length - 2].x,
      this.trajectoryPoints[this.trajectoryPoints.length - 2].y,
      this.trajectoryPoints[this.trajectoryPoints.length - 1].x,
      this.trajectoryPoints[this.trajectoryPoints.length - 1].y
    );

    // 设置轨迹线样式 - 统一颜色
    this.context.strokeStyle = '#ff317af7'; // 品牌色
    this.context.lineWidth = 3;
    this.context.stroke();
  }

  // 绘制改进的十字准星（移除中心圆点）
  private drawCrosshair(x: number, y: number): void {
    if (!this.context) return;

    const crosshairSize = 20;
    const lineWidth = 2;

    // 绘制外圈
    this.context.beginPath();
    this.context.arc(x, y, crosshairSize / 2, 0, Math.PI * 2);
    this.context.strokeStyle = '#ff5ba854'; // 确认色
    this.context.lineWidth = lineWidth;
    this.context.stroke();

    // 绘制水平线
    this.context.beginPath();
    this.context.moveTo(x - crosshairSize, y);
    this.context.lineTo(x + crosshairSize, y);
    this.context.strokeStyle = '#ff5ba854'; // 确认色
    this.context.lineWidth = lineWidth;
    this.context.stroke();

    // 绘制垂直线
    this.context.beginPath();
    this.context.moveTo(x, y - crosshairSize);
    this.context.lineTo(x, y + crosshairSize);
    this.context.strokeStyle = '#ff5ba854'; // 确认色
    this.context.lineWidth = lineWidth;
    this.context.stroke();
  }

  // 绘制轨迹点
  private drawTrajectoryPoints(): void {
    if (!this.showTrajectoryPoints || this.trajectoryPoints.length === 0) return;

    // 绘制轨迹点
    for (const point of this.trajectoryPoints) {
      this.context.beginPath();
      this.context.arc(point.x, point.y, 3, 0, Math.PI * 2);

      // 根据仰角设置不同颜色
      if (point.elevation >= 30) {
        this.context.fillStyle = 'rgba(0, 255, 0, 0.7)'; // 30度以上为绿色
      } else if (point.elevation >= 0) {
        this.context.fillStyle = 'rgba(255, 255, 0, 0.7)'; // 0-30度为黄色
      } else {
        this.context.fillStyle = 'rgba(255, 0, 0, 0.7)'; // 负仰度为红色
      }

      this.context.fill();

      // 显示仰角值（可选）
      if (point.elevation >= 0 && point.elevation <= 30) {
        this.context.font = '12px sans-serif';
        this.context.fillStyle = '#ffffff';
        this.context.textAlign = 'center';
        this.context.textBaseline = 'top';
        this.context.fillText(`${point.elevation.toFixed(1)}°`, point.x, point.y + 8);
      }
    }
  }

  // 绘制雷达界面
  private drawRadar(): void {
    if (!this.context) {
      console.error("Canvas context is not available");
      return;
    }

    // 清除画布
    this.context.clearRect(0, 0, this.context.width, this.context.height);

    // 计算可用绘制区域（考虑10像素内边距）
    const padding = 10;
    const availableWidth = this.context.width - 2 * padding;
    const availableHeight = this.context.height - 2 * padding;

    // 以短边计算半径，确保圆完全可见
    const diameter = Math.min(availableWidth, availableHeight);
    const actualRadius = diameter / 2;

    // 更新中心点位置（考虑内边距）
    const actualCenterX = padding + availableWidth / 2;
    const actualCenterY = padding + availableHeight / 2;

    // 绘制背景圆 - 使用官方Dark模式背景色
    this.context.beginPath();
    this.context.arc(actualCenterX, actualCenterY, actualRadius, 0, Math.PI * 2);
    this.context.fillStyle = 'rgba(25, 26, 28, 0.8)'; // background_secondary 半透明
    this.context.fill();

    // 绘制三个等距圆环：0°、30°、60°仰角
    const elevations = [0, 30, 60]; // 三个圆环
    const ringColors = ['#ffffffff', '#99ffffff', '#99ffffff']; // 颜色：白色、半透明白色、半透明白色
    const ringWidths = [3, 2, 2]; // 线宽：最外层最粗

    for (let i = 0; i < elevations.length; i++) {
      const elevation = elevations[i];

      // 计算每个圆环的半径（等距分布）
      // 0°仰角：半径=actualRadius（最大）
      // 30°仰角：半径=actualRadius * 2/3
      // 60°仰角：半径=actualRadius * 1/3
      const radius = actualRadius * (1 - i / 3);

      this.context.beginPath();
      this.context.arc(actualCenterX, actualCenterY, radius, 0, Math.PI * 2);

      // 设置圆环样式
      this.context.strokeStyle = ringColors[i];
      this.context.lineWidth = ringWidths[i];
      this.context.stroke();



      // 添加刻度标注
      this.context.font = '50px sans-serif';
      this.context.fillStyle = '#ff5ba854'; // 确认色
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';

      // 在一个方向上都添加标注
      // const directions = [0];
      // for (const direction of directions) {
        const angleRad = 0 * Math.PI / 180;
        const labelX = actualCenterX + (radius + 10) * Math.sin(angleRad);
        const labelY = actualCenterY - (radius + 10) * Math.cos(angleRad);
        if(elevation!==0){
          this.context.fillText(`${elevation}°`, labelX, labelY);
        }

      // }

    }

    // 绘制中心点（90°仰角）
    this.context.beginPath();
    this.context.arc(actualCenterX, actualCenterY, 4, 0, Math.PI * 2);
    this.context.fillStyle = '#ffffffff';
    this.context.fill();

    // 添加中心点标注
    this.context.font = '50px sans-serif';
    this.context.fillStyle = '#ff5ba854';
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    this.context.fillText('90°', actualCenterX, actualCenterY - 20);

    // 绘制网格线 - 径向线（方位角网格）
    for (let i = 0; i < 8; i++) {
      const angle = i * 45;
      const angleRad = angle * Math.PI / 180;

      // 绘制径向线
      const x = actualCenterX + actualRadius * Math.sin(angleRad);
      const y = actualCenterY - actualRadius * Math.cos(angleRad);

      this.context.beginPath();
      this.context.moveTo(actualCenterX, actualCenterY);
      this.context.lineTo(x, y);
      this.context.strokeStyle = '#99ffffff'; // 半透明白色
      this.context.lineWidth = 1;
      this.context.stroke();
    }

    // 绘制方向标记 - 放在圆外
    const directions = ['N', 'E', 'S', 'W'];
    const directionAngles = [0, 90, 180, 270];

    for (let i = 0; i < directions.length; i++) {
      const angleRad = directionAngles[i] * Math.PI / 180;
      const labelX = actualCenterX + (actualRadius +10) * Math.sin(angleRad);
      const labelY = actualCenterY - (actualRadius +10) * Math.cos(angleRad);

      this.context.font = '40px sans-serif';
      this.context.fillStyle = '#ff5ba854'; // 确认色
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';
      if(directions[i]==='N'||directions[i]==='S'){
        this.context.fillText(directions[i], actualCenterX + (actualRadius -10) * Math.sin(angleRad), actualCenterY - (actualRadius -10) * Math.cos(angleRad));
      }else{
        this.context.fillText(directions[i], labelX, labelY);
      }
    }

    // 绘制平滑的轨迹曲线
    this.drawSmoothedTrajectory();

    // 绘制轨迹点
    this.drawTrajectoryPoints();

    // 绘制卫星实时位置（只在卫星可见时）
    if (this.currentElevation > 0) {
      const coords = this.convertAzElToRadarCoords(this.currentAzimuth, this.currentElevation);

      // 检查坐标是否在雷达范围内
      const distanceFromCenter = Math.sqrt(
        Math.pow(coords.x - actualCenterX, 2) +
        Math.pow(coords.y - actualCenterY, 2)
      );

      if (distanceFromCenter <= actualRadius * 1.1) {
        this.context.beginPath();
        this.context.arc(coords.x, coords.y, 8, 0, Math.PI * 2);
        this.context.fillStyle = '#ffd94838'; // warning色
        this.context.fill();

        // 添加调试信息（可选）
        if (this.showTrajectoryPoints) {
          this.context.font = '12px sans-serif';
          this.context.fillStyle = '#ffffff';
          this.context.textAlign = 'center';
          this.context.textBaseline = 'bottom';
          this.context.fillText(`${this.currentElevation.toFixed(1)}°`, coords.x, coords.y - 10);
        }
      }
    }

    // 绘制准星
    const crosshairCoords = this.convertDeviceOrientationToRadarCoords(this.azimuth, this.pitch);
    const distanceFromCenter = Math.sqrt(
      Math.pow(crosshairCoords.x - actualCenterX, 2) +
      Math.pow(crosshairCoords.y - actualCenterY, 2)
    );

    // 只要在雷达图范围内就绘制准星
    if (distanceFromCenter <= actualRadius) {
      this.drawCrosshair(crosshairCoords.x, crosshairCoords.y);
    }
  }

  // 将设备方向转换为雷达坐标（针对准星优化版）
  // 将设备方向转换为雷达坐标（针对卫星追踪优化版）
  private convertDeviceOrientationToRadarCoords(azimuth: number, pitch: number): Coordinate {
    // 限制俯仰角在-90到90度范围内
    const normalizedPitch = Math.max(-90, Math.min(90, pitch));

    // 针对卫星追踪的优化映射：
    // 当pitch=-90°（屏幕朝上，仰角90°）时，距离=0（圆心）
    // 当pitch=0°（水平，仰角0°）时，距离=雷达半径（边缘）
    // 当pitch>0°（屏幕朝下，仰角<0°）时，距离=雷达半径（边缘，不考虑负仰角）

    // 使用分段线性映射
    let distance: number;

    if (normalizedPitch <= 0) {
      // 屏幕朝上或水平：pitch从-90°到0°，距离从0到雷达半径
      distance = this.radarRadius * (normalizedPitch + 90) / 90;
    } else {
      // 屏幕朝下：pitch>0°，距离固定为雷达半径（边缘）
      distance = this.radarRadius;
    }

    // 计算角度（基于方位角）
    // 注意：我们现在只使用北向模式，所以不需要displayAzimuth计算
    const normalizedAzimuth = ((azimuth % 360) + 360) % 360; // 规范化到0-360度
    const angleRad = normalizedAzimuth * Math.PI / 180;

    // 计算坐标
    const x = this.centerX + distance * Math.sin(angleRad);
    const y = this.centerY - distance * Math.cos(angleRad);

    return {x, y};
  }
  // 切换轨迹点显示
  private toggleTrajectoryPoints(): void {
    this.showTrajectoryPoints = !this.showTrajectoryPoints;
    this.drawRadar();
  }




  // 处理收发器数据的函数（修复版）
  private processTransmittersWithDoppler(
    originalData: trans,
    rangeRate: number, // 使用 range_rate (公里/秒)
    isSatelliteVisible: boolean
  ): TransWithDisplay {
    // 创建新的数据对象，手动复制属性
    const newData: TransWithDisplay = {
      success: originalData.success,
      satellite: {
        norad_id: originalData.satellite.norad_id,
        name: originalData.satellite.name,
        status: originalData.satellite.status
      },
      transmitters: [],
      count: originalData.count
    };

    // 处理每个收发器
    if (originalData.transmitters) {
      newData.transmitters = originalData.transmitters.map((transmitter: transmitters_info): TransmitterWithDisplay => {
        let displayDownlink: string;
        let displayUplink: string;


          // 卫星可见时，应用多普勒频移
          // rangeRate 单位是公里/秒，需要转换为米/秒
          const relativeSpeed = rangeRate * 1000; // 转换为米/秒

          // 计算多普勒频移
          const downlinkDoppler = this.calculateDopplerShift(transmitter.downlink_frequency, relativeSpeed);
          const uplinkDoppler = this.calculateDopplerShift(transmitter.uplink_frequency, relativeSpeed);

          // 应用频移（注意符号：远离时频率降低，接近时频率增加）
          const downlinkWithDoppler = transmitter.downlink_frequency + downlinkDoppler;
          const uplinkWithDoppler = transmitter.uplink_frequency + uplinkDoppler;

          displayDownlink = this.formatFrequency(downlinkWithDoppler);
          displayUplink = this.formatFrequency(uplinkWithDoppler);

          // 调试信息
          // console.info(`多普勒频移计算:
          // 原始下行频率: ${transmitter.downlink_frequency} Hz
          // 原始上行频率: ${transmitter.uplink_frequency} Hz
          // 相对速度: ${relativeSpeed} m/s
          // 下行频移: ${downlinkDoppler} Hz
          // 上行频移: ${uplinkDoppler} Hz
          // 调整后下行: ${downlinkWithDoppler} Hz
          // 调整后上行: ${uplinkWithDoppler} Hz`);


        // 手动复制所有属性并添加新属性
        return {
          description: transmitter.description,
          downlink_frequency: transmitter.downlink_frequency,
          downlink_mode: transmitter.downlink_mode,
          uplink_frequency: transmitter.uplink_frequency,
          uplink_mode: transmitter.uplink_mode,
          invert: transmitter.invert,
          displayDownlink,
          displayUplink
        };
      });
    }

    return newData;
  }

  // 辅助函数
  private calculateDopplerShift(baseFrequency: number, relativeSpeed: number): number {
    if (baseFrequency <= 0) return 0;
    const speedOfLight = 299792458;
    return -baseFrequency * relativeSpeed / speedOfLight;
  }

  private formatFrequency(frequency: number): string {
    if (frequency <= 0) return "N/A";
    if (frequency >= 1000000) return `${(frequency / 1000000).toFixed(4)} MHz`;
    if (frequency >= 1000) return `${(frequency / 1000).toFixed(4)} kHz`;
    return `${frequency.toFixed(4)} Hz`;
  }

  build() {
    NavDestination() {
      Column() {
        // 雷达显示区域 - 高度调整为50%
        Canvas(this.context)
          .width('100%')
          .height('50%') // 调整高度为50%
          .backgroundColor('#ff191a1c') // background_secondary
          .onReady(() => {
            console.info("Canvas准备就绪");

            // 计算雷达尺寸（考虑10像素内边距）
            const padding = 10;
            const availableWidth = this.context.width - 2 * padding;
            const availableHeight = this.context.height - 2 * padding;

            // 以短边计算半径
            const diameter = Math.min(availableWidth, availableHeight);
            this.radarRadius = diameter / 2;
            this.centerX = padding + availableWidth / 2;
            this.centerY = padding + availableHeight / 2;

            console.info(`Canvas尺寸: ${this.context.width}x${this.context.height}`);
            console.info(`雷达半径: ${this.radarRadius}, 中心点: (${this.centerX}, ${this.centerY})`);

            // 初始绘制
            this.drawRadar();
          })

        // 信息显示区域 - 在画布下方
        Column() {
          // 卫星基本信息
          Row() {
            Text(`卫星: ${this.satelliteName}`)
              .fontSize(16)
              .fontColor('#e5ffffff') // font_primary
              .layoutWeight(1)

            Text(`NORAD: ${this.noradId}`)
              .fontSize(16)
              .fontColor('#99ffffff') // font_secondary
          }
          .width('90%')
          .margin({ bottom: 8 })

          // 卫星位置信息
          Row() {
            Text(`仰角: ${this.currentElevation.toFixed(1)}°`)
              .fontSize(16)
              .fontColor('#e5ffffff') // font_primary
              .layoutWeight(1)

            Text(`方位角: ${this.currentAzimuth.toFixed(1)}°`)
              .fontSize(16)
              .fontColor('#e5ffffff') // font_primary
              .layoutWeight(1)

            Text(`距离: ${this.currentRange.toFixed(1)}km`)
              .fontSize(16)
              .fontColor('#e5ffffff') // font_primary
              .layoutWeight(1)
          }
          .width('90%')
          .margin({ bottom: 10 })
        }
        .width('100%')
        .margin({ top: 10, bottom: 5 })

        // 下半部分留空，用于放置卫星收发器
        Column() {
          List({ space: 5 }) {
              ForEach(this.new_rad_trans.transmitters, (item:TransmitterWithDisplay) => {
                ListItem() {
                  Column() {
                    Row(){
                      Text(){
                        SymbolSpan($r('sys.symbol.arrowtriangle_down_fill'))
                      }
                      Text(item.description)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .textAlign(TextAlign.Center)
                        .width('90%')
                      Text(){
                        SymbolSpan($r('sys.symbol.arrowtriangle_up_fill'))
                      }
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceAround)
                    Row() {
                      if(String(item.downlink_frequency)==='null'){
                        Text('暂无')
                          .width('40%')
                      }else{
                        Text(item.displayDownlink)
                          .width('40%')
                      }
                      if(String(item.uplink_frequency)==='null'){
                        Text('暂无')
                          .width('40%')
                      }else{
                        Text(item.displayUplink)
                          .width('40%')
                      }
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceAround)
                    Row(){
                      Text('模式：'+item.downlink_mode)
                      if(item.invert===true){
                        Text('倒置：是')
                      }else{
                        Text('倒置：否')
                      }
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceAround)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Center)
                }
                .backgroundColor($r('sys.color.background_fourth'))
                .borderRadius(10)
              })
          }
        }
        .width('90%')
        .height('30%')
        .justifyContent(FlexAlign.Center)

        Button(this.showTrajectoryPoints ? '隐藏轨迹点' : '显示轨迹点')
          .width('80%')
          .height(40)
          .backgroundColor('#ff5ba854') // 确认色
          .fontColor('#ffffffff') // font_on_primary
          .onClick(() => {
            this.toggleTrajectoryPoints();
          })
          .margin({top:5})
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ff191a1c') // background_secondary
    }
    .title(this.pageTitle) // 动态标题
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}
