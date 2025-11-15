// SatelliteService.ets
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 卫星服务基础URL
let satelliteUrl: string = 'http://cq.huwenxin.top:12303/api/'; // 请替换为实际服务器地址

// 1. 卫星TLE数据接口
export interface SatelliteTLE {
  norad_id: number;
  name: string;
  tle1: string;
  tle2: string;
}

// 2. 卫星列表响应接口
export interface SatelliteListResponse {
  success: boolean;
  count: number;
  data: SatelliteTLE[];
}

// 3. 轨道计算请求参数接口
export interface OrbitCalculateRequest {
  norad_id: number;
  lat: number;
  lng: number;
  alt?: number;
  extended?: boolean;
}

// 4. 轨道计算响应接口
export interface OrbitCalculateResponse {
  success: boolean;
  data?: OrbitCalculateData;
  error?: string;
}

// 5. 轨道计算数据接口
export interface OrbitCalculateData {
  basic: BasicInfo;
  position: PositionInfo;
  observer: ObserverInfo;
}

// 6. 基本信息接口
export interface BasicInfo {
  norad_id: number;
  name: string;
  timestamp: string;
  tle_updated: string;
}

// 7. 位置信息接口
export interface PositionInfo {
  eci: EciInfo;
  geodetic: GeodeticInfo;
}

// 8. ECI坐标信息接口
export interface EciInfo {
  x: number;
  y: number;
  z: number;
}

// 9. 地理坐标信息接口
export interface GeodeticInfo {
  longitude: number;
  latitude: number;
  height: number;
  velocity: number;
}

// 10. 观察者信息接口
export interface ObserverInfo {
  azimuth: number;
  elevation: number;
  range: number;
  range_rate: number;
  is_visible: boolean;
}

// 11. 过境轨迹预测响应接口
export interface PassTrajectoryResponse {
  success: boolean;
  pass_info?: PassInfo;
  trajectory?: [number, number][]; // [方位角, 仰角] 的数组
  error?: string;
}

// 12. 过境信息接口
export interface PassInfo {
  pass_number: number;
  start_time: string;
  end_time: string;
  max_elevation_time: string;
  max_elevation: number;
  duration_minutes: number;
}

// 13. 高级过境预测响应接口
export interface AdvancedPassesResponse {
  success: boolean;
  passes?: PassInfo[];
  error?: string;
}

// 14. 轨迹点接口
export interface TrajectoryPoint {
  timestamp: string;
  azimuth: number;
  elevation: number;
  range: number;
  is_visible: boolean;
}

// 15. 轨迹预测响应接口
export interface TrajectoryResponse {
  success: boolean;
  trajectory?: TrajectoryPoint[];
  error?: string;
}

//16. 卫星收发器接口
export interface trans {
  success: boolean;
  total: number;
  data: Transmitter[];
}

export interface Transmitter {
  norad_id: number;
  description: string;
  downlink_frequency: number;
  downlink_mode: string;
  uplink_frequency: number;
  uplink_mode: string;
  invert: boolean;
}


// 卫星服务类
export class SatelliteService {
  // 获取卫星列表
  static async getSatelliteList(limit: number = 10000): Promise<SatelliteListResponse> {
    const mode_url = `satellites?limit=${limit}`;
    const HttpRequestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' }
    };

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        satelliteUrl + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            if (data.responseCode === 200) {
              const response: SatelliteListResponse = JSON.parse(data.result.toString());
              hilog.info(0x0001, "SatelliteService", "获取卫星列表成功");
              resolve(response);
            } else {
              hilog.error(0x0001, "SatelliteService", "获取卫星列表失败: %{public}i", data.responseCode);
              reject(data.responseCode);
            }
            httpRequest.destroy();
          } else {
            hilog.error(0x0001, "SatelliteService", "网络错误: %{public}s", JSON.stringify(err));
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }

  // 计算卫星当前位置
  static async calculateOrbit(
    noradId: number,
    lat: number,
    lng: number,
    alt: number
  ): Promise<OrbitCalculateResponse> {
    const mode_url = 'orbit/calculate';
    const HttpRequestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: {
        norad_id: noradId,
        lat: lat,
        lng: lng,
        alt: alt
      }
    };

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        satelliteUrl + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            if (data.responseCode === 200) {
              const response: OrbitCalculateResponse = JSON.parse(data.result.toString());
              hilog.info(0x0001, "SatelliteService", "计算卫星轨道成功");
              resolve(response);
            } else {
              hilog.error(0x0001, "SatelliteService", "计算卫星轨道失败: %{public}i", data.responseCode);
              reject(data.responseCode);
            }
            httpRequest.destroy();
          } else {
            hilog.error(0x0001, "SatelliteService", "网络错误: %{public}s", JSON.stringify(err));
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }

  // 获取卫星过境轨迹（极简模式）
  static async getPassTrajectory(
    noradId: number,
    lat: number,
    lng: number,
    alt: number = 0,
    duration: number = 10,
    start_time: string
  ): Promise<PassTrajectoryResponse> {
    const mode_url =
      `pass/by-time/${noradId}?lat=${lat}&lng=${lng}&alt=${alt}&start_time=${start_time}&duration=${duration}`;
    const HttpRequestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' }
    };

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        satelliteUrl + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            if (data.responseCode === 200) {
              const response: PassTrajectoryResponse = JSON.parse(data.result.toString());
              hilog.info(0x0001, "SatelliteService", "获取卫星过境轨迹成功");
              resolve(response);
            } else {
              hilog.error(0x0001, "SatelliteService", "获取卫星过境轨迹失败: %{public}i", data.responseCode);
              reject(data.responseCode);
            }
            httpRequest.destroy();
          } else {
            hilog.error(0x0001, "SatelliteService", "网络错误: %{public}s", JSON.stringify(err));
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }

  // 获取高级过境预测（多天过境）
  static async getAdvancedPasses(
    noradId: number,
    lat: number,
    lng: number,
    alt: number = 0,
    days: number = 2,
    minElevation: number = 16
  ): Promise<AdvancedPassesResponse> {
    const mode_url = `passes/${noradId}?lat=${lat}&lng=${lng}&alt=${alt}&days=${days}&min_elevation=${minElevation}`;
    const HttpRequestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' }
    };

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        satelliteUrl + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            if (data.responseCode === 200) {
              const response: AdvancedPassesResponse = JSON.parse(data.result.toString());
              hilog.info(0x0001, "SatelliteService", "获取高级过境预测成功");
              resolve(response);
            } else {
              hilog.error(0x0001, "SatelliteService", "获取高级过境预测失败: %{public}i", data.responseCode);
              reject(data.responseCode);
            }
            httpRequest.destroy();
          } else {
            hilog.error(0x0001, "SatelliteService", "网络错误: %{public}s", JSON.stringify(err));
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }

  // 获取卫星收发器
  static async get_transmitters(): Promise<trans> {
    const mode_url = `transmitters`;
    const HttpRequestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' }
    };

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        satelliteUrl + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            if (data.responseCode === 200) {
              const response: trans = JSON.parse(data.result.toString());
              hilog.info(0x0001, "SatelliteService", "获取卫星收发器成功");
              resolve(response);
            } else {
              hilog.error(0x0001, "SatelliteService", "获取卫星收发器失败: %{public}i", data.responseCode);
              reject(data.responseCode);
            }
            httpRequest.destroy();
          } else {
            hilog.error(0x0001, "SatelliteService", "网络错误: %{public}s", JSON.stringify(err));
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }
}
