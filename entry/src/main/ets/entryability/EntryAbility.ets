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
    const response = await SatelliteService.getSatelliteList();
    if (response.success) {
      await satellite_db_control.db_put(this.context,response.data)
        .then(()=>{
          console.log("DB-页面数据下载初始化")
          return satellite_db_control.db_get_count(this.context)
        })
        .then((totalCount)=>{
          console.log("DB-页面数据下载完成，更新UI")
          AppStorage.setOrCreate('totalCount',totalCount);
        })

    }
  }
}