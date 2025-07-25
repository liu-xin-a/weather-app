export const ICON_MAP: Record<string, string> = {
  // 白天
  '100': '\uf101', // 晴
  '101': '\uf102', // 多云
  '102': '\uf103', // 少云
  '103': '\uf104', // 晴间多云
  '104': '\uf105', // 阴
  // 夜间
  '150': '\uf106', // 夜间晴
  '151': '\uf107', // 夜间多云
  '152': '\uf108', // 夜间少云
  '153': '\uf109', // 夜间晴间多云
  // 阵雨
  '300': '\uf10a', // 阵雨
  '301': '\uf10b', // 强阵雨
  '302': '\uf10c', // 雷阵雨
  '303': '\uf10d', // 强雷阵雨
  '304': '\uf10e', // 雷阵雨伴有冰雹
  '305': '\uf10f', // 小雨
  '306': '\uf110', // 中雨
  '307': '\uf111', // 大雨
  '308': '\uf112', // 极端降雨
  '309': '\uf113', // 毛毛雨/细雨
  '310': '\uf114', // 暴雨
  '311': '\uf115', // 大暴雨
  '312': '\uf116', // 特大暴雨
  '313': '\uf117', // 冻雨
  '314': '\uf118', // 小到中雨
  '315': '\uf119', // 中到大雨
  '316': '\uf11a', // 大到暴雨
  '317': '\uf11b', // 暴雨到大暴雨
  '318': '\uf11c', // 大暴雨到特大暴雨
  '350': '\uf11d', // 夜间阵雨
  '351': '\uf11e', // 夜间强阵雨
  '399': '\uf11f', // 雨
  // 雪
  '400': '\uf120', // 小雪
  '401': '\uf121', // 中雪
  '402': '\uf122', // 大雪
  '403': '\uf123', // 暴雪
  '404': '\uf124', // 雨夹雪
  '405': '\uf125', // 雨雪天气
  '406': '\uf126', // 阵雨夹雪
  '407': '\uf127', // 阵雪
  '408': '\uf128', // 小到中雪
  '409': '\uf129', // 中到大雪
  '410': '\uf12a', // 大到暴雪
  '456': '\uf12b', // 夜间阵雨夹雪
  '457': '\uf12c', // 夜间阵雪
  '499': '\uf12d', // 雪
  // 沙尘
  '500': '\uf12e', // 薄雾
  '501': '\uf12f', // 雾
  '502': '\uf130', // 霾
  '503': '\uf131', // 扬沙
  '504': '\uf132', // 浮尘
  '507': '\uf133', // 沙尘暴
  '508': '\uf134', // 强沙尘暴
  '509': '\uf135', // 浓雾
  '510': '\uf136', // 强浓雾
  '511': '\uf137', // 中度霾
  '512': '\uf138', // 重度霾
  '513': '\uf139', // 严重霾
  '514': '\uf13a', // 大雾
  '515': '\uf13b', // 特强浓雾
  // 特殊
  '800': '\uf13c', // 新月
  '801': '\uf13d', // 上弦月
  '802': '\uf13e', // 满月
  '803': '\uf13f', // 下弦月
  '804': '\uf140', // 蛾眉月
  '805': '\uf141', // 盈凸月
  '806': '\uf142', // 亏凸月
  '807': '\uf143', // 残月
  '900': '\uf144', // 炎热
  '901': '\uf145', // 寒冷
  '999': '\uf146', // 未知
};

/**
 * 将 YYYY-MM-DD 格式的日期字符串转换为更友好的格式
 * @param dateStr API 返回的日期字符串, e.g., "2025-07-24"
 * @returns "今天", "明天", "后天", 或 "周X"
 */
export function formatForecastDate(dateStr: string): string {
  const date = new Date(dateStr);
  const today = new Date();
  const tomorrow = new Date();
  tomorrow.setDate(today.getDate() + 1);
  const dayAfter = new Date();
  dayAfter.setDate(today.getDate() + 2);

  // 清除时间部分，只比较年月日
  today.setHours(0, 0, 0, 0);
  date.setHours(0, 0, 0, 0);
  tomorrow.setHours(0, 0, 0, 0);
  dayAfter.setHours(0, 0, 0, 0);

  if (date.getTime() === today.getTime()) {
    return '今天';
  }
  if (date.getTime() === tomorrow.getTime()) {
    return '明天';
  }
  if (date.getTime() === dayAfter.getTime()) {
    return '后天';
  }

  // 否则，返回星期几
  const week = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  return week[date.getDay()];
}

/**
 * 将一个Date对象格式化为 "HH:mm" 的字符串
 * @param date 一个Date对象
 * @returns 格式化后的时间字符串，例如 "10:07"
 */
export function formatTime(date: Date): string {
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}