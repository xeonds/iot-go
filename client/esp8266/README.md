- init.ino WiFi AP模式配网&MQTT客户端实现
- main.ino 基于上述IoT框架的智能灯控制

makefile

- pull-up: 通过wifi控制引脚输出高电平
- pull-down: 通过wifi控制引脚输出低电平
- get-status: 通过wifi获得当前引脚状态
- serial: 连接串口调试

## todo

- 服务端重连:无需重启自动持续重联服务端ip
- wifi重联：只有按下复位按键5s之后才清空服务端ip
- 按键
    - 点击切换亮度0-255, step 64
    - 长按5s重新配网


## 流程

有wifi配置则直接连接，连接失败则进入主循环，接受按键控制。在主循环中，长按5s进入配网模式，短按则切换亮度，若websocket连接失败则不断尝试重连。
