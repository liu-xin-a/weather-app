
export interface WeatherApiResponse {
  code: string;
  updateTime: string;
  fxLink: string;
  now: NowWeatherData; // 引用我们之前定义的 NowWeatherData
}

// 定义“实时天气”的数据结构，对应 JSON 中的 "now" 对象
export interface NowWeatherData {
  temp: string;       // 当前温度
  feelsLike: string;  // 体感温度
  text: string;       // 天气状况的文字描述，例如“多云”
  icon: string;       // 天气状况的图标代码，需要用它来匹配你的图标字体
  windDir: string;    // 风向
  windScale: string;  // 风力等级
  humidity: string;   // 相对湿度
  pressure: string;   // 大气压强
  vis: string;        // 能见度，单位是公里
}

// 定义一个“空”的初始数据，用于在网络请求回来前占位
export const initialNowWeatherData: NowWeatherData = {
  temp: '--',
  feelsLike: '--',
  text: '加载中...',
  icon: '999', // 和风天气图标代码'999'代表“未知”
  windDir: 'N/A',
  windScale: 'N/A',
  humidity: '--',
  pressure: '--',
  vis: '--'
};

// 定义“单日预报”的数据结构，对应 daily 数组中的一个元素
export interface DailyForecast {
  fxDate: string;   // 预报日期
  tempMax: string;  // 最高温度
  tempMin: string;  // 最低温度
  iconDay: string;  // 白天天气图标代码
  textDay: string;  // 白天天气文字描述
}

// 定义“n天预报 API”的完整响应结构
export interface ForecastApiResponse {
  code: string;
  daily: DailyForecast[]; // 核心数据是一个 DailyForecast 类型的数组
}

// 定义单个城市位置的数据结构
export interface CityLocation {
  name: string; // 地区/城市名称
  id: string;   // 地区/城市ID
  adm1: string; // 该地区/城市的上级行政区划，例如“北京市”
  adm2: string; // 该地区/城市的上级行政区划，例如“朝阳区”
}

// 定义城市搜索 API 的完整响应结构
export interface CityLookupApiResponse {
  code: string;
  location: CityLocation[]; // 核心数据是一个 CityLocation 类型的数组
}

export interface CurrentCityInfo{
  id:string,
  name:string
}