import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

//学习记录，关于promise的返回值的设置
//1.resolve是成功
//2.reject是返回失败的方法
//3.初始状态是pending，等待中，进行异步的操作

let url_main: string = 'http://cq.zhangyulin.top:8000/api/';
let HttpRequestOptions: http.HttpRequestOptions = {};
let mode_url = '';

//对于用户注册和登录的时候返回的格式
interface res_user {
  success:boolean,
  message:string,
  data:data_user,
}

interface data_user{
  user:user_data,
  token:string
}

//这个是用户注册登录返回的data具体内容
interface user_data {
  id: number,
  callsign: string,
  email:string,

}

//发送日志记录的时候的模板
interface tx_log {
  contactCallsign: string,
  timestamp: string, // ISO 8601 格式的日期字符串
  frequency: number,
  mode: string,
  sentReport: string,
  receivedReport: string,
  notes: string // 可选字段
}
//接受日志记录的时候的模板
interface rx_log {
  id: number,
  contactCallsign: string,
  timestamp: string,
  frequency: number,
  mode: string,
  sentReport:string,
  receivedReport: string,
  notes: string,
  user_id: number,
  createdAt: string,
  updatedAt:string
}
//这个是用获取日志返回结构体

//这个是添加log的响应
interface res_add_log {
  success:boolean,
  message:string,
  data:rx_log
}
//这个是用获取日志列表返回的分页信息
interface pagination{
  currentPage: number,
  totalPages: number,
  totalCount: number,
  hasNext: boolean,
  hasPrev: boolean
}
//这个是返回日志列表的data内容
interface log_list{
  logs:rx_log[],
  pagination:pagination
}


//这个是用获取日志列表结构
interface res_log_list{
  success:boolean,
  message:string,
  data:log_list
}

interface res_once_log{
  success:boolean,
  message:string,
  data: rx_log
}
//通用的返回格式
interface message{
  success: boolean,
  message: string
}

class http_id {
  static async httpRequest(mode:number ,password:string,callsign: string, email?:string): Promise<res_user> {
    if (mode === 1) {
      //注册
      mode_url = 'users/register'
      HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: {
          "callsign": callsign,
          "password": password,
          "email":email
        },
      }
    } else if (mode === 2) {
      //进行登录
      mode_url = 'users/login'
      HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json'},
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
            if(data.responseCode === 409 || data.responseCode === 401 || data.responseCode === 400){
              reject(data.responseCode)
              hilog.error(0x0001, "http_login", "http_login:%{public}i", data.responseCode);
            }
            if (data.responseCode === 200 ||data.responseCode === 201) {
              const res: res_user = JSON.parse(data.result + '');
              hilog.info(0x0001, "http_login", "http_login:%{public}i", data.responseCode);
              resolve(res);
            } else {
              reject("error:出现未知错误")
              hilog.error(0x0001, "http_login：", "出现未知错误");
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
  static async httpRequest(tx:tx_log ,token: string): Promise<res_add_log> {
    //创建队伍
    mode_url = 'logs'
    HttpRequestOptions = { method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      extraData: {
        "contactCallsign": tx.contactCallsign,
        "timestamp": tx.timestamp, // ISO 8601 格式的日期字符串
        "frequency":tx.frequency,
        "mode": tx.mode,
        "sentReport": tx.sentReport,
        "receivedReport": tx.receivedReport,
        "notes": tx.notes // 可选字段

      }
    }

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            console.log(data.result as string)
            if (data.responseCode !== 201) {
              hilog.error(0x0001, "http_add_log", "log_interface_httpcode:%{public}i", data.responseCode);
              reject(data.responseCode)
            }
            if (data.responseCode === 201) {
              hilog.info(0x0001, "http_add_log", "log_interface_httpcode:%{public}i", data.responseCode);
              console.log('http_add_log：' + data.result);
              const responseObj: res_add_log = JSON.parse(data.result + '');
              resolve(responseObj);
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
  static async httpRequest( use:number,page:number, token: string,extar:string): Promise<res_log_list> {
    //获取日志列表
    if(use===0){
      mode_url = 'logs?page=1&limit=5'
    }
    else{
      mode_url = 'logs?limit=5&page='+page+ extar
    }
    HttpRequestOptions = { method: http.RequestMethod.GET,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      }
    }

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            console.log(data.result as string)
            if (data.responseCode !== 200) {
              hilog.error(0x0001, "http_list_logs", "http_list_logs:%{public}i", data.responseCode);
              reject(data.responseCode)
            }
            if (data.responseCode === 200) {
              hilog.info(0x0001, "http_list_logs", "http_list_logs:%{public}i", data.responseCode);
              console.log('http_list_logs：' + data.result);
              const responseObj: res_log_list = JSON.parse(data.result + '');
              resolve(responseObj);
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
  static async httpRequest( log_id:string, token: string): Promise<res_once_log> {
    //获取日志列表
    mode_url = 'logs/'+log_id
    HttpRequestOptions = { method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
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
            const responseObj: res_once_log = JSON.parse(data.result + '');
            if (data.responseCode !== 200) {
              hilog.error(0x0001, "http_once_logs", "http_once_logs:%{public}i", data.responseCode);
              reject(responseObj.message)
            }
            if (data.responseCode === 200) {
              hilog.info(0x0001, "http_once_logs", "http_once_logs:%{public}i", data.responseCode);
              console.log('http_once_logs：' + data.result);
              const responseObj: res_once_log = JSON.parse(data.result + '');
              resolve(responseObj);
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
  res_user,user_data,tx_log,rx_log,res_add_log,res_log_list,res_once_log,
  http_id,http_log_add,http_list_logs,http_once_logs
};