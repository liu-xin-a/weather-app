
import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

// 为我们的缓存数据定义一个统一的“包装盒”结构
// T 是一个泛型，代表我们可以缓存任何类型的数据（如 NowWeatherData, DailyForecast[] 等）
interface WeatherCache<T> {
  data: T;          // 缓存的数据本身
  timestamp: number; // 存入时的时间戳 (毫秒)
}

const PREF_FILE_NAME = 'weather_cache'; // 专门为缓存创建一个独立的文件
// 获取 preferences 实例的辅助函数
async function getCachePreferences(context: common.Context): Promise<preferences.Preferences> {
  return await preferences.getPreferences(context, PREF_FILE_NAME);
}

/**
 * 工具函数一：将天气数据存入缓存
 * @param context 上下文
 * @param key 缓存的键名 (e.g., 'now_weather', 'hourly_forecast')
 * @param data 要缓存的天气数据
 */
export async function saveWeatherCache<T>(context: common.Context, key: string, data: T) {
  try {
    const prefs = await getCachePreferences(context);
    // 1. 创建一个包含数据和当前时间戳的“包装盒”
    const cacheObject: WeatherCache<T> = {
      data: data,
      timestamp: Date.now() // 获取当前时间的毫秒数
    };
    // 2. 将整个“包装盒”转换成JSON字符串
    const cacheString = JSON.stringify(cacheObject);
    // 3. 存入 preferences
    await prefs.put(key, cacheString);
    await prefs.flush();
    console.info(`[Cache] 成功将数据存入缓存，键名: ${key}`);
  } catch (e) {
    console.error(`[Cache] 保存缓存失败，键名: ${key}`, JSON.stringify(e));
  }
}

/**
 * 工具函数二：从缓存中读取天气数据
 * @param context 上下文
 * @param key 缓存的键名
 * @returns 返回一个包含数据和时间戳的“包装盒”，如果找不到或出错则返回 null
 */
export async function loadWeatherCache<T>(context: common.Context, key: string): Promise<WeatherCache<T> | null> {
  try {
    const prefs = await getCachePreferences(context);
    const cacheString = await prefs.get(key, '') as string;
    if (cacheString) {
      const cacheObject = JSON.parse(cacheString) as WeatherCache<T>;
      console.info(`[Cache] 成功从缓存中加载数据，键名: ${key}`);
      return cacheObject;
    }
  } catch (e) {
    console.error(`[Cache] 加载缓存失败，键名: ${key}`, JSON.stringify(e));
  }
  return null;
}