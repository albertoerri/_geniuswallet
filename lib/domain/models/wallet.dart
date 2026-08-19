enum WalletImportType {
  recoveryPhrase,
  privateKey,
  generated,
}

class Wallet {
  final String id;
  final String name;
  final String address;
  final String networkId;
  final WalletImportType importType;
  final DateTime createdAt;
  final bool isBackedUp;

  const Wallet({
    required this.id,
    required this.name,
    required this.address,
    required this.networkId,
    required this.importType,
    required this.createdAt,
    this.isBackedUp = true,
  });

  Wallet copyWith({
    String? id,
    String? name,
    String? address,
    String? networkId,
    WalletImportType? importType,
    DateTime? createdAt,
    bool? isBackedUp,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      networkId: networkId ?? this.networkId,
      importType: importType ?? this.importType,
      createdAt: createdAt ?? this.createdAt,
      isBackedUp: isBackedUp ?? this.isBackedUp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'networkId': networkId,
      'importType': importType.name,
      'createdAt': createdAt.toIso8601String(),
      'isBackedUp': isBackedUp,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      networkId: json['networkId'] as String,
      importType: WalletImportType.values.firstWhere(
        (e) => e.name == json['importType'],
        orElse: () => WalletImportType.recoveryPhrase,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isBackedUp: json['isBackedUp'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
