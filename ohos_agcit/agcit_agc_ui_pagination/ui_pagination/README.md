# 分页器 UIPagination

## 简介

UIPagination，是一个基于open harmony基础组件开发的分页器按钮，包含图标按钮版本、文字按钮版本、支持输入当前页码以及支持设置主题色等。

## 快速开始

### 安装

```
ohpm install @hw-agconnect/ui-pagination
```

### 使用

```

// 在业务页面使用组件，比如xxx.ets
import { UIPagination } from '@hw-agconnect/ui-pagination';

UIPagination({
    currentPage: this.currentPage,
    total: this.totalNum,
    change: (currentV: number) => {
      this.onPageChange(currentV);
    }
})

```

### 相关权限

无

### 约束与限制

1.本示例仅支持标准系统上运行，支持设备：华为手机。

2.HarmonyOS系统：HarmonyOS 5.0.0 Release及以上。

3.DevEco Studio版本：DevEco Studio 5.0.0 Release及以上。

4.HarmonyOS SDK版本：HarmonyOS 5.0.0 Release SDK及以上。

## 子组件

无

## 接口

### UIPagination(option: UIPaginationOptions)

**UIPaginationOptions对象说明**

| <div style="width:200px" align="left" >名称</div> | <div style="width:200px" align="left" >类型</div> | <div style="width:80px" align="left" >必填</div> | <div style="width:200px" align="left" >说明</div> |
|:------------------------------------------------|:------------------------------------------------|:-----------------------------------------------|:------------------------------------------------|
| currentPage                                     | number                                          | 否                                              | 当前页                                             |
| total                                           | number                                          | 否                                              | 数据总量                                            |
| pageSize                                        | number                                          | 否                                              | 每页数据量                                           |
| enableInput                                     | boolean                                         | 否                                              | 是否支持输入当前页码，默认值：true                             |
| pageFgSize                                      | Length                                          | 否                                              | 页码字体大小                                          |
| themeColor                                      | ResourceColor                                   | 否                                              | 主题色，可以控制当前页码的颜色和输入框颜色                           |
| btnOption                                       | IBtnOption                                      | 否                                              | 按钮选项                                            |

**IBtnOption对象说明**

| <div style="width:300px" align="left" >名称</div> | <div style="width:300px" align="left" >类型</div> | <div style="width:80px" align="left" >必填</div> | <div style="width:200px" align="left" >说明</div> |
|:------------------------------------------------|:------------------------------------------------|------------------------------------------------|-------------------------------------------------|
| prevText                                        | ResourceStr                                     | 否                                              | 左侧按钮文字                                          |
| nextText                                        | ResourceStr                                     | 否                                              | 右侧按钮文字                                          |
| showIcon                                        | boolean                                         | 否                                              | 是否图标版本按钮，默认值：true                               |
| btnFgSize                                       | Length                                          | 否                                              | 按钮文字大小                                          |
| btnFgColor                                      | ResourceColor                                   | 否                                              | 按钮文字颜色                                          |
| btnIconColor                                    | ResourceColor                                   | 否                                              | 按钮图标颜色                                          |
| btnBgColor                                      | ResourceColor                                   | 否                                              | 按钮背景颜色                                          |
| iconH                                           | number                                          | 否                                              | 设置图标按钮中图标高度，默认值：16。                             |

## 事件

| <div style="width:300px" align="left" >名称</div> | <div style="width:300px" align="left" >功能描述</div> |
|:------------------------------------------------|:--------------------------------------------------|
| change(callback: (currentV: number) => void)    | 当前页码改变时触发事件                                       |

## 示例

### 示例1

```
import { UIPagination } from '@hw-agconnect/ui-pagination';

@ComponentV2
struct Card {
  @Param title: string = '';
  @BuilderParam content: () => void;

  build() {
    Column({ space: 10 }) {
      Text(this.title).fontSize(16).fontWeight(500)
      Column() {
        if (this.content) {
          this.content();
        }
      }
      .width('100%')
      .padding(16)
      .borderRadius(12)
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    }
    .alignItems(HorizontalAlign.Start)
  }
}

@Entry
@ComponentV2
struct PaginationSample1 {
  @Local currentPage: number = 1;
  @Local totalNum: number = 50;
  @Local pageSize: number = 10;
  onPageChange: (currentV: number) => void = (currentV: number) => {
    this.currentPage = currentV;
  };

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Card({ title: '默认样式（图标版）' }) {
            UIPagination({
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              }
            })
          }

          Card({ title: '文字样式' }) {
            UIPagination({
              btnOption: {
                showIcon: false,
              },
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              }
            })
          }

          Card({ title: '精简版' }) {
            UIPagination({
              btnOption: {
                btnBgColor: Color.Transparent,
              },
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              }
            })
          }

          Card({ title: '页码只读' }) {
            UIPagination({
              enableInput: false,
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              }
            })
          }
        }
        .width('100%')
      }
      .padding(16)
      .height('100%')
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.TopStart)
    }
    .title('基础用法')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
```

![基础用法](https://agc-storage-drcn.platform.dbankcloud.cn/v0/qwer-wdt80/ui_component_screenshots%2Fscreenshot_20250121_193542.jpg?token=c1256261-8f18-4694-be7d-71e5b293e395)

### 示例2

```
import { UIPagination } from '@hw-agconnect/ui-pagination';

@ComponentV2
struct Card {
  @Param title: string = '';
  @BuilderParam content: () => void;

  build() {
    Column({ space: 10 }) {
      Text(this.title).fontSize(16).fontWeight(500)
      Column() {
        if (this.content) {
          this.content();
        }
      }
      .width('100%')
      .padding(16)
      .borderRadius(12)
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    }
    .alignItems(HorizontalAlign.Start)
  }
}

@Entry
@ComponentV2
struct PaginationSample1 {
  @Local currentPage: number = 1;
  @Local totalNum: number = 50;
  @Local pageSize: number = 10;
  onPageChange: (currentV: number) => void = (currentV: number) => {
    this.currentPage = currentV;
  };

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Card({ title: '文字样式(自定义)' }) {
            UIPagination({
              btnOption: {
                showIcon: false,
                prevText: '前一页',
                nextText: '后一页',
              },
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              },
            })
          }

          Card({ title: '设置字号和图标大小' }) {
            UIPagination({
              btnOption: {
                iconH: 20,
              },
              pageFgSize: 20,
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              },
            })
          }

          Card({ title: '自定义主题色' }) {
            UIPagination({
              themeColor: Color.Pink,
              currentPage: this.currentPage,
              total: this.totalNum,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              },
            })
          }

          Card({ title: '超长数据' }) {
            UIPagination({
              currentPage: this.currentPage,
              total: 99999999999991 * this.pageSize,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              },
            })
          }

          Card({ title: '只读超长数据' }) {
            UIPagination({
              enableInput: false,
              currentPage: 1666666666667,
              total: 99999999999991 * this.pageSize,
              change: (currentV: number) => {
                this.onPageChange(currentV);
              },
            })
          }
        }
        .width('100%')
      }
      .padding(16)
      .height('100%')
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.TopStart)
    }
    .title('自定义参数')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
```

![自定义参数](https://agc-storage-drcn.platform.dbankcloud.cn/v0/qwer-wdt80/ui_component_screenshots%2Fscreenshot_20250121_193552.jpg?token=e19f60e1-253d-42f6-8f5b-85bcdba89434)