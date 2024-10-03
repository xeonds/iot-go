# go-iot

The infrastructure of IoT for LAN and WAN.

## 项目结构

### client

控制器，用于连接服务器，接收服务器的指令，控制设备。优先连接公网网关，当公网网关不可用时，连接本地网关。

### gateway

本地网关，用于本地控制设备，在远程服务器不可用时，本地网关可以继续工作。功能上与服务器相同，但是不需要连接到公网。

### server

服务器，用于接收客户端的连接，发送指令给客户端，接收客户端的数据。

## LICENSE

GNU General Public License V3