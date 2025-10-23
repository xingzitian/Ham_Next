import { AdvancedPassesResponse, SatelliteService, SatelliteTLE } from '../http_server/SatelliteService';
import { PromptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { satellite_db_control } from './Satellite_db';

// 卫星过境信息接口
interface SatellitePassInfo {
  noradId: number;
  name: string;
  pass_number: number;
  startTime: string;
  endTime: string;
  maxElevation: number;
  duration: number;
}

PersistentStorage.persistProp('lat', 39.9042);
PersistentStorage.persistProp('lng', 116.4074);
PersistentStorage.persistProp('alt', 0);

@Component
export struct Satellite_index {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  @Consume('index') index: NavPathStack;

  // 搜索相关状态
  @State searchKeyword: string = '';
  @State isSearching: boolean = false;
  @State searchResults: SatelliteTLE[] = [];
  @State displayList: SatelliteTLE[] = [];

  // 分页相关状态
  @State currentPage: number = 1;
  @State pageSize: number = 20; // 每页显示数量
  @StorageLink('totalCount') totalCount: number = 0

  // 卫星列表（从数据库获取）
  @State satelliteList: SatelliteTLE[] = [];

  // 已选择的卫星
  // @State selectedSatellites: SatelliteTLE[] = [];
  @StorageLink('selectedSatellites') selectedSatellites: SatelliteTLE[] = []
  // 查询结果（过境信息列表）
  @State passResults: SatellitePassInfo[] = [];

  // 加载状态
  @State isLoading: boolean = false;
  @State isDialogLoading: boolean = false;

  // 用户位置（默认为北京）
  @StorageLink('NORAD_ID') NORAD_ID: number = 0
  @StorageLink('lat') lat: number = 0
  @StorageLink('lng') lng: number = 0
  @StorageLink('alt') alt: number = 0
  @StorageLink('start_time') start_time: string = ''
  @StorageLink('duration') duration: number = 0

  // 天数限制
  @State daysLimit: number = 1;
  // 最低仰角限制
  @State minElevation: number = 18;
  // 是否显示卫星选择弹窗
  @State showSatelliteDialog: boolean = false;
  // 最近一次过境距离现在的时间（格式化）
  @State nextPassCountdown: string = '';
  // 计时器ID
  private countdownTimer: number = 0;

  // 组件生命周期
  aboutToAppear() {
    this.requestSensorPermissions();
    this.loadSatelliteCount();
  }

  aboutToDisappear() {
    // 清除计时器
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
    }
  }

  /**
   * 加载卫星总数
   */
  private async loadSatelliteCount(): Promise<void> {
    try {
      this.totalCount = await satellite_db_control.db_get_count(this.context);
      console.info(`卫星总数: ${this.totalCount}`);
    } catch (error) {
      console.error('获取卫星总数失败:', error);
    }
  }

  /**
   * 从数据库加载卫星列表（分页）
   */
  private async loadSatellitesFromDB(page: number = 1): Promise<void> {
    this.isDialogLoading = true;
    try {
      this.satelliteList = await satellite_db_control.db_get(this.context, page, this.pageSize);
      this.displayList = this.satelliteList;
      this.currentPage = page;
      console.info(`加载第 ${page} 页数据，共 ${this.satelliteList.length} 条`);
    } catch (error) {
      console.error('从数据库加载卫星列表失败:', error);
      this.promptAction.showToast({ message: '加载卫星列表失败' });
    } finally {
      this.isDialogLoading = false;
    }
  }

  /**
   * 从数据库搜索卫星
   */
  private async searchSatellitesFromDB(keyword: string): Promise<void> {
    this.isDialogLoading = true;
    try {
      this.searchResults = await satellite_db_control.db_search(this.context, keyword, 1, this.pageSize);
      this.displayList = this.searchResults;
      console.info(`搜索 "${keyword}" 找到 ${this.searchResults.length} 个结果`);
    } catch (error) {
      console.error('搜索卫星失败:', error);
      this.promptAction.showToast({ message: '搜索失败' });
    } finally {
      this.isDialogLoading = false;
    }
  }

  private requestSensorPermissions(): void {
    try {
      this.atManager.requestPermissionsFromUser(this.context, [
        'ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'
      ]).then((data) => {
        console.info('权限申请结果: ' + JSON.stringify(data));

        // 权限申请成功后初始化传感器
        if (data.authResults[0] === 0) {
          this.getUserLocation();
        } else {
          console.error('获取定位权限申请失败');
        }
      }).catch((error: BusinessError) => {
        console.error('权限申请失败: ' + JSON.stringify(error));
      });
    } catch (error) {
      console.error('创建权限管理器失败: ' + JSON.stringify(error));
    }
  }

  // 获取用户位置
  private async getUserLocation(): Promise<void> {
    let locationChange = (err: BusinessError, location: geoLocationManager.Location) => {
      if (err) {
        console.error('locationChange: err=' + JSON.stringify(err));
      }
      if (location) {
        console.info('locationChange: location=' + JSON.stringify(location));
        this.lat = location.latitude
        this.lng = location.longitude
        this.alt = location.altitude || 0
      }
    };

    try {
      geoLocationManager.getCurrentLocation(locationChange);
    } catch (err) {
      console.error("errCode:" + err.code + ", message:" + err.message);
    }
  }

  // 添加卫星到选择列表
  private addSatellite(satellite: SatelliteTLE): void {
    // 检查是否已添加
    const isAlreadyAdded = this.selectedSatellites.some(s => s.norad_id === satellite.norad_id);
    if (!isAlreadyAdded) {
      this.selectedSatellites = [...this.selectedSatellites, satellite];
      this.promptAction.showToast({ message: `已添加 ${satellite.name}` });
    } else {
      this.promptAction.showToast({ message: `${satellite.name} 已添加` });
    }
  }

  // 从选择列表移除卫星
  private removeSatellite(noradId: number): void {
    this.selectedSatellites = this.selectedSatellites.filter(s => s.norad_id !== noradId);
  }

  // 查询所有已选卫星的过境信息
  private async queryAllSatellites(): Promise<void> {
    if (this.selectedSatellites.length === 0) {
      this.promptAction.showToast({ message: '请先添加卫星' });
      return;
    }

    this.isLoading = true;
    this.passResults = [];

    try {
      // 依次查询每个卫星的过境信息
      for (const satellite of this.selectedSatellites) {
        const response: AdvancedPassesResponse = await SatelliteService.getAdvancedPasses(
          satellite.norad_id,
          this.lat,
          this.lng,
          this.alt,
          this.daysLimit,
          this.minElevation
        );

        if (response.success && response.passes) {
          // 将每个过境信息添加到结果列表
          for (const pass of response.passes) {
            this.passResults = [...this.passResults, {
              noradId: satellite.norad_id,
              name: satellite.name,
              pass_number: pass.pass_number,
              startTime: pass.start_time,
              endTime: pass.end_time,
              maxElevation: pass.max_elevation,
              duration: pass.duration_minutes
            }];
          }
        }
      }

      // 按开始时间排序
      this.passResults.sort((a, b) =>
      new Date(a.startTime).getTime() - new Date(b.startTime).getTime()
      );

      // 启动倒计时更新
      this.startCountdown();

      this.promptAction.showToast({ message: `查询完成，找到 ${this.passResults.length} 个过境` });
    } catch (error) {
      console.error('查询卫星过境错误:', error);
      this.promptAction.showToast({ message: '查询失败' });
    } finally {
      this.isLoading = false;
    }
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

  // 更新倒计时显示（精确到秒）
  private updateCountdown(): void {
    if (this.passResults.length === 0) {
      this.nextPassCountdown = '暂无过境信息';
      return;
    }

    // 获取当前时间（精确到毫秒）
    const now = new Date();
    const nowTime = now.getTime();

    // 找到第一个未来的过境
    const nextPass = this.passResults.find(pass => new Date(pass.startTime).getTime() > nowTime);

    if (!nextPass) {
      this.nextPassCountdown = '所有过境已结束';
      return;
    }

    // 计算距离开始的时间差（毫秒）
    const timeDiff = new Date(nextPass.startTime).getTime() - nowTime;

    // 转换为天、小时、分钟、秒
    const days = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000);

    // 格式化显示（始终显示秒）
    if (days > 0) {
      this.nextPassCountdown = `最近的卫星下次过境: ${days}天${hours}小时${minutes}分${seconds}秒后`;
    } else if (hours > 0) {
      this.nextPassCountdown = `最近的卫星下次过境: ${hours}小时${minutes}分${seconds}秒后`;
    } else if (minutes > 0) {
      this.nextPassCountdown = `最近的卫星下次过境: ${minutes}分${seconds}秒后`;
    } else {
      this.nextPassCountdown = `最近的卫星下次过境: ${seconds}秒后`;
    }
  }

  // 正确地将UTC时间转换为中国时间（UTC+8）
  private convertUTCToChinaTime(utcTime: string): string {
    const date = new Date(utcTime);
    // 使用更可靠的方法处理时区转换
    const chinaTime = new Date(date.getTime() + (8 * 60 * 60 * 1000));
    return chinaTime.toISOString().replace('T', ' ').substring(0, 19);
  }

  // 格式化时间显示（使用中国时间，精确到秒）
  private formatTime(timeString: string): string {
    const chinaTime = this.convertUTCToChinaTime(timeString);
    const date = new Date(chinaTime);
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes()
      .toString()
      .padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
  }

  // 格式化日期时间显示（完整格式）
  private formatDateTime(timeString: string): string {
    const chinaTime = this.convertUTCToChinaTime(timeString);
    const date = new Date(chinaTime);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate()
      .toString()
      .padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes()
      .toString()
      .padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
  }

  // 执行搜索
  private async performSearch(keyword: string): Promise<void> {
    this.searchKeyword = keyword;
    this.isSearching = keyword.length > 0;

    if (this.isSearching) {
      await this.searchSatellitesFromDB(keyword);
    } else {
      // 清空搜索，回到当前页
      await this.loadSatellitesFromDB(this.currentPage);
    }
  }

  // 清空搜索
  private async clearSearch(): Promise<void> {
    this.searchKeyword = '';
    this.isSearching = false;
    await this.loadSatellitesFromDB(this.currentPage);
  }

  build() {
    NavDestination() {
      Column() {
        // 时间显示区域
        Column() {
          Text("当前时区时间：")
            .fontSize(18)
            .fontColor($r('sys.color.font_primary'))
          TextClock()
            .fontSize(18)
            .format("yyyy年M月d日HH:mm:ss")
            .fontColor($r('sys.color.font_primary'))

          Divider().strokeWidth(2).color($r('sys.color.comp_divider'))

          Text("当前UTC时间：")
            .fontSize(18)
            .fontColor($r('sys.color.font_primary'))
          TextClock({ timeZoneOffset: 0 })
            .fontSize(18)
            .format("yyyy年M月d日HH:mm:ss")
            .fontColor($r('sys.color.font_primary'))
        }
        .width('90%')
        .padding(12)
        .backgroundColor($r('sys.color.background_secondary'))
        .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 8 })
        .margin({ top: 5, bottom: 10 })

        // 下次过境倒计时
        Text(this.nextPassCountdown)
          .fontSize(18)
          .fontColor($r('sys.color.brand'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        // 查询条件区域
        Row() {
          // 天数限制输入框
          TextInput({ placeholder: "查询天数", text: String(this.daysLimit) })
            .type(InputType.Number)
            .width('40%')
            .margin(8)
            .backgroundColor($r('sys.color.background_secondary'))
            .fontColor($r('sys.color.font_primary'))
            .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 4 })
            .onChange((value: string) => {
              const numValue = parseInt(value);
              if (!isNaN(numValue) && numValue > 0) {
                this.daysLimit = numValue;
              }
            })

          // 最低仰角输入框
          TextInput({ placeholder: "最低仰角", text: String(this.minElevation) })
            .type(InputType.Number)
            .width('40%')
            .margin(8)
            .backgroundColor($r('sys.color.background_secondary'))
            .fontColor($r('sys.color.font_primary'))
            .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 4 })
            .onChange((value: string) => {
              const numValue = parseInt(value);
              if (!isNaN(numValue) && numValue >= 0) {
                this.minElevation = numValue;
              }
            })
        }
        .margin({ bottom: 10 })

        // 已选卫星区域和操作按钮放在一行
        Row() {
          Text('已选卫星:')
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Button('手动定位')
            .fontSize(14)
            .height(36)
            .padding({ left: 12, right: 12 })
            .backgroundColor($r('sys.color.brand'))
            .fontColor($r('sys.color.comp_common_contrary'))
            .margin({ right: 8 })
            .onClick(() => {
              this.getUserLocation()
            })

          // 添加卫星按钮
          Button('添加卫星')
            .fontSize(14)
            .height(36)
            .padding({ left: 12, right: 12 })
            .backgroundColor($r('sys.color.brand'))
            .fontColor($r('sys.color.comp_common_contrary'))
            .margin({ right: 8 })
            .onClick(async () => {
              this.showSatelliteDialog = true;
              await this.loadSatellitesFromDB(1);
            })

          // 查询按钮
          Button(this.isLoading ? '查询中...' : '查询过境')
            .fontSize(14)
            .height(36)
            .padding({ left: 12, right: 12 })
            .backgroundColor($r('sys.color.confirm'))
            .fontColor($r('sys.color.comp_common_contrary'))
            .enabled(!this.isLoading)
            .onClick(() => this.queryAllSatellites())
        }
        .width('90%')
        .margin({ bottom: 12 })

        Text('纬度:' + this.lat.toFixed(4) + '经度:' + this.lng.toFixed(4))
          .fontSize(18)
          .fontColor($r('sys.color.brand'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        // 已选卫星列表
        Scroll() {
          Column() {
            if (this.selectedSatellites.length === 0) {
              Text('暂无已选卫星，点击"添加卫星"按钮选择')
                .fontSize(14)
                .fontColor($r('sys.color.font_tertiary'))
                .margin(10)
            } else {
              ForEach(this.selectedSatellites, (satellite: SatelliteTLE) => {
                Row() {
                  Text(satellite.name)
                    .fontSize(16)
                    .fontColor($r('sys.color.font_primary'))
                    .layoutWeight(1)

                  Text() {
                    SymbolSpan($r('sys.symbol.trash'))
                      .fontWeight(FontWeight.Normal)
                      .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                      .fontColor([$r('sys.color.warning'), Color.White])
                      .fontSize(40)
                  }
                  .onClick(() => {
                    this.removeSatellite(satellite.norad_id)
                  })

                }
                .padding(10)
                .backgroundColor($r('sys.color.background_secondary'))
                .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 6 })
                .margin({ bottom: 6 })
              })
            }
          }
        }
        .height('15%')
        .width('90%')
        .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 6 })

        // 结果列表标题
        Text('过境信息:')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16, bottom: 12 })
          .align(Alignment.Start)
          .width('90%')

        if (this.passResults.length === 0 && !this.isLoading) {
          Text('暂无过境信息')
            .fontSize(16)
            .fontColor($r('sys.color.font_tertiary'))
            .margin(20)
        }

        // 结果列表
        List() {
          ForEach(this.passResults, (passInfo: SatellitePassInfo) => {
            ListItem() {
              Column() {
                // 卫星名称和NORAD ID
                Row() {
                  Text(passInfo.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('sys.color.font_primary'))
                    .layoutWeight(1)

                  Text(`NORAD: ${passInfo.noradId}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_tertiary'))
                }
                .margin({ bottom: 6 })

                // 时间信息（显示中国时间）
                Row() {
                  Text(`${this.formatDateTime(passInfo.startTime)}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_tertiary'))

                  Text(`${this.formatTime(passInfo.startTime)} - ${this.formatTime(passInfo.endTime)}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_tertiary'))
                    .margin({ left: 8 })
                }
                .margin({ bottom: 6 })

                // 仰角和持续时间
                Row() {
                  Text(`最大仰角: ${passInfo.maxElevation.toFixed(1)}°`)
                    .fontSize(14)
                    .fontColor($r('sys.color.font_primary'))

                  Text(`持续时间: ${passInfo.duration}分钟`)
                    .fontSize(14)
                    .fontColor($r('sys.color.font_primary'))
                    .margin({ left: 16 })
                }
                .margin({ bottom: 12 })

                // 查看按钮
                Button('查看轨迹')
                  .width('100%')
                  .height(36)
                  .backgroundColor($r('sys.color.brand'))
                  .fontColor($r('sys.color.comp_common_contrary'))
                  .onClick(() => {
                    AppStorage.setOrCreate('NEXT_PASS_TIME', passInfo.startTime);
                    this.NORAD_ID = passInfo.noradId
                    this.start_time = passInfo.startTime
                    this.duration = passInfo.duration
                    AppStorage.setOrCreate('SATELLITE_NAME', passInfo.name);
                    this.index.pushPath({ name: 'SatelliteRadar' })
                  })
              }
              .padding(12)
              .backgroundColor($r('sys.color.background_secondary'))
              .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 8 })
              .margin({ bottom: 12 })
            }
          })
        }
        .height('40%')
        .width('90%')

        // 卫星选择弹窗
        if (this.showSatelliteDialog) {
          Column() {
            // 弹窗标题和搜索框
            Row() {
              Text('选择卫星')
                .fontSize(18)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)

              // 搜索框
              TextInput({ placeholder: '搜索卫星名称或ID', text: this.searchKeyword })
                .width('60%')
                .height(36)
                .margin({ right: 8 })
                .backgroundColor($r('sys.color.background_secondary'))
                .fontColor($r('sys.color.font_primary'))
                .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 4 })
                .onChange((value: string) => {
                  this.performSearch(value);
                })

              // 清空搜索按钮
              if (this.isSearching) {
                Text() {
                  SymbolSpan($r('sys.symbol.delete_left'))
                    .fontSize(20)
                }
                .width(36)
                .height(36)
                .onClick(() => {
                  this.clearSearch();
                })
              }
            }
            .padding({
              top: 20,
              bottom: 10,
              left: 16,
              right: 16
            })

            // 显示搜索提示或结果数量
            if (this.isSearching) {
              Text(this.searchResults.length > 0 ?
                `找到 ${this.searchResults.length} 个匹配结果` :
                '未找到匹配的卫星')
                .fontSize(14)
                .fontColor($r('sys.color.font_tertiary'))
                .margin({ bottom: 10 })
            }

            Scroll() {
              Column() {
                if (this.isDialogLoading) {
                  Text('正在加载...')
                    .fontSize(14)
                    .fontColor($r('sys.color.font_tertiary'))
                    .margin(10)
                } else if (this.displayList.length === 0) {
                  Text(this.isSearching ? '请尝试其他搜索词' : '暂无卫星数据')
                    .fontSize(14)
                    .fontColor($r('sys.color.font_tertiary'))
                    .margin(10)
                } else {
                  ForEach(this.displayList, (satellite: SatelliteTLE) => {
                    Button(satellite.name)
                      .width('90%')
                      .height(44)
                      .margin(6)
                      .backgroundColor(this.selectedSatellites.some(s => s.norad_id === satellite.norad_id) ?
                        $r('sys.color.brand') : $r('sys.color.background_secondary'))
                      .fontColor(this.selectedSatellites.some(s => s.norad_id === satellite.norad_id) ?
                        $r('sys.color.comp_common_contrary') : $r('sys.color.font_primary'))
                      .onClick(() => this.addSatellite(satellite))
                  })
                }
              }
            }
            .height('60%')
            .width('100%')

            // 分页控件（只有在非搜索模式下显示）
            if (!this.isSearching) {
              Row() {
                Button('上一页')
                  .enabled(this.currentPage > 1)
                  .onClick(async () => {
                    if (this.currentPage > 1) {
                      await this.loadSatellitesFromDB(this.currentPage - 1);
                    }
                  })

                Text(`第 ${this.currentPage} 页 / 共 ${Math.ceil(this.totalCount / this.pageSize)} 页`)
                  .fontSize(14)
                  .margin({ left: 16, right: 16 })

                Button('下一页')
                  .enabled(this.currentPage < Math.ceil(this.totalCount / this.pageSize))
                  .onClick(async () => {
                    if (this.currentPage < Math.ceil(this.totalCount / this.pageSize)) {
                      await this.loadSatellitesFromDB(this.currentPage + 1);
                    }
                  })
              }
              .margin(10)
              .width('100%')
              .justifyContent(FlexAlign.Center)
            }

            Button('关闭')
              .width('80%')
              .height(36)
              .margin(10)
              .backgroundColor($r('sys.color.warning'))
              .fontColor($r('sys.color.comp_common_contrary'))
              .onClick(() => {
                this.showSatelliteDialog = false;
                this.clearSearch(); // 关闭时清空搜索
              })
          }
          .width('90%')
          .height('80%')
          .backgroundColor($r('sys.color.background_primary'))
          .border({ width: 1, color: $r('sys.color.comp_divider'), radius: 12 })
          .position({ x: '5%', y: '10%' })
          .zIndex(999)
        }
      }
      .width('100%')
      .height('90%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('sys.color.background_primary'))
    }
    .title('追星-卫星过境计算')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}
