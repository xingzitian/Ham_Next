/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

/**
 * 常量类
 */
export class Constants {
  static readonly PREV_TEXT_DEFAULT = $r('app.string.prev_text');
  static readonly NEXT_TEXT_DEFAULT = $r('app.string.next_text');
  static readonly BTN_FG_SIZE_DEFAULT = $r('sys.float.ohos_id_text_size_button3');
  static readonly BTN_FG_COLOR_DEFAULT = $r('sys.color.ohos_id_color_text_primary');
  static readonly BTN_ICON_COLOR_DEFAULT = $r('sys.color.ohos_id_color_primary');
  static readonly BTN_BG_COLOR_DEFAULT = $r('sys.color.ohos_id_color_button_normal');
  static readonly PAGE_SIZE_DEFAULT: number = 10;
  static readonly ICON_DEFAULT_H: number = 16;
}

/**
 * 按钮类型：上一页/下一页
 */
export enum BtnType {
  /**
   * 上一页
   */
  PREV = 'prev',
  /**
   * 下一页
   */
  NEXT = 'next',
}

/**
 * 按钮选项
 */
export interface IBtnOption {
  /**
   * 上一页按钮文字
   */
  prevText?: ResourceStr;

  /**
   * 下一页按钮文字
   */
  nextText?: ResourceStr;

  /**
   * 按钮文字大小
   */
  btnFgSize?: Length;

  /**
   * 按钮文字颜色
   */
  btnFgColor?: ResourceColor;

  /**
   * 按钮图标颜色
   */
  btnIconColor?: ResourceColor;

  /**
   * 按钮背景颜色
   */
  btnBgColor?: ResourceColor;

  /**
   * 是否以icon形式展示按钮
   */
  showIcon?: boolean;

  /**
   * 按钮内部图标高度
   */
  iconH?: number;
}
