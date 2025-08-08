// WeatherWidgetAbility.ets

import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { http } from '@kit.NetworkKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CurrentCityInfo, NowWeatherData, WeatherApiResponse } from '../model/WeatherModels';
import { loadCityFromPreferences } from '../utils/PreferencesUtil';
import { QWEATHER_API_KEY, QWEATHER_NOW_URL } from '../common/Constants';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = "WIDGET_DEBUG";
// 2. 定义一个和UI侧完全一致的“接头暗号”
const STORAGE_FILE_NAME = 'WeatherWidgetStore';
class FormData {
  city: string = '北京'; // 和卡片布局中对应
  text: string = '。。。'; // 和卡片布局中对应
  temp:string = '0';
  iconCode: string = '999';
}
let formData = new FormData();
export default class WeatherWidgetAbility extends FormExtensionAbility {
  // onAddForm 现在只负责触发一次初始数据加载
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(0x0000, TAG, 'onAddForm: 卡片被创建。');
    const formId = want.parameters?.["ohos.extra.param.key.form_identity"] as string;
    if (formId) {
      this.fetchDataAndUpdateStorage(formId, 'onAddForm');
    }
    return formBindingData.createFormBindingData();
  }

  // onUpdateForm 负责定时刷新
  onUpdateForm(formId: string): void {
    hilog.info(0x0000, TAG, `onUpdateForm: 卡片定时刷新被触发`);
    this.fetchDataAndUpdateStorage(formId, 'onUpdateForm');
  }

  // onFormEvent 负责响应UI点击
  onFormEvent(formId: string, message: string): void {
    hilog.info(0x0000, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);
    this.fetchDataAndUpdateStorage(formId,message)
  }

  // 核心函数：获取数据并更新 Storage
  async fetchDataAndUpdateStorage(formId: string, trigger: string): Promise<void> {
    hilog.info(0x0000, TAG, `由 [${trigger}] 触发, 开始获取数据并更新Storage。`);
    try {
      let cityInfo = await loadCityFromPreferences(this.context);
      if (!cityInfo) {
        cityInfo = { id: '101010100', name: '北京' };
      }

      const nowWeather = await this.getNowWeather(cityInfo.id);

      if (nowWeather) {
        const storage = await preferences.getPreferences(this.context, STORAGE_FILE_NAME);

        hilog.info(0x0000, TAG, `获取到天气数据，准备写入Storage: city=${cityInfo.name}`);

        // await storage.put('city', cityInfo.name);
        // await storage.put('temp', nowWeather.temp);
        // await storage.put('text', nowWeather.text);
        // await storage.put('iconCode', nowWeather.icon);
        // await storage.flush();
        formData = {
          city:cityInfo.name,
          text:nowWeather.text,
          temp:nowWeather.temp,
          iconCode:nowWeather.icon,
        }
        hilog.info(0x0000, TAG, '成功写入Storage并flush。');

        // ✅ 关键：更新卡片，触发 UI 读取 LocalStorage 的变更
        let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
        formProvider.updateForm(formId, formInfo).then(() => {
          hilog.info(0x0000, TAG, 'FormAbility updateForm success.');
        }).catch((error: BusinessError) => {
          hilog.info(0x0000, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
        })
        hilog.info(0x0000, TAG, 'formProvider.updateForm success.');

      } else {
        throw new Error('获取天气数据失败');
      }
    } catch (e) {
      hilog.error(0x0000, TAG, `fetchDataAndUpdateStorage 捕获到异常: ${e.message}`);
    }
  }


  /**
   * 网络请求函数：获取实时天气
   * @param cityId
   * @returns NowWeatherData or null
   */
  async getNowWeather(cityId: string): Promise<NowWeatherData | null> {
    const url = `${QWEATHER_NOW_URL}?location=${cityId}&key=${QWEATHER_API_KEY}`;
    hilog.info(0x0000, TAG, `getNowWeather: 准备发起网络请求, URL: ${url}`);
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url, { method: http.RequestMethod.GET });
      hilog.info(0x0000, TAG, `getNowWeather: 网络请求完成, HTTP Code: ${response.responseCode}`);

      if (response.responseCode === 200 && response.result) {
        const result = JSON.parse(response.result as string) as WeatherApiResponse;
        hilog.info(0x0000, TAG, `getNowWeather: JSON解析完成, API Code: ${result.code}`);
        if (result.code === '200' && result.now) {
          return result.now;
        }
      }
    } catch (e) {
      hilog.error(0x0000, TAG, `getNowWeather: 网络请求捕获到异常！Error: ${e.message}`);
    } finally {
      // 确保httpRequest被销毁
      httpRequest.destroy();
    }
    return null;
  }
}