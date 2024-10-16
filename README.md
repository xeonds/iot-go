# go-iot

The infrastructure of IoT for LAN and WAN.

## 项目结构

### client

控制器，用于连接服务器，接收服务器的指令，控制设备。优先连接公网网关，当公网网关不可用时，连接本地网关。

### gateway

本地网关，用于本地控制设备，在远程服务器不可用时，本地网关可以继续工作。功能上与服务器相同，但是不需要连接到公网。

系统由用户（app）设备（物联网终端）和网关组成。其中网关分为两级，一个是内网网关，另一个是公网网关。用户使用app向网关查询设备状态/控制设备开关，设备定时向网关上报自身状态，并取走并执行数据库中对应自己的指令并执行，同时上报更新自身状态。网关检测数据库中设备在线状态，若设备长时间未上报状态，则更新设备状态为离线。两套网关系统互为冗余，如果物联网设备发现内网存在合法网关则以它为服务器，由这个网关和公网网关同步状态。内网网关可以直接调用设备的api即时执行指令和同步状态。公网则只能通过轮询来定期上报状态并执行指令。用户的app可以配置网关和设备。配置设备时，指定要接入的网络和合法的网关密钥，以及公网服务器的ip/域名，设备就能自行接入局域网并：优先注册内网网关，若未发现内网网关则在用户给出的公网网关进行注册。配置网关时，步骤和配置设备基本相同。公网网关可以不配置，这样这就是一个纯本地的物联网网络。如果网关被配置了公网网关url,则会给内网设备都同步添加上公网网关的url。

用户的app控制设备时，如果和网关在同一局域网中，则直接借助网关在局域网内实时控制设备。如果app在公网中，则通过公网设备进行远程控制。

## 解决的问题

主要有两个。

一个是设备的配网问题。提供了一组基于自动发现的方式来完成配网的流程，以及一个可用性较高的网络架构设计，从而保证整个网络的任务执行顺畅及时。

另一个问题是自动化任务编排的问题，提供了一个基于dsl的编排语言，以及对应的多元组形式的任务配置方式，提升了自动化编排的描述力，灵活性和简易性。

## LICENSE

GNU General Public License V3
