import { CityLocation, CityLookupApiResponse, CurrentCityInfo } from "../model/WeatherModels";
import { promptAction } from "@kit.ArkUI";
import { http } from "@kit.NetworkKit";
import { QWEATHER_CITY_LOOKUP_URL } from "../common/Constants";
import { QWEATHER_API_KEY } from "../common/Constants";


@Builder
export function CitySearchPageBuilder(){
  CitySearchPage();
}
@Component
struct CitySearchPage {

  pathStack: NavPathStack = new NavPathStack();
  @State searchText:string = '';
  @State  searchResults: CityLocation[] = [];
  @State isLoading: boolean = false; // 用于未来显示“加载中...”的状态
  /**
   * 核心函数一：执行城市搜索
   */
  async searchCity() {
    if (!this.searchText) {
      promptAction.openToast({
        message:'请输入城市名称',
        duration:2000
      })
      return;
    }
    this.isLoading = true;
    this.searchResults = []; // 每次搜索前清空上次的结果

    let httpRequest = http.createHttp();
    // 使用 encodeURIComponent 对用户输入进行编码，防止中文或特殊字符出错
    // const url = `${QWEATHER_CITY_LOOKUP_URL}?location=${encodeURIComponent(this.searchText)}&key=${QWEATHER_API_KEY}`;
    const url = `${QWEATHER_CITY_LOOKUP_URL}?location=${this.searchText}&key=${QWEATHER_API_KEY}`;

    try {
      const response = await httpRequest.request(url);
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as CityLookupApiResponse;
        if (result.code === '200') {
          this.searchResults = result.location; // 更新搜索结果列表
          if (this.searchResults.length === 0) {
            promptAction.openToast({
              message:'未找到相关城市',
              duration:2000
            })
          }

        }
      }
    } catch (err) {
      console.error("Search city error: ", err);
      promptAction.openToast({
        message:'搜索失败，请检查网络',
        duration:2000
      })
    } finally {
      this.isLoading = false; // 隐藏加载状态
      httpRequest.destroy();
    }
  }
  /**
   * 核心函数二：选择一个城市并返回
   * @param city 用户点击的城市对象
   */
  selectCity(city: CityLocation) {
    // 准备要写入“全局公告板”的数据
    const newCity: CurrentCityInfo = { id: city.id, name: city.name };
    // 使用 AppStorage.Set 将新城市信息写入“全局公告板”
    // 主页的 @StorageLink 会自动监听到这个变化
   AppStorage.set<CurrentCityInfo>('currentcity',newCity)
    // 命令导航栈：返回上一页
    this.pathStack.pop();
  }
  build() {
    NavDestination() {
      Column(){
        Row({space:10}){
          TextInput({
            placeholder:'请输入名称',
            text:$$this.searchText
          })
            .layoutWeight(1)
            .onSubmit(()=>{
              this.searchCity();
            })
          Button('搜索')
            .onClick(()=>{
              this.searchCity();
            })
        }
        .justifyContent(FlexAlign.SpaceAround)
        .width('100%')
        List({space:10}){
          ForEach(this.searchResults,(item:CityLocation)=>{
            ListItem(){
              Column() {
                Text(item.name).fontSize(18).fontWeight(FontWeight.Medium)
                Text(`${item.adm2}, ${item.adm1}`) // 例如 "朝阳区, 北京市"
                  .fontSize(14)
                  .fontColor(Color.Gray)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .padding({ top: 12, bottom: 12, left: 10, right: 10 })
              .width('100%')
            }
            .onClick(()=>{
              this.selectCity(item)
            })
          })
        }
        .layoutWeight(1)
      }
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}