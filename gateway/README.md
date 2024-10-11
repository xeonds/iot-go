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

## 流程

网关入网后，借助mDNS广播自身地址和信息以便设备和app连接。

对于设备，设备发现后自动通过网关的api注册并建立socket连接。

对于app，发现网关后更新网关ip和端口，之后通过网关的http api进行控制，状态更新等操作。

网关侧，设备入网后应该自动通过socket连接网关ip，并实时双向更新状态。具体来说事件会触发数据库更新，设备注册，上下线都会更新数据库。

当设备通电入网并知晓网关ip后应该立刻建立socket连接，网关处会根据此信息更新在线状态。

设备可以暴露http接口供其他用途，例如作为数据输出端供现有系统使用。

## 多网关逻辑

公网网关和内网网关分别记为AB。设备可以任意注册给AB网关。

AB通过socket连接通信以保证任务实时性。A可以控制自己的设备和B的设备。B连接到A后将数据库api暴露给A，A处执行的数据库逻辑为A,B并集。A执行控制任务时，遇到标注为B的，则通过ws转发控制指令到B。

## web面板:

使用ws和网关连接，数据库的数据变动实时通过socket发送给网关。