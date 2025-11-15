import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData'; // 导入模块
import { SatelliteTLE,Transmitter } from '../http_server/SatelliteService';

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

            const SQL_CREATE_TABLE =
              'CREATE TABLE satellites (norad_id INT PRIMARY KEY, name VARCHAR(255) NOT NULL, tle1 VARCHAR(255) NOT NULL, tle2 VARCHAR(255) NOT NULL);';

            await store.execute(SQL_CREATE_TABLE);

            // 新增：创建收发器表
            const SQL_CREATE_TABLE_TRANSMITTERS = `CREATE TABLE transmitters (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              norad_id INTEGER NOT NULL,
              description TEXT,
              downlink_frequency INTEGER,
              downlink_mode TEXT,
              uplink_frequency INTEGER,
              uplink_mode TEXT,
              invert INTEGER
            );`;
            await store.execute(SQL_CREATE_TABLE_TRANSMITTERS);

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
            const valueBucket: relationalStore.ValuesBucket = {
              norad_id: data[i].norad_id,
              name: data[i].name,
              tle1: data[i].tle1,
              tle2: data[i].tle2,
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
          const sql = 'SELECT norad_id, name, tle1, tle2 FROM satellites ORDER BY name LIMIT ? OFFSET ?';
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
                  tle1: resultSet.getString(resultSet.getColumnIndex('tle1')),
                  tle2: resultSet.getString(resultSet.getColumnIndex('tle2')),
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
          const sql = 'SELECT norad_id, name, tle1, tle2 FROM satellites WHERE name LIKE ? OR norad_id LIKE ? ORDER BY name LIMIT ? OFFSET ?';
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
                  tle1: resultSet.getString(resultSet.getColumnIndex('tle1')),
                  tle2: resultSet.getString(resultSet.getColumnIndex('tle2')),
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

  // /**
  //  * 清空卫星表中的所有数据
  //  * @param context UIAbility上下文
  //  * @returns Promise<void>
  //  */
  // public static db_clear_all(context: common.UIAbilityContext): Promise<void> {
  //   return new Promise((resolve, reject) => {
  //     relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
  //       if (err) {
  //         console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
  //         reject(err);
  //         return;
  //       }
  //
  //       if (store) {
  //         const sql = 'DELETE FROM satellites';
  //
  //         (store as relationalStore.RdbStore).executeSql(sql, [], (err) => {
  //           if (err) {
  //             console.error(`Failed to clear table. Code:${err.code}, message:${err.message}`);
  //             reject(err);
  //             return;
  //           }
  //
  //           console.info('Succeeded in clearing all satellite data');
  //           resolve();
  //         });
  //       } else {
  //         reject(new Error('Store is undefined'));
  //       }
  //     });
  //   });
  // }

  // 修改原有的清空方法，同时清空两个表
  public static db_clear_all(context: common.UIAbilityContext): Promise<void> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          // 先清空卫星表，再清空收发器表
          const sql_satellites = 'DELETE FROM satellites';
          const sql_transmitters = 'DELETE FROM transmitters';

          (store as relationalStore.RdbStore).executeSql(sql_satellites, [], (err) => {
            if (err) {
              console.error(`Failed to clear satellites table. Code:${err.code}, message:${err.message}`);
              reject(err);
              return;
            }

            (store as relationalStore.RdbStore).executeSql(sql_transmitters, [], (err) => {
              if (err) {
                console.error(`Failed to clear transmitters table. Code:${err.code}, message:${err.message}`);
                reject(err);
                return;
              }

              console.info('Succeeded in clearing all satellite and transmitter data');
              resolve();
            });
          });
        } else {
          reject(new Error('Store is undefined'));
        }
      });
    });
  }

  /**
   * 批量插入收发器数据
   * @param context UIAbility上下文
   * @param data 收发器数据数组
   * @returns Promise<void>
   */
  public static db_put_transmitters(context: common.UIAbilityContext, data: Transmitter[]): Promise<void> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        console.info('Succeeded in getting RdbStore for transmitters.');

        if (store === undefined) {
          reject(new Error('Store is undefined'));
          return;
        }

        console.log("Starting transmitter insertion, n=" + data.length);

        const insertAll = async () => {
          let successCount = 0;
          let errorCount = 0;

          for (let i = 0; i < data.length; i++) {
            const valueBucket: relationalStore.ValuesBucket = {
              norad_id: data[i].norad_id,
              description: data[i].description,
              downlink_frequency: data[i].downlink_frequency,
              downlink_mode: data[i].downlink_mode,
              uplink_frequency: data[i].uplink_frequency,
              uplink_mode: data[i].uplink_mode,
              invert: data[i].invert ? 1 : 0, // 布尔值转换为整数存储
            };

            try {
              const rowId = await store.insert('transmitters', valueBucket);
              console.info(`Succeeded in inserting transmitter data. rowId:${rowId}`);
              successCount++;
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to insert transmitter data. Code:${err.code}, message:${err.message}`);
              errorCount++;
            }
          }

          console.info(`Transmitter insert completed. Success: ${successCount}, Failed: ${errorCount}`);

          if (successCount > 0) {
            resolve();
          } else {
            reject(new Error(`All transmitter insertions failed. Total attempts: ${data.length}`));
          }
        };

        insertAll();
      });
    });
  }


  /**
   * 按卫星NORAD ID查询收发器（参考后端单个卫星查询方法）
   * @param context UIAbility上下文
   * @param noradId 卫星NORAD ID
   * @returns Promise<Transmitter[]> 指定卫星的收发器数组
   */
  public static db_get_transmitters_by_norad(context: common.UIAbilityContext, noradId: number): Promise<Transmitter[]> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          const sql = 'SELECT norad_id, description, downlink_frequency, downlink_mode, uplink_frequency, uplink_mode, invert FROM transmitters WHERE norad_id = ? ORDER BY downlink_frequency ASC';
          const bindArgs = [noradId];

          (store as relationalStore.RdbStore).querySql(sql, bindArgs, (err, resultSet) => {
            if (err) {
              console.error(`Query transmitters by norad failed, code is ${err.code}, message is ${err.message}`);
              reject(err);
              return;
            }

            const transmitters: Transmitter[] = [];
            try {
              while (resultSet.goToNextRow()) {
                const transmitter: Transmitter = {
                  norad_id: resultSet.getLong(resultSet.getColumnIndex('norad_id')),
                  description: resultSet.getString(resultSet.getColumnIndex('description')),
                  downlink_frequency: resultSet.getDouble(resultSet.getColumnIndex('downlink_frequency')),
                  downlink_mode: resultSet.getString(resultSet.getColumnIndex('downlink_mode')),
                  uplink_frequency: resultSet.getDouble(resultSet.getColumnIndex('uplink_frequency')),
                  uplink_mode: resultSet.getString(resultSet.getColumnIndex('uplink_mode')),
                  invert: resultSet.getLong(resultSet.getColumnIndex('invert')) === 1,
                };
                transmitters.push(transmitter);
              }
              console.info(`Succeeded in querying transmitters for norad_id ${noradId}. Count: ${transmitters.length}`);
              resolve(transmitters);
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to process transmitter result set. Code:${err.code}, message:${err.message}`);
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
   * 获取收发器总数
   * @param context UIAbility上下文
   * @returns Promise<number> 收发器总数
   */
  public static db_get_transmitters_count(context: common.UIAbilityContext): Promise<number> {
    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }

        if (store) {
          const sql = 'SELECT COUNT(*) as total_count FROM transmitters';

          (store as relationalStore.RdbStore).querySql(sql, [], (err, resultSet) => {
            if (err) {
              console.error(`Query transmitters count failed, code is ${err.code}, message is ${err.message}`);
              reject(err);
              return;
            }

            try {
              let count = 0;
              if (resultSet.goToNextRow()) {
                count = resultSet.getLong(resultSet.getColumnIndex('total_count'));
              }
              console.info(`Succeeded in querying transmitter count: ${count}`);
              resolve(count);
            } catch (error) {
              const err = error as BusinessError;
              console.error(`Failed to process transmitter count result set. Code:${err.code}, message:${err.message}`);
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

}


