import 'package:flutter/material.dart';

import '../../dashboard/model/picked_file_item.dart';

enum DeviceFilter { all, myDevices, nearby }

enum DeviceConnectionType { account, bluetooth, airdrop }

class TransferDevice {
  const TransferDevice({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isOnline,
    required this.isNearby,
    required this.radarAngle,
    required this.radarRadius,
    required this.connectionType,
    this.isHost = false,
    this.subtitle,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isOnline;
  final bool isNearby;
  final double radarAngle;
  final double radarRadius;
  final DeviceConnectionType connectionType;
  final bool isHost;
  final String? subtitle;

  bool get isAccountLinked => connectionType == DeviceConnectionType.account;

  String get statusLabel {
    if (!isOnline) return 'Offline';
    return switch (connectionType) {
      DeviceConnectionType.account => 'Same account',
      DeviceConnectionType.bluetooth => 'Bluetooth',
      DeviceConnectionType.airdrop => 'AirDrop',
    };
  }

  static TransferDevice host({required String deviceName}) {
    return TransferDevice(
      id: 'host',
      name: deviceName,
      icon: Icons.laptop_mac_rounded,
      color: const Color(0xFF4D49FF),
      isOnline: true,
      isNearby: true,
      radarAngle: 0,
      radarRadius: 0,
      connectionType: DeviceConnectionType.account,
      isHost: true,
      subtitle: 'Sending from',
    );
  }

  static List<TransferDevice> buildPeers() {
    // Evenly spaced around the radar to avoid label overlap.
    const configs = [
      (name: 'Android', icon: Icons.smartphone_rounded, color: Color(0xFF00BFA5), online: true, nearby: true, angle: -1.57, radius: 0.74, type: DeviceConnectionType.account),
      (name: 'Office PC', icon: Icons.desktop_windows_rounded, color: Color(0xFF1976D2), online: true, nearby: false, angle: -0.52, radius: 0.58, type: DeviceConnectionType.account),
      (name: 'iPad Pro', icon: Icons.tablet_mac_rounded, color: Color(0xFF7E57C2), online: true, nearby: true, angle: 0.52, radius: 0.74, type: DeviceConnectionType.account),
      (name: 'Nearby Laptop', icon: Icons.laptop_rounded, color: Color(0xFF455A64), online: true, nearby: true, angle: 1.57, radius: 0.58, type: DeviceConnectionType.bluetooth),
      (name: 'iPhone Nearby', icon: Icons.phone_iphone_rounded, color: Color(0xFF4D49FF), online: true, nearby: true, angle: 2.62, radius: 0.74, type: DeviceConnectionType.airdrop),
      (name: 'Earbuds', icon: Icons.headphones_rounded, color: Color(0xFF9CA3AF), online: false, nearby: false, angle: 3.67, radius: 0.52, type: DeviceConnectionType.bluetooth),
    ];

    return [
      for (var i = 0; i < configs.length; i++)
        TransferDevice(
          id: 'peer-$i',
          name: configs[i].name,
          icon: configs[i].icon,
          color: configs[i].color,
          isOnline: configs[i].online,
          isNearby: configs[i].nearby,
          radarAngle: configs[i].angle,
          radarRadius: configs[i].radius,
          connectionType: configs[i].type,
          subtitle: configs[i].type == DeviceConnectionType.account
              ? 'Logged in'
              : configs[i].type == DeviceConnectionType.airdrop
                  ? 'AirDrop'
                  : 'Bluetooth',
        ),
    ];
  }

  static List<TransferDevice> filtered(DeviceFilter filter, List<TransferDevice> peers) {
    return switch (filter) {
      DeviceFilter.all => peers,
      DeviceFilter.myDevices =>
        peers.where((d) => d.isAccountLinked && d.isOnline).toList(),
      DeviceFilter.nearby => peers
          .where(
            (d) =>
                d.isOnline &&
                (d.connectionType == DeviceConnectionType.bluetooth ||
                    d.connectionType == DeviceConnectionType.airdrop ||
                    d.isNearby),
          )
          .toList(),
    };
  }

  static int countFor(DeviceFilter filter, List<TransferDevice> peers) {
    return filtered(filter, peers).length;
  }
}

class FileDragPayload {
  const FileDragPayload(this.files);

  final List<PickedFileItem> files;
}

class TransferredFileDetail {
  const TransferredFileDetail({
    required this.fileName,
    required this.fileSizeLabel,
    required this.icon,
    this.extension,
  });

  final String fileName;
  final String fileSizeLabel;
  final IconData icon;
  final String? extension;
}

class TransferResult {
  const TransferResult({
    required this.destinationName,
    required this.destinationIcon,
    required this.files,
  });

  final String destinationName;
  final IconData destinationIcon;
  final List<TransferredFileDetail> files;

  int get fileCount => files.length;
}
