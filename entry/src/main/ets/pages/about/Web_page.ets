import { webview } from '@kit.ArkWeb';

//todo 修改信息在上架之前
@Component
export struct beian_web_page {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    NavDestination() {
      Web({ src: 'https://beian.miit.gov.cn', controller: this.controller })
        .cacheMode(CacheMode.Online)
    }
  }
}

@Component
export struct private_huawei_web_page {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    NavDestination() {
      Web({
        src: 'https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN',
        controller: this.controller
      })
    }
  }
}

@Component
export struct private_cq_web_page {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    NavDestination() {
      Web({
        src: 'https://www.xingzitian.top/privacy.html',
        controller: this.controller
      })
    }
  }
}

@Component
export struct ham_set {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    NavDestination() {
      Web({
        src: 'https://ham-dev.c5r.app/',
        controller: this.controller
      })
    }
  }
}

//
// @Component
// export struct private_cq_web_page {
//   controller: webview.WebviewController = new webview.WebviewController();
//
//   build() {
//     NavDestination() {
//       Web({
//         src: 'https://www.xingzitian.top/privacy.html',
//         controller: this.controller
//       })
//     }
//   }
// }
//
// @Component
// export struct private_cq_web_page {
//   controller: webview.WebviewController = new webview.WebviewController();
//
//   build() {
//     NavDestination() {
//       Web({
//         src: 'https://www.xingzitian.top/privacy.html',
//         controller: this.controller
//       })
//     }
//   }
// }