# Gateway

## Functions

- LAN devices registration/unregistration
- LAN devices status monitoring
- LAN devices control
- LAN devices event notification
- Automation for LAN devices
- Multilevel structure gateway

## 多级网关

当公网网关不可用时，自动切换到局域网网关，局域网网关不可用时，自动切换到局域网内的子网网关。

实现思路：下级网关通过心跳包检测上级网关，当上级网关不可用时，下级网关自动接管上级网关的功能。

## 事件通知

当设备状态发生变化时，通过事件通知机制通知用户。

当用户发送控制指令时，通过事件通知机制通知设备。

## TODO

对api请求的反馈