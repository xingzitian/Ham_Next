import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { SatelliteService } from '../pages/http_server/SatelliteService';
import { satellite_db_control } from '../pages/Satellite/Satellite_db';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    try {
      // 等待数据库初始化完成
      await satellite_db_control.db_set(this.context);
      // 然后下载数据
      await satellite_db_control.db_get_count(this.context)
        .then((totalCount)=>{
          if(totalCount===0){
            console.log('数据库为空，初次使用或手动清空自动开始下载数据...')
            this.fetchSatelliteList();
          }else{
            console.log('数据库已有数据')
          }
        })
      hilog.info(DOMAIN, 'testTag', 'Database initialized and data downloaded successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize database or download data: %{public}s', JSON.stringify(error));
    }
  }


  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private async fetchSatelliteList(){
    try{
      // 1. 并行下载数据（同时发起两个请求）
      console.log("开始下载卫星和收发器数据...");
      const results = await Promise.all([
        SatelliteService.get_transmitters(),
        SatelliteService.getSatelliteList()
      ]);

      // 2. 分别获取结果
      const res_trans = results[0];
      const res_sat = results[1];

      // 3. 先存储卫星数据
      console.log("存储卫星数据...");
      await satellite_db_control.db_put(this.context, res_sat.data);

      // 4. 获取并更新卫星数量
      const total_satellite = await satellite_db_control.db_get_count(this.context);
      AppStorage.setOrCreate('total_satellite', total_satellite);
      console.log("卫星数据下载完成，总数:", total_satellite);

      // 5. 存储收发器数据
      console.log("存储收发器数据...");
      await satellite_db_control.db_put_transmitters(this.context, res_trans.data);

      // 6. 获取并更新收发器数量
      const total_trans = await satellite_db_control.db_get_transmitters_count(this.context);
      AppStorage.setOrCreate('total_trans', total_trans);
      console.log("收发器数据下载完成，总数:", total_trans);
    }catch (error){
      console.error("数据下载失败:", error);
    }
  }
}