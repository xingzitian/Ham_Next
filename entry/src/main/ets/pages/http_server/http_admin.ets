import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TeamData, message } from './httpService'

let url_main: string = 'https://app.huiyou.zhangyulin.top:3000/api/';
let audit_status: string = ''

class http_admin_teams_get {
  static async httpRequest(token: string): Promise<Array<TeamData>> {
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + 'admin/teamsToAudit',
        {
          header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
          method: http.RequestMethod.GET,
        },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            hilog.info(0x0001, "http_admin_teams_get", "http_unionID_login:%{public}i", data.responseCode);
            const responseObj: object = JSON.parse(data.result + '');
            if (data.responseCode !== 200) {
              promptAction.showToast({
                message: responseObj["message"]
              });
            }

            if (data.responseCode === 200) {
              const responseObj: Array<TeamData> = JSON.parse(data.result + '');
              console.log('http_admin_teams_get:' + data.result);
              console.log('http_admin_teams_get:' + responseObj[0].team_name);
              resolve(responseObj);
            } else {
              reject(responseObj["message"])
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

class http_admin_teams_change {
  static async httpRequest(token: string, team_code: string, approvalResult: string): Promise<number> {
    return new Promise((resolve, reject) => {
      let approvalComment: string;
      if (approvalResult === 'approved') {
        approvalComment = '队伍信息合法，审核通过'
        audit_status = '通过'
      } else {
        approvalComment = '队伍信息不合法，审核不通过'
        audit_status = '不通过'
      }
      let httpRequest = http.createHttp();
      httpRequest.request(
        url_main + 'admin/auditTeam',
        {
          method: http.RequestMethod.PUT,
          header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
          extraData: {
            "team_code": team_code,
            "audit_status": audit_status,
            "opinion_content": approvalComment
          }
        },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            hilog.info(0x0001, "http_admin_teams_get", "http_unionID_login:%{public}i", data.responseCode);
            const responseObj: Array<message> = JSON.parse(data.result + '');
            promptAction.showToast({
              message: responseObj["message"]
            });
            if (data.responseCode !== 200) {
              reject(responseObj["message"])
            }
            console.log(String(data.responseCode))
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
  http_admin_teams_get, http_admin_teams_change
};