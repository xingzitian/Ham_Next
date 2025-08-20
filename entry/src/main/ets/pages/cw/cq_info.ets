import {
  cw,morseCodeTable,
  q_phrases,q,
  phoneticAlphabet,phonetic
} from './base_resource'


@Component
export struct base_info_1 {
  @Consume('index') index: NavPathStack;
  @State morseCodeTable:Array<cw> = morseCodeTable
  build() {
    NavDestination() {
      List({ space: 10 }){
        ForEach(this.morseCodeTable,(item:cw)=>{
          ListItem(){
            Text(item.字符+'  '+item.电码)

              .borderRadius(15)
              .backgroundColor('#ffffffff')
              .width('100%')
              .height(50)
              .fontSize(20)
          }

        })
      }
      .width("90%")

    }

    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('字母解释法')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}

@Component
export struct base_info_2 {
  @Consume('index') index: NavPathStack;
  @State q_phrases:Array<q> = q_phrases
  build() {
    NavDestination() {
      List({ space: 10 }){
        ForEach(this.q_phrases,(item:q)=>{
          ListItem(){
            Text(item.Q简语+'  '+item.含义)

              .borderRadius(15)
              .backgroundColor('#ffffffff')
              .width('100%')
              .height(50)
              .fontSize(20)
          }
        })
      }
      .width("90%")
    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('常用 Q 简语')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}

@Component
export struct base_info_3 {
  @Consume('index') index: NavPathStack;
  @State phoneticAlphabet:Array<phonetic> = phoneticAlphabet
  build() {
    NavDestination() {
      List({ space: 10 }){
        ForEach(this.phoneticAlphabet,(item:phonetic)=>{
          ListItem(){
            Text(item.letter+'  '+item.phonetic)

              .borderRadius(15)
              .backgroundColor('#ffffffff')
              .width('100%')
              .height(50)
              .fontSize(20)
          }
        })
      }
      .width("90%")
    }
    .backgroundColor($r('sys.color.container_modal_unfocus_background'))
    .title('常用 Q 简语')
    .onBackPressed(() => {
      this.index.pop() // 弹出路由栈栈顶元素
      return true
    })
  }
}
