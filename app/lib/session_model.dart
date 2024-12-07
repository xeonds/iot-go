import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IotLang {
  final String key;
  final String? subKey;
  final int? index;
  final String? modifier;

  IotLang({
    required this.key,
    this.subKey,
    this.index,
    this.modifier,
  });

  factory IotLang.fromMatch(RegExpMatch match) {
    return IotLang(
      key: match.group(1)!,
      subKey: match.group(2),
      index: match.group(3) != null ? int.parse(match.group(3)!) : null,
      modifier: match.group(4),
    );
  }
}

IotLang? parseExpression(String expr) {
  final RegExp re = RegExp(r'^(\w+)(?:\.(\w+))?(?:\[(\d+)\])?(?::(.+))?$');
  final match = re.firstMatch(expr);
  if (match != null) {
    return IotLang.fromMatch(match);
  }
  return null;
}

class Device {
  final String id;
  String name;
  String status;
  String cmds;

  Device({
    required this.id,
    required this.name,
    required this.status,
    required this.cmds,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      cmds: json['cmds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'cmds': cmds,
    };
  }
}

class Rule {
  final List<Task> tasks;
  final bool isManual;
  final DateTime? dateTime;
  final String repeat;
  final List<Condition> conditions;
  bool isEnabled;

  Rule({
    required this.tasks,
    required this.isManual,
    this.dateTime,
    required this.repeat,
    required this.conditions,
    required this.isEnabled,
  });
}

class Condition {
  final String item;
  final String comparator;
  final String value;

  Condition({
    required this.item,
    required this.comparator,
    required this.value,
  });
}

class Task {
  final String id;
  final List<String> commands;

  Task({
    required this.id,
    required this.commands,
  });
}

class SessionModel extends ChangeNotifier {
  List<Device> devices = [];
  List<Rule> rules = [];
  String? gatewayIp;
  bool isLoading = false;
  int? gatewayPort;
  SharedPreferences prefs;

  SessionModel(this.prefs) {
    loadConfig();
    if (gatewayIp == null && gatewayPort == null) {
      //   fetchDevices();
      // } else {
      discoverGateway();
    }
    notifyListeners();
  }

  void loadConfig() {
    gatewayIp = prefs.getString('gatewayIp');
    gatewayPort = prefs.getInt('gatewayPort');
    String? devicesJson = prefs.getString('devices');
    if (devicesJson != null) {
      List<dynamic> deviceList = json.decode(devicesJson);
      devices = deviceList.map((json) => Device.fromJson(json)).toList();
    }
    notifyListeners();
  }

  void saveConfig() async {
    if (gatewayIp != null) {
      await prefs.setString('gatewayIp', gatewayIp!);
    }
    if (gatewayPort != null) {
      await prefs.setInt('gatewayPort', gatewayPort!);
    }
    String devicesJson =
        json.encode(devices.map((device) => device.toJson()).toList());
    await prefs.setString('devices', devicesJson);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    saveConfig();
  }

  // 发现网关
  void discoverGateway() async {
    final MDnsClient client = MDnsClient();
    await client.start();

    bool gatewayFound = false;

    // 查找 "_iot-gateway._tcp" 服务
    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_iot-gateway._tcp'))) {
      if (gatewayFound) break;
      await for (final SrvResourceRecord srv
          in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName))) {
        if (gatewayFound) break;
        await for (final IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target))) {
          if (!gatewayFound) {
            gatewayIp = ip.address.address;
            gatewayPort = srv.port;
            notifyListeners();
            await fetchDevices(); // 找到网关后立即获取设备
            gatewayFound = true;
          }
        }
      }
    }
    client.stop();
  }

  // 获取设备列表
  Future<void> fetchDevices() async {
    if (gatewayIp == null) return;
    isLoading = true;
    try {
      final response = await http
          .get(Uri.parse('http://$gatewayIp:$gatewayPort/api/devices'));
      if (response.statusCode == 200) {
        List<dynamic> deviceJson = json.decode(response.body);
        devices = deviceJson.map((json) => Device.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load devices');
      }
    } catch (e) {
      print('Error fetching devices: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 控制设备状态
  Future<void> controlDevice(String id, String action) async {
    if (gatewayIp == null) return;
    try {
      final response = await http.post(
          Uri.parse('http://$gatewayIp:$gatewayPort/api/control/$id/$action'));
      if (response.statusCode == 200) {
        print('Device $id action $action successful');
        /**
         * TODO: update iot-lang to support: 
         * modifier: expr which describe how to modify the status
         *     with this, directly update the status of the device without 
         *     the need to fetch the status
         * tag: string which describe the command
         */

        final parsed = parseExpression(action);
        if (parsed != null) {
          final data = parsed.modifier != null
              ? parsed.modifier!
              : devices.firstWhere((device) => device.id == id).status;
          devices.firstWhere((device) => device.id == id).status = data;
        }
      }
    } catch (e) {
      print('Error controlling device: $e');
    } finally {
      notifyListeners();
    }
  }

  // 注销设备
  Future<void> unregisterDevice(String id) async {
    if (gatewayIp == null) return;
    try {
      final response = await http
          .post(Uri.parse('http://$gatewayIp:$gatewayPort/api/unregister/$id'));
      if (response.statusCode == 200) {
        print('Device $id unregistered successfully');
        devices.removeWhere((device) => device.id == id);
      } else {
        throw Exception('Failed to unregister device');
      }
    } catch (e) {
      print('Error unregistering device: $e');
    } finally {
      notifyListeners();
    }
  }

  void renameDevice(String id, String name) async {
    if (gatewayIp == null) return;
    try {
      final response = await http.post(
          Uri.parse('http://$gatewayIp:$gatewayPort/api/rename/$id/$name'));
      if (response.statusCode == 200) {
        print('Device $id renamed to $name');
        devices.firstWhere((device) => device.id == id).name = name;
      } else {
        throw Exception('Failed to rename device');
      }
    } catch (e) {
      print('Error renaming device: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchRules() async {
    if (gatewayIp == null) return;
    try {
      final response =
          await http.get(Uri.parse('http://$gatewayIp:$gatewayPort/api/rules'));
      if (response.statusCode == 200) {
        List<dynamic> rulesJson = json.decode(response.body);
        rules = rulesJson
            .map((json) => Rule(
                  tasks: (json['commands'] as List<dynamic>)
                      .map((json) => Task(
                            id: json['id'],
                            commands: json['commands'],
                          ))
                      .toList(),
                  isManual: json['isManual'],
                  dateTime: json['dateTime'] != null
                      ? DateTime.parse(json['dateTime'])
                      : null,
                  repeat: json['repeat'],
                  conditions: (json['conditions'] as List<dynamic>)
                      .map((json) => Condition(
                            item: json['item'],
                            comparator: json['comparator'],
                            value: json['value'],
                          ))
                      .toList(),
                  isEnabled: json['isEnabled'],
                ))
            .toList();
      } else {
        throw Exception('Failed to load automations');
      }
    } catch (e) {
      print('Error fetching automations: $e');
    }
  }

  Future<void> updateRule(Rule rule) async {
    if (gatewayIp == null) return;
    try {
      final response = await http.post(
        Uri.parse('http://$gatewayIp:$gatewayPort/api/rules'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'tasks': rule.tasks
              .map((task) => {
                    'id': task.id,
                    'commands': task.commands,
                  })
              .toList(),
          'isManual': rule.isManual,
          'dateTime': rule.dateTime?.toIso8601String(),
          'repeat': rule.repeat,
          'conditions': rule.conditions
              .map((condition) => {
                    'item': condition.item,
                    'comparator': condition.comparator,
                    'value': condition.value,
                  })
              .toList(),
          'isEnabled': rule.isEnabled,
        }),
      );
      if (response.statusCode == 200) {
        print('Rule updated successfully');
      } else {
        throw Exception('Failed to update rule');
      }
    } catch (e) {
      print('Error updating rule: $e');
    }
  }
}
