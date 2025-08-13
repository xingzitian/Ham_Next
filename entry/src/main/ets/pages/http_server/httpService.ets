import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { data } from '@kit.TelephonyKit';

//学习记录，关于promise的返回值的设置
//1.resolve是成功
//2.reject是返回失败的方法
//3.初始状态是pending，等待中，进行异步的操作

let url_main: string = 'http://192.168.3.132:3000/api/';
let HttpRequestOptions: http.HttpRequestOptions = {};
let mode_url = '';
//通用的返回格式
interface Request{
  success: boolean
  message: string
}
//对于用户注册和登录的时候返回的格式
interface res_user {
  success:boolean,
  message:string,
  data:user_data
}
//这个是用户注册登录返回的data具体内容
interface user_data {
  token:string,
  user:user
}
//暂时没有用上的用户模型
interface user {
  user_id:number,
  username:string,
  phone:string,
  email:string,
  is_verified:number
}
//发送日志记录的时候的模板
interface tx_log {
  log_date: string,
  log_time: string,
  frequency: number,
  other_username: string,
  rx_report: number,
  tx_report: number,
  summary: string
}
//接受日志记录的时候的模板
interface rx_log {
  log_id: number,
  log_date: string,
  log_time: string,
  frequency: number,
  other_username: string,
  rx_report: number,
  tx_report: number,
  summary: string,
  user_id: number
}
//这个是用获取日志返回的data具体内容
interface log_message{
  logId:number
}

interface res_add_log {
  success:boolean,
  message:string,
  data:log_message
}
//这个是用获取日志列表返回的data具体内容
interface res_log_list_data{
  total: number,
  pages: number,
  currentPage: number,
  logs:rx_log[]
}
//这个是用获取日志列表结构
interface res_log_list{
  success:boolean,
  message:string,
  data:res_log_list_data
}

interface res_once_log{
  success:boolean,
  message:string,
  data:rx_log
}

interface log_delete_res{
  success: boolean,
  message: string
}

class http_id {
  static async httpRequest(username: string, phone: string ,email:string,pass_num:string,mode:number ,token?:string): Promise<res_user> {
    if (mode === 1) {
      //注册
      mode_url = 'users/register'
      HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: {
          "username": username,    // 字符串，3-50字符，必填
          "phone": phone,    // 字符串，有效的手机号，必填
          "email": email, // 字符串，有效的邮箱格式，可选
          "password": pass_num       // 字符串，至少6位，必填
        },
      }
    } else if (mode === 2) {
      //进行登录
      mode_url = 'users/login'
      HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json'},
        extraData: {
          "phone": phone,    // 字符串，有效的手机号，必填
          "password": pass_num       // 字符串，必填
        }
      }
    } else if (mode === 3) {
      //获取当前用户信息
      mode_url = 'users/men'
      HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json','Authorization': 'Bearer ' + token},
      }
    }
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            hilog.info(0x0001, "http_login：", "http_login:%{public}i", data.responseCode);
            const responseObj: Array<res_user> = JSON.parse(data.result + '');
            promptAction.showToast({
              message: responseObj["message"]
            });

            if (data.responseCode === 200) {
              const res: res_user = JSON.parse(data.result + '');
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
          "log_date": tx.log_date,   // 字符串，日期格式YYYY-MM-DD，必填
          "log_time": tx.log_time,     // 字符串，时间格式HH:MM:SS，必填
          "frequency": tx.frequency,       // 数字，频率值，必填
          "other_username": tx.other_username, // 字符串，对方用户名，必填
          "rx_report": tx.rx_report,            // 整数，收方信号报告，必填
          "tx_report": tx.tx_report,            // 整数，发方信号报告，必填
          "summary": tx.summary    // 字符串，内容摘要，可选

        }
      }

    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + mode_url,
        HttpRequestOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            // data.header 为 HTTP 响应头，可根据业务需要进行解析
            hilog.info(0x0001, "http_add_log：", "log_interface_httpcode:%{public}i", data.responseCode);
            console.log(data.result as string)
            const responseObj: object = JSON.parse(data.result + '');
            if (data.responseCode !== 201) {
              reject(responseObj["message"])
              promptAction.showToast({
                message: responseObj["message"]
              });
            }
            if (data.responseCode === 201) {
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
  static async httpRequest( date:string,page:string,limit:string, token: string): Promise<Array<res_log_list>> {
      //获取日志列表
      mode_url = 'logs?'+"data="+date+"&"+"page="+page+"&"+"limit="+limit
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
            hilog.info(0x0001, "http_list_logs：", "teams_interface_httpcode:%{public}i", data.responseCode);
            console.log(data.result as string)
            const responseObj: object = JSON.parse(data.result + '');
            if (data.responseCode !== 200) {
              reject(responseObj["message"])
              promptAction.showToast({
                message: responseObj["message"]
              });
            }
            if (data.responseCode === 200) {
              console.log('http_list_logs：' + data.result);
              const responseObj: Array<res_log_list> = JSON.parse(data.result + '');
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
  static async httpRequest( log_id:string, token: string): Promise<Array<res_once_log>> {
    //获取日志列表
    mode_url = 'logs?'+log_id
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
            hilog.info(0x0001, "http_once_logs：", "teams_interface_httpcode:%{public}i", data.responseCode);
            console.log(data.result as string)
            const responseObj: object = JSON.parse(data.result + '');
            if (data.responseCode !== 200) {
              reject(responseObj["message"])
              promptAction.showToast({
                message: responseObj["message"]
              });
            }
            if (data.responseCode === 200) {
              console.log('http_once_logs：' + data.result);
              const responseObj: Array<res_once_log> = JSON.parse(data.result + '');
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

class http_logs_manage {
  //这个都是查询或者添加相关的路由
  static async httpRequest(log_id: string,token:string): Promise<Array<log_delete_res>> {
      //删除队伍
      mode_url = 'logs/' + log_id
      HttpRequestOptions = { method: http.RequestMethod.DELETE,
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
            hilog.info(0x0001, "http_log_delete", "log_interface_httpcode:%{public}i", data.responseCode);
            console.log(data.result as string)
            const responseObj: object = JSON.parse(data.result + '');
            if (data.responseCode !== 200) {
              reject(responseObj["message"])
              promptAction.showToast({
                message: responseObj["message"]
              });
            }
            if (data.responseCode === 200) {
              console.log('http_log_delete' + data.result);
              const responseObj: Array<log_delete_res> = JSON.parse(data.result + '');
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
  Request,res_user,user_data,user,tx_log,rx_log,log_message,res_add_log,res_log_list_data,res_log_list,res_once_log,log_delete_res,
  http_id,http_log_add,http_list_logs,http_once_logs,http_logs_manage
};