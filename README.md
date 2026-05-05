# 🎰 Pachinko

2D 柏青哥（パチンコ）弹珠机游戏 Demo，使用 Godot 4.6 开发。

## ✨ 特性

- **3 种版面** — Classic / Fortune / Storm，各有独特的钉阵布局与奖杯配置
- **物理模拟** — 真实弹珠弹跳、摩擦与重力
- **チューリップ机关** — 经典柏青哥开合花瓣装置
- **老虎机 & 大奖** — 集齐符号触发 Jackpot
- **粒子特效 & 屏幕震动** — 命中反馈与视觉表现
- **主菜单 & 关于页** — 含 Matrix Rain 终端风格动画
- **触屏支持** — 底部按钮栏可触控发射与切换版面
- **PWA 支持** — 可安装为离线应用

## 🎮 在线试玩

[https://xkweimeng.github.io/Pachinko/](https://xkweimeng.github.io/Pachinko/)

## 🛠️ 本地运行

1. 安装 [Godot 4.6](https://godotengine.org/download)
2. 克隆仓库：`git clone https://github.com/xkWeiMeng/Pachinko.git`
3. 用 Godot 打开 `project.godot`
4. 按 F5 运行

## 📁 项目结构

```
scenes/       # 场景文件
scripts/      # GDScript 脚本
autoloads/    # 全局单例（EventBus / GameState / AudioManager）
resources/    # 资源文件
shaders/      # 着色器
```

## 📄 License

[MIT](LICENSE) © XieKang
