import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:http/http.dart' as http;

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
}

class AutomationRule {
  final String id;
  final String device;
  final String condition;
  final String action;

  AutomationRule({
    required this.id,
    required this.device,
    required this.condition,
    required this.action,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'],
      device: json['device'],
      condition: json['condition'],
      action: json['action'],
    );
  }
}

class SessionModel extends ChangeNotifier {
  List<Device> devices = [];
  String? gatewayIp;
  bool isLoading = false;
  int? gatewayPort;

  SessionModel() {
    discoverGateway();
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
            fetchDevices(); // 找到网关后立即获取设备
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
        await Future.delayed(const Duration(milliseconds: 256));
        final statusResponse = await http
            .get(Uri.parse('http://$gatewayIp:$gatewayPort/api/status/$id'));
        if (statusResponse.statusCode == 200) {
          var data = json.decode(statusResponse.body);
          devices.firstWhere((device) => device.id == id).status = data;
          print('Device $id status: ${data}');
        } else {
          throw Exception('Failed to fetch device status');
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

  void getAutomations() async {
    if (gatewayIp == null) return;
    try {
      final response = await http
          .get(Uri.parse('http://$gatewayIp:$gatewayPort/api/automations'));
      if (response.statusCode == 200) {
        print('Automations: ${response.body}');
      } else {
        throw Exception('Failed to load automations');
      }
    } catch (e) {
      print('Error fetching automations: $e');
    }
  }
}
