import { TeamData, http_teams } from '../http_server/httpService';

@Component
export struct team_search {
  @State team_list_array: Array<TeamData> = [];
  @State search: string = ''
  @Consume('Full_screen') Full_screen: NavPathStack;
  @StorageLink('team_code') team_code: string = '';

  async http_team_search(search: string) {
    try {
      this.team_list_array = [];
      const response = await http_teams.httpRequest(20, '', '', search);
      this.team_list_array = response
    } catch (error) {
      console.error('Error occurred during request:', error);
    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Image($r('app.media.ic_search'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .margin({ left: 11 })

          TextInput({ placeholder: '搜索队伍或队伍代码' })
            .width('70%')
            .fontSize(16)
            .lineHeight(21)
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ left: 6 })
            .backgroundColor('#ffe5e5ea')
            .onChange((search: string) => {
              this.search = search;
            });
          Button('搜索', { type: ButtonType.Capsule, stateEffect: true })
            .onClick(() => {
              AlertDialog.show(
                {
                  message: '请选择搜索方法',
                  primaryButton: {
                    value: '队名搜索',
                    action: () => {
                      this.http_team_search(this.search);
                    }
                  },
                  secondaryButton: {
                    value: '队伍代码搜索',
                    action: () => {
                      this.Full_screen.pushPath({ name: 'team_info' })
                      this.team_code = this.search
                    }
                  }
                }
              )
            })
        }
        .borderRadius(20)
        .backgroundColor('#ffe5e5ea')
        .height(40)
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      List({ space: 20 }) {
        ForEach(this.team_list_array, (item: TeamData) => {
          ListItem() {
            Column() {
              Text(item.team_name)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
              Row() {
                Text('已参加人数：')
                Text(String(item.joined_count) + '/' + String(item.team_size))
              }
            }
            .width('90%')
            .alignItems(HorizontalAlign.Start)
          }
          .onClick(() => {
            this.Full_screen.pushPath({ name: 'team_info' })
            this.team_code = item.team_code
          })
        })
      }
    }
    .backgroundColor('#fff1f3f5')
    .width('90%')
  }
}