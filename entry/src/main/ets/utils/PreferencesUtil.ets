// 文件路径: entry/src/main/ets/utils/PreferencesUtil.ets

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CurrentCityInfo } from '../model/WeatherModels';

const PREF_FILE_NAME = 'weather_settings'; // 定义存储文件的名字
const PREF_KEY_CITY_INFO = 'current_city_info'; // 定义存储城市信息的键名

/**
 * 获取一个专属于本应用的 preferences 实例
 */
async function getPreferences(context: common.UIAbilityContext): Promise<preferences.Preferences> {
  return await preferences.getPreferences(context, PREF_FILE_NAME);
}

/**
 * 工具函数一：将用户选择的城市信息保存到闪存
 */
export async function saveCityToPreferences(context: common.UIAbilityContext, city: CurrentCityInfo) {
  try {
    const prefs = await getPreferences(context);
    // 因为 preferences 只能存字符串等基础类型，所以我们必须先把对象转换成JSON字符串
    const cityJsonString = JSON.stringify(city);
    await prefs.put(PREF_KEY_CITY_INFO, cityJsonString);
    await prefs.flush(); // 确保数据立刻写入磁盘
    console.info("城市信息已成功保存到持久化存储。");
  } catch (e) {
    console.error("保存城市信息失败", e);
  }
}

/**
 * 工具函数二：从闪存中读取上次保存的城市信息
 */
export async function loadCityFromPreferences(context: common.UIAbilityContext): Promise<CurrentCityInfo | null> {
  try {
    const prefs = await getPreferences(context);
    // 读取时，也要先以字符串的形式读出来
    const cityJsonString = await prefs.get(PREF_KEY_CITY_INFO, '') as string;
    if (cityJsonString) {
      // 如果字符串不为空，再把它解析回我们需要的 CurrentCityInfo 对象
      const cityInfo = JSON.parse(cityJsonString) as CurrentCityInfo;
      console.info("成功从持久化存储中加载了城市信息:", JSON.stringify(cityInfo));
      return cityInfo;
    }
  } catch (e) {
    console.error("加载城市信息失败", e);
  }
  // 如果遇到任何错误或没有找到数据，都返回 null
  return null;
}