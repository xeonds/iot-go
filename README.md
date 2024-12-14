# IoT-Go

The infrastructure of scalable IoT system for LAN and WAN.

## solved problems

The one is client's network auto configuration. App can help config most types of clients. And the network structure makes the system available at most times.

Another is automation. The system provides a dsl parser, which is used to describe control commands, and task compose, makes it more powerful to compose automation tasks.

## project structure

This system is consisted with app, clients and gateways. It works like this:

- Users use app to send/receive data from gateway, then the gateway relays the command to the actual client, which controls the real hardware.
- Users setup automation rules in app, which stores in the gateway. Gateway runs automation scripts when being triggered, which send commands to clients/do other stuffs.

And in this system, in order to make it more scalable, the gateway can be configured to cascade mode: **When you add a url which points to a parent gateway, it will create a websocket connection to parent gateway and listen for commands from the parent gateway. And when parent gateway receives a command from app/automation, it will also relays the command to connected sub-gateways using websocket. The result of the command's execution is the sum of both parent gateway and the sub-gateway.**

Assume that `A` is the parent gateway of `B`, expected effect is, when you run command in A, the gateway B will also receive your command. This solves such problem: if your device is registered under B, but you are not in B's LAN, and in this case, if your B is connected to public gateway A, then you can use A to relay command to B, and control your device in B's LAN.

### client

This is controller, it controls the things, and receive commands from gateway/send commands to server.

### gateway

LAN gateway, used to receive commands from app/another gateway, and controls devices that has been connected to itself.

The gateway also can run automation tasks to control devices.

### app

User can use app to interact with gateway(the LAN gateway or the public gateway), and can access device and register them to the target gateway using WiFi, Bluetooth, GPIO, USB, or ZigBee or other protocols.

### IoTLang

名字没想好，东西本身是作为物联网设备之间通讯协议/任务编排用的。

用途：

- 一定程度的描述能力，可以表述函数原型程度的表达力
- 支持控制流编排，便于制定计划任务

目前用正则大概写了一个：

```
type.key[count]:value->ret_type;
```

type和key都是描述指令类型的部分，count是可选的描述指令参数范围的部分，value是指令的参数，ret_type应该被用来描述指令的返回值类型

要求：

- 解释器比较好编写：最好不涉及带有递归结构的二型文法，就算有，也得有一个好编写解释器的三型文法子集专门用作网关和IoT设备的指令传递

现在大概设计是三型文法完全的控制指令子集+二型文法可描述的指令编排语言。这部分需要实现一个dsl解释器和对应的运行库。

目前打算用OCaml写解释器部分，然后在网关处用go实现运行库来解释运行自动化任务。语言之间的通信用链接器解决，或者先用管道的松耦合方法调用。

> 2024.12.14更新：IotLang的核心是值变换，以及值的引用。类型描述了指令对于值是否有副作用，key指示了指令作用的对象的引用，count指示了被引用变量的编号，value则是状态变化的具体量。因此，返回值并不需要，因为语句本身已经约定了在当前状态下，状态的变化将是什么结果。
> `type.key[count]:value;`
> 所以，也不需要什么返回值了。对于别的部分，例如图像/音频传输，这不应该由IotLang来处理，应该在其他端口使用别的协议来传输，这么设计同时也保证了控制流不会被数据传输流影响。
> 比如对于一个推送视频流的硬件，可以在固件的代码中用IotLang规定好控制类指令，以及一条用于约定传输图像流使用的端口、协议的指令，这样当控制端app连接到网关，获取到IotLang定义的设备的信息，就可以知道如何控制设备，以及如何获取设备的数据。
> 对于状态获取，也可以在IotLang中定义一个指令，用于获取设备的状态，这样app就可以通过网关获取设备的状态，而不需要直接连接到设备。

---

## TODO

- 添加数据表，待执行指令和指令执行历史
- 设备执行指令后，返回指令执行状况
- 网关检测数据库中设备在线状态，心跳检测，设置不在线设备状态为-1
- 内网设备自动发现并连接局域网网关
- 配置设备时，指定要接入的网络和**合法的网关密钥**，以及公网服务器的ip/域名
- 设备优先注册内网网关，若未发现内网网关则在用户给出的公网网关进行注册
- 设备侧的公网网关可以不配置，（先mdns发现网关，失败则使用配置的网关）这样这就是一个纯本地的物联网网络。
- 用户的app控制设备时，如果和网关在同一局域网中，则直接借助网关在局域网内实时控制设备。如果app在公网中，则通过公网设备进行远程控制。
- 自动化
    - app侧接入网关api，获取/添加/编辑/删除/启用/禁用自动化任务
    - 网关侧接入数据库，线程启动时添加事件触发器通道，在数据库操作/时间变化中向通道发送事件，触发器接收到事件后执行对应的自动化任务
        - 暂时不支持完整的iot-lang，只支持`;`分隔的具体指令序列，不涉及变量、函数、控制流等

## LICENSE

GNU General Public License V3
