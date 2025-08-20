

@Component
export struct user_team_list {
  @State team_list_array: Array<TeamData> = [];
  @Consume('Full_screen') Full_screen: NavPathStack;
  @StorageLink('team_code') team_code: string = '';
  @StorageProp('token') token: string = ''
  @StorageProp('username') username: string = '';
  tool: NavigationMenuItem = {
    'value': "", 'icon': "resources/base/media/plus.svg", 'action': () => {
      this.Full_screen.pushPath({ name: 'add_team' })
    }
  }

  aboutToAppear(): void {
    this.http_get_user_team(this.token);
  }

  async http_get_user_team(token: string) {
    try {
      const response = await http_teams.httpRequest(11, '', token);
      this.team_list_array = response;
    } catch (error) {
      console.error('Error occurred during request:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        Tabs() {
          TabContent() {
            Column() {
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
              .height('100%')
            }
          }
          .tabBar("我加入的队伍")

          TabContent() {
            Column() {
              List({ space: 20 }) {
                ForEach(this.team_list_array, (item: TeamData) => {
                  if (item.creator_name === this.username) {
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
                  }

                })
              }
              .height('100%')
            }
          }
          .tabBar("我管理的队伍")
        }
        .width('90%')
      }
    }
    .title("已经加入的队伍")
    .menus([this.tool])
    .backgroundColor('#fff1f3f5')
  }
}

@Component
export struct admin_team_list {
  @State team_list_array: Array<TeamData> = [];
  @Consume('Full_screen') Full_screen: NavPathStack;
  @StorageLink('team_code') team_code: string = '';
  @StorageProp('token') token: string = ''
  @StorageProp('username') username: string = '';

  aboutToAppear(): void {
    console.log("admin-info")
    this.http_get_user_team(this.token);
  }

  async http_get_user_team(token: string) {
    try {
      const response = await http_admin_teams_get.httpRequest(token);
      this.team_list_array = response;
    } catch (error) {
      console.error('Error occurred during request:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        Tabs() {
          TabContent() {
            Column() {
              List({ space: 20 }) {
                ForEach(this.team_list_array, (item: TeamData) => {
                  ListItem() {
                    Column() {
                      Text(item.team_name)
                        .fontSize(22)
                        .fontWeight(FontWeight.Bold)
                        .textAlign(TextAlign.Start)
                      Row() {
                        Text('创建者：')
                        Text(String(item.creator_name))
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
              .height('100%')
            }
          }
          .tabBar("待审核的队伍")
        }
        .width('90%')
      }
    }
    .title("待审核的队伍")
    .backgroundColor('#fff1f3f5')
  }
}