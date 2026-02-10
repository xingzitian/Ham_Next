import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

//学习记录，关于promise的返回值的设置
//1.resolve是成功
//2.reject是返回失败的方法
//3.初始状态是pending，等待中，进行异步的操作

let url_main: string = 'http://10.12.8.7:8080';
let HttpRequestOptions: http.HttpRequestOptions = {};
let mode_url = '';

//对于用户注册和登录的时候返回的格式
interface user {
  success: boolean,
  message: string,
  code: number,
  data: data_user,
}

interface data_user {
  id: number,
  token: string,
  callsign: string,
  email: string
}

interface res_add_log {
  success: boolean,
  message: string,
  code: number,
  data: string,
}

//发送日志记录的时候的模板
interface tx_log {
  contactCallsign: string,
  timestamp: string,
  frequency: number,
  mode: string,
  sentReport: string,
  receivedReport: string,
  notes: string // 可选字段
}

interface res_log_list {
  success: boolean,
  message: string,
  code: number,
  data: rx_log[],
}

interface rx_log {
  id: number,
  contactCallsign: string,
  date: string,
  frequency: number,
  mode: string,
  sentReport: string,
  receivedReport: string,
  description: string,
}


interface res_once_log {
  success: boolean,
  message: string,
  code: number,
  data: rx_log
}

class http_id {
  static async httpRequest(mode: number, password: string, callsign: string, email?: string): Promise<user> {
    if (mode === 1) {
      //注册
      mode_url = '/user/register'
      HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: {
          "callsign": callsign,
          "password": password,
          "email": email
        },
      }
    } else if (mode === 2) {
      //进行登录
      mode_url = '/user/login'
      HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: {
          "callsign": callsign,
          "password": password
        }
      }
    }
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
              const res: user= JSON.parse(data.result + '');
              hilog.info(0x0001, "http_login", "http_login:%{public}i", res.code);
              if(res.success===true){
                resolve(res);
              }else{
                reject(res.message);
              }

            // 当该请求使用完毕时，开发者务必调用 destroy 方法主动销毁该 JavaScript Object。
            httpRequest.destroy();

          } else {
            console.info('error:' + JSON.stringify(err));
            // 当该请求使用完毕时，开发者务必调用 destroy 方法主动销毁该 JavaScript Object。
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }
}

class http_log_add {
  static async httpRequest(tx: tx_log, token: string): Promise<res_add_log> {
    //创建队伍
    mode_url = '/log/add'
    HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      extraData: {
        "contactCallsign": tx.contactCallsign,
        "date": tx.timestamp,
        "frequency": tx.frequency,
        "mode": tx.mode,
        "sentReport": tx.sentReport,
        "receivedReport": tx.receivedReport,
        "description": tx.notes // 可选字段

      }
    }

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            console.log('http_add_log：' + data.result);
            const res: res_add_log = JSON.parse(data.result + '');
            hilog.info(0x0001, "http_add_log", "log_interface_httpcode:%{public}i", res.code);
            if(res.success===true){
              resolve(res);
            }else{
              reject(res.message);
            }

            httpRequest.destroy();
          } else {
            console.info('error:' + JSON.stringify(err));
            // 当该请求使用完毕时，开发者务必调用 destroy 方法主动销毁该 JavaScript Object。
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }
}

class http_list_logs {
  //这个都是查询或者添加相关的路由
  static async httpRequest( token: string,page?: number, reateDate?:string,mode?:string,minFrequency?:string,maxFrequency?:string,callsign?:string): Promise<res_log_list> {
    //获取日志列表
    mode_url = '/log/select'
    HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      extraData:{
        "createDate":reateDate,
        "mode":mode,
        "minFrequency":minFrequency,
        "maxFrequency":maxFrequency,
        "callsign":callsign,
        "pageNum":page
    }
    }

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            const res: res_log_list = JSON.parse(data.result + '');
            console.log(data.result as string)
            hilog.info(0x0001, "http_list_logs", "http_list_logs:%{public}i",res.code);
            console.log('http_list_logs：' + data.result);
            if(res.success===true){
              resolve(res);
            }else{
              reject(res.message);
            }
            httpRequest.destroy();
          } else {
            console.info('error:' + JSON.stringify(err));
            // 当该请求使用完毕时，开发者务必调用 destroy 方法主动销毁该 JavaScript Object。
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }
}

class http_once_logs {
  //这个都是查询或者添加相关的路由
  static async httpRequest(log_id: string, token: string): Promise<res_once_log> {
    //获取日志列表
    mode_url = "/log/get_info"
    HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      extraData:{
        id:log_id
      },
    }


    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            // data.header 为 HTTP 响应头，可根据业务需要进行解析
            console.log(data.result as string)
            const res: res_once_log = JSON.parse(data.result + '');
            hilog.info(0x0001, "http_once_logs", "http_once_logs:%{public}i",res.message);
            console.log('http_once_logs：' + data.result);
            if(res.success===true){
              resolve(res);
            }else{
              reject(res.message);
            }

            httpRequest.destroy();
          } else {
            console.info('error:' + JSON.stringify(err));
            // 当该请求使用完毕时，开发者务必调用 destroy 方法主动销毁该 JavaScript Object。
            httpRequest.destroy();
            reject(err);
          }
        }
      );
    });
  }
}


export {
  tx_log,
  rx_log,
  res_add_log,
  res_log_list,
  res_once_log,
  http_id,
  http_log_add,
  http_list_logs,
  http_once_logs
};