// 文件路径: entry/src/main/ets/utils/StyleProvider.ets

type GradientColors = [string, number][];

// 预设几种天气状况的颜色数组
// 关键修正：我们调整了颜色的起止点(offset)，让渐变效果更明显
const sunnyColors: GradientColors = [
  ['#4A90E2', 0.0], // 亮蓝色从顶部(0%)开始
  ['#81C7F4', 0.6]  // 天蓝色在60%的位置就已经完全过渡，剩下的40%都是天蓝色
];

const cloudyColors: GradientColors = [
  ['#7D7D7D', 0.0],
  ['#B0B0B0', 1.0] // 灰色系可以保持平滑过渡
];

const rainyColors: GradientColors = [
  ['#2C3E50', 0.0],
  ['#34495E', 1.0]
];

const nightColors: GradientColors = [
  ['#0F2027', 0.0],  // 深黑蓝从顶部(0%)开始
  ['#203A43', 0.5],  // 墨蓝在中间(50%)
  ['#2C5364', 1.0]   // 蓝灰在底部(100%)结束
];

const defaultColors = sunnyColors;

/**
 * 根据和风天气的图标代码，获取对应的颜色数组
 */
export function getWeatherGradientColors(iconCode: string): GradientColors {
  const codeNumber = parseInt(iconCode);

  if (isNaN(codeNumber)) {
    return defaultColors;
  }
  // 夜晚
  if (codeNumber >= 150 && codeNumber < 300) {
    return nightColors;
  }
  // 雨天
  if (codeNumber >= 300 && codeNumber < 400) {
    return rainyColors;
  }
  // 雪天
  if (codeNumber >= 400 && codeNumber < 500) {
    return cloudyColors;
  }
  // 阴天/多云
  if ([101, 102, 103, 104].includes(codeNumber)) {
    return cloudyColors;
  }
  // 默认返回晴天
  return defaultColors;
}

/**
 * 根据天气图标代码，获取一个适合搭配的、半透明的图标背景色
 * @param iconCode 从API获取的图标代码
 * @returns 表示颜色的字符串, e.g., "#FFFFFF33"
 */
export function getIconBackgroundColor(iconCode: string): string {
  const codeNumber = parseInt(iconCode);

  if (isNaN(codeNumber)) {
    return '#FFFFFF33'; // 默认半透明白色
  }

  // 夜晚
  if (codeNumber >= 150 && codeNumber < 300) {
    return '#FFFFFF1A'; // 夜晚使用更透明的白色
  }

  // 雨天/雪天/阴天
  if (codeNumber >= 101 && codeNumber < 500) {
    return '#FFFFFF2B'; // 阴雨天使用稍不透明的白色
  }

  // 默认（晴天）
  return '#FFFFFF33';
}