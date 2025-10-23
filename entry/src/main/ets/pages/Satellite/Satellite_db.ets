import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData'; // 导入模块
import { SatelliteTLE } from '../http_server/SatelliteService';

const STORE_CONFIG: relationalStore.StoreConfig = {
  // 数据库文件名
  name: 'satellites.db',
  // 数据库安全级别
  securityLevel: relationalStore.SecurityLevel.S3,
};

export class satellite_db_control{

  public static db_set(context: common.UIAbilityContext): Promise<void> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, async (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }
        console.info('Succeeded in getting RdbStore.');
        let storeVersion = store.version;
        if (storeVersion === 0) {
          try {
            const SQL_CREATE_TABLE = 'CREATE TABLE satellites (norad_id INT PRIMARY KEY,name VARCHAR(255) NOT NULL,line1 VARCHAR(255) NOT NULL,line2 VARCHAR(255) NOT NULL,updated_at TIMESTAMP NOT NULL);';

            await store.execute(SQL_CREATE_TABLE);
            storeVersion = 1;
          } catch (e) {
            const err = e as BusinessError;
            console.error(`Failed to execute sql. Code:${err.code}, message:${err.message}`);
            reject(err);
            return;
          }
        }
        store.version = storeVersion;
        resolve(); // 数据库初始化完成
      });
    });
  }

  /**
   * 批量插入卫星数据（Promise风格）- 保持原有数组遍历逻辑
   * @param context UIAbility上下文
   * @param data 卫星数据数组
   * @returns Promise<void>
   */
  public static db_put(context: common.UIAbilityContext, data: SatelliteTLE[]): Promise<void> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        console.info('Succeeded in getting RdbStore.');

        if (store === undefined) {
          reject(new Error('Store is undefined'));
          return;
        }

        console.log("store !== undefined");
        console.log("n=" + data.length);

        // 使用 async 函数来处理逐条插入
        const insertAll = async () => {
          let successCount = 0;
          let errorCount = 0;

          for (let i = 0; i < data.length; i++) {
            console.log("i=" + i);
            const valueBucket: relationalStore.ValuesBucket = {
              norad_id: data[i].norad_id,
              name: data[i].name,
              line1: data[i].line1,
              line2: data[i].line2,
              updated_at: data[i].updated_at
            };

            try {
              const rowId = await store.insert('satellites', valueBucket);
              console.info(`Succeeded in inserting data. rowId:${rowId}`);
              successCount++;
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to insert data. Code:${err.code}, message:${err.message}`);
              errorCount++;
            }
          }

          console.info(`Insert completed. Success: ${successCount}, Failed: ${errorCount}`);

          // 如果有任何成功插入的记录，就认为操作成功
          if (successCount > 0) {
            resolve();
          } else {
            reject(new Error(`All insertions failed. Total attempts: ${data.length}`));
          }
        };

        // 执行插入
        insertAll();
      });
    });
  }
  /**
   * 从数据库中分页查询卫星列表
   * @param context UIAbility上下文
   * @param page 页码（从1开始）
   * @param pageSize 每页大小
   * @returns Promise<SatelliteTLE[]> 包含完整卫星信息的数组
   */
  public static db_get(context: common.UIAbilityContext, page: number = 1, pageSize: number = 20): Promise<SatelliteTLE[]> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          const offset = (page - 1) * pageSize;
          const sql = 'SELECT norad_id, name, line1, line2, updated_at FROM satellites ORDER BY name LIMIT ? OFFSET ?';
          const bindArgs = [pageSize, offset];

          (store as relationalStore.RdbStore).querySql(sql, bindArgs, (err, resultSet) => {
            if (err) {
              console.error(`Query failed, code is ${err.code}, message is ${err.message}`);
              reject(err);
              return;
            }

            const satellites: SatelliteTLE[] = [];
            try {
              while (resultSet.goToNextRow()) {
                const satellite: SatelliteTLE = {
                  norad_id: resultSet.getLong(resultSet.getColumnIndex('norad_id')),
                  name: resultSet.getString(resultSet.getColumnIndex('name')),
                  line1: resultSet.getString(resultSet.getColumnIndex('line1')),
                  line2: resultSet.getString(resultSet.getColumnIndex('line2')),
                  updated_at: resultSet.getString(resultSet.getColumnIndex('updated_at'))
                };
                satellites.push(satellite);
              }
              console.info(`Succeeded in querying satellites. Count: ${satellites.length}`);
              resolve(satellites);
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to process result set. Code:${err.code}, message:${err.message}`);
              reject(err);
            } finally {
              resultSet.close();
            }
          });
        } else {
          reject(new Error('Store is undefined'));
        }
      });
    });
  }
  /**
   * 获取卫星总数
   * @param context UIAbility上下文
   * @returns Promise<number> 卫星总数
   */
  public static db_get_count(context: common.UIAbilityContext): Promise<number> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          const sql = 'SELECT COUNT(*) as total_count FROM satellites';

          (store as relationalStore.RdbStore).querySql(sql, [], (err, resultSet) => {
            if (err) {
              console.error(`Query failed, code is ${err.code}, message is ${err.message}`);
              reject(err);
              return;
            }

            try {
              let count = 0;
              if (resultSet.goToNextRow()) {
                count = resultSet.getLong(resultSet.getColumnIndex('total_count'));
              }
              console.info(`Succeeded in querying satellite count: ${count}`);
              resolve(count);
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to process result set. Code:${err.code}, message:${err.message}`);
              reject(err);
            } finally {
              resultSet.close();
            }
          });
        } else {
          reject(new Error('Store is undefined'));
        }
      });
    });
  }

  // 在 satellite_db_control.ts 中添加
  /**
   * 从数据库搜索卫星
   * @param context UIAbility上下文
   * @param keyword 搜索关键词
   * @param page 页码
   * @param pageSize 每页大小
   * @returns Promise<SatelliteTLE[]> 包含完整卫星信息的数组
   */
  public static db_search(context: common.UIAbilityContext, keyword: string, page: number = 1, pageSize: number = 20): Promise<SatelliteTLE[]> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          const offset = (page - 1) * pageSize;
          const sql = 'SELECT norad_id, name, line1, line2, updated_at FROM satellites WHERE name LIKE ? OR norad_id LIKE ? ORDER BY name LIMIT ? OFFSET ?';
          const bindArgs = [`%${keyword}%`, `%${keyword}%`, pageSize, offset];

          (store as relationalStore.RdbStore).querySql(sql, bindArgs, (err, resultSet) => {
            if (err) {
              console.error(`Query failed, code is ${err.code}, message is ${err.message}`);
              reject(err);
              return;
            }

            const satellites: SatelliteTLE[] = [];
            try {
              while (resultSet.goToNextRow()) {
                const satellite: SatelliteTLE = {
                  norad_id: resultSet.getLong(resultSet.getColumnIndex('norad_id')),
                  name: resultSet.getString(resultSet.getColumnIndex('name')),
                  line1: resultSet.getString(resultSet.getColumnIndex('line1')),
                  line2: resultSet.getString(resultSet.getColumnIndex('line2')),
                  updated_at: resultSet.getString(resultSet.getColumnIndex('updated_at'))
                };
                satellites.push(satellite);
              }
              console.info(`Succeeded in searching satellites. Count: ${satellites.length}`);
              resolve(satellites);
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to process result set. Code:${err.code}, message:${err.message}`);
              reject(err);
            } finally {
              resultSet.close();
            }
          });
        } else {
          reject(new Error('Store is undefined'));
        }
      });
    });
  }

  /**
   * 清空卫星表中的所有数据
   * @param context UIAbility上下文
   * @returns Promise<void>
   */
  public static db_clear_all(context: common.UIAbilityContext): Promise<void> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          const sql = 'DELETE FROM satellites';

          (store as relationalStore.RdbStore).executeSql(sql, [], (err) => {
            if (err) {
              console.error(`Failed to clear table. Code:${err.code}, message:${err.message}`);
              reject(err);
              return;
            }

            console.info('Succeeded in clearing all satellite data');
            resolve();
          });
        } else {
          reject(new Error('Store is undefined'));
        }
      });
    });
  }

}


