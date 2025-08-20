/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */
import { Constants, BtnType, IBtnOption } from '../common/Constants';

@Extend(Text)
function pageText() {
  .fontSize($r('sys.float.ohos_id_text_size_body1'))
  .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
  .fontWeight(FontWeight.Medium)
  .fontColor($r('sys.color.ohos_id_color_text_primary'))
  .maxLines(1)
}

@ComponentV2
export struct UIPagination {
  /**
   * 按钮选项
   */
  @Param btnOption: IBtnOption = {
    prevText: Constants.PREV_TEXT_DEFAULT,
    nextText: Constants.NEXT_TEXT_DEFAULT,
    btnFgSize: Constants.BTN_FG_SIZE_DEFAULT,
    btnFgColor: Constants.BTN_FG_COLOR_DEFAULT,
    btnIconColor: Constants.BTN_ICON_COLOR_DEFAULT,
    btnBgColor: Constants.BTN_BG_COLOR_DEFAULT,
    showIcon: true,
    iconH: Constants.ICON_DEFAULT_H,
  };
  /**
   * 设置是否支持输入模式
   */
  @Param enableInput: boolean = true;
  /**
   * 页码字体大小
   */
  @Param pageFgSize: Length = $r('sys.float.ohos_id_text_size_body1');
  /**
   * 主题色
   */
  @Param themeColor: ResourceColor = $r('sys.color.ohos_id_color_emphasize');
  /**
   * 当前页
   */
  @Param currentPage: number = 1;

  @Monitor('currentPage')
  currentPageChange(monitor: IMonitor) {
    let now = monitor.value()?.now as number;
    now = Math.ceil(now);
    if (now > 0 && now <= this.getTotalPageNum) {
      this.curPageV = now;
    }
  }

  /**
   * 数据总量
   */
  @Param total: number = 1;

  @Monitor('total')
  totalChange(monitor: IMonitor) {
    const total = monitor.value()?.now as number;
    this.totalV = total;
    if (this.totalV <= 0) {
      this.totalV = 1;
    }
    const totalPage = Math.ceil(this.totalV / this.pageSizeV);
    if (this.curPageV > totalPage) {
      this.curPageV = totalPage;
      this.change(this.curPageV);
    }
  }

  /**
   * 每页数据量
   */
  @Param pageSize: number = Constants.PAGE_SIZE_DEFAULT;

  @Monitor('pageSize')
  pageSizeChange(monitor: IMonitor) {
    const now = monitor.value()?.now as number;
    if (now > 0) {
      this.pageSizeV = Math.ceil(now);
      this.curPageV = 1;
      this.change(this.curPageV);
    }
  }

  /**
   * 点击按钮时触发
   */
  @Event change: (currentV: number) => void = (currentV: number) => {
  };
  @Local curPageV: number = 0;
  @Local pageSizeV: number = Constants.PAGE_SIZE_DEFAULT;
  @Local inputV: string = '';
  @Local totalV: number = 1;
  @Local isEditing: boolean = false;

  aboutToAppear(): void {
    // 处理非法输入
    this.handleCustomInput();
  }

  handleCustomInput() {
    this.totalV = this.total;
    if (this.totalV <= 0) {
      this.totalV = 1;
    }
    if (this.pageSize > 0) {
      this.pageSizeV = Math.ceil(this.pageSize);
    }
    this.curPageV = Math.ceil(this.currentPage);
    if (this.curPageV <= 0) {
      this.curPageV = 1;
    }
    const totalPage = Math.ceil(this.totalV / this.pageSizeV);
    if (this.curPageV > totalPage) {
      this.curPageV = totalPage;
    }
  }

  isEnabled(btnType: BtnType) {
    if (btnType === BtnType.PREV) {
      return this.curPageV > 1;
    }
    return this.curPageV < this.getTotalPageNum;
  }

  handlePageInput(value: string) {
    if (!value) {
      this.curPageV = 1;
      this.change(this.curPageV);
      return;
    }
    const page = Number(value);
    if (page <= 0) {
      this.curPageV = 1;
    } else if (page > this.getTotalPageNum) {
      this.curPageV = this.getTotalPageNum;
    } else {
      this.curPageV = page;
    }
    this.change(this.curPageV);
  }

  @Computed
  get getTotalPageNum() {
    return Math.ceil(this.totalV / this.pageSizeV);
  }

  @Builder
  buildBtn(btnType: BtnType) {
    Button() {
      if (this.btnOption.showIcon ?? true) {
        Image(btnType === BtnType.PREV ? $r('app.media.ic_public_arrow_left') : $r('app.media.ic_public_arrow_right'))
          .height(this.btnOption.iconH ?? Constants.ICON_DEFAULT_H)
          .objectFit(ImageFit.Cover)
          .fillColor(this.btnOption.btnIconColor ?? Constants.BTN_ICON_COLOR_DEFAULT)
      } else {
        Text(btnType === BtnType.PREV ? (this.btnOption.prevText ?? Constants.PREV_TEXT_DEFAULT) :
          (this.btnOption.nextText ?? Constants.NEXT_TEXT_DEFAULT))
          .fontColor(this.btnOption.btnFgColor ?? Constants.BTN_FG_COLOR_DEFAULT)
          .fontSize(this.btnOption.btnFgSize ?? Constants.BTN_FG_SIZE_DEFAULT)
          .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
          .maxLines(1)
      }
    }
    .type(ButtonType.Normal)
    .enabled(this.isEnabled(btnType))
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8,
    })
    .borderRadius($r('sys.float.ohos_id_corner_radius_mark'))
    .backgroundColor(this.btnOption.btnBgColor ?? Constants.BTN_BG_COLOR_DEFAULT)
    .onClick(() => {
      if (btnType === BtnType.PREV) {
        this.curPageV--;
      } else {
        this.curPageV++;
      }
      this.change(this.curPageV);
    })
  }

  build() {
    Row() {
      this.buildBtn(BtnType.PREV)
      if (this.enableInput) {
        Row() {
          TextInput({ text: this.curPageV.toString() })
            .type(InputType.Number)
            .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isEditing ? $r('sys.color.ohos_id_color_text_primary') : this.themeColor)
            .maxLines(1)
            .fontSize(this.pageFgSize)
            .borderColor(this.isEditing ? this.themeColor : Color.Transparent)
            .borderWidth(1)
            .borderRadius($r('sys.float.ohos_id_corner_radius_mark'))
            .padding({
              left: 4,
              right: 4,
            })
            .backgroundColor(Color.Transparent)
            .width('auto')
            .onChange((value: string) => {
              this.inputV = value;
            })
            .onEditChange((value) => {
              this.isEditing = value;
              if (!this.isEditing) {
                this.handlePageInput(this.inputV);
              }
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)
        .margin({ left: 12 })
      } else {
        Scroll() {
          Text(this.curPageV.toString())
            .pageText()
            .fontSize(this.pageFgSize)
            .fontColor(this.themeColor)
            .padding({
              top: 2,
              bottom: 2,
              left: 4,
              right: 4,
            })
        }
        .scrollable(ScrollDirection.Horizontal)
        .align(Alignment.End)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .margin({ left: 12 })

      }

      Text('/')
        .pageText()
        .width(24)
        .fontSize(this.pageFgSize)
        .textAlign(TextAlign.Center)
        .alignSelf(ItemAlign.Center)
        .margin({ left: 2, right: 2 })

      Scroll() {
        Text(this.getTotalPageNum.toString())
          .pageText()
          .fontSize(this.pageFgSize)
          .padding({
            top: 2,
            bottom: 2,
            left: 4,
            right: 4,
          })

      }
      .scrollable(ScrollDirection.Horizontal)
      .align(Alignment.Start)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .margin({ right: 12 })

      this.buildBtn(BtnType.NEXT)
    }
    .width('100%')
  }
}
