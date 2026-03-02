class EnergyContract {
  final String id;           
  String contractName;      
  String provider;
  // 🔥 userName RIMOSSO: Il nome appartiene al profilo, non alla tariffa
  double f1Price;      
  double f2Price;      
  double f3Price;      
  bool isMonorario;
  
  double? f1Pure;       
  double? f2Pure;       
  double? f3Pure;       
  
  double? fixedMonthlyFee;
  double? powerFee;
  double? transportFee;
  double? systemCharges;
  double? vat;
  double spread;            
  DateTime? createdAt;      

  EnergyContract({
    required this.id,       
    this.contractName = "Contratto Standard",
    this.provider = "Nuovo Fornitore",
    this.f1Price = 0.0, 
    this.f2Price = 0.0, 
    this.f3Price = 0.0, 
    this.isMonorario = false,
    this.f1Pure,
    this.f2Pure,
    this.f3Pure,
    this.fixedMonthlyFee,
    this.powerFee,
    this.transportFee,
    this.systemCharges,
    this.vat,
    this.spread = 0.0,      
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contractName': contractName,
    'provider': provider,
    'f1Price': f1Price,
    'f2Price': f2Price,
    'f3Price': f3Price,
    'isMonorario': isMonorario,
    'spread': spread,        
    if (f1Pure != null) 'f1Pure': f1Pure,
    if (f2Pure != null) 'f2Pure': f2Pure,
    if (f3Pure != null) 'f3Pure': f3Pure,
    if (fixedMonthlyFee != null) 'fixedMonthlyFee': fixedMonthlyFee,
    if (powerFee != null) 'powerFee': powerFee,
    if (transportFee != null) 'transportFee': transportFee,
    if (systemCharges != null) 'systemCharges': systemCharges,
    if (vat != null) 'vat': vat,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory EnergyContract.fromJson(Map<String, dynamic> json) => EnergyContract(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    contractName: json['contractName'] ?? "Contratto",
    provider: json['provider'] ?? "",
    f1Price: (json['f1Price'] ?? 0.0).toDouble(), 
    f2Price: (json['f2Price'] ?? 0.0).toDouble(),
    f3Price: (json['f3Price'] ?? 0.0).toDouble(),
    isMonorario: json['isMonorario'] ?? false,
    spread: (json['spread'] ?? 0.0).toDouble(), 
    f1Pure: json['f1Pure']?.toDouble(),
    f2Pure: json['f2Pure']?.toDouble(),
    f3Pure: json['f3Pure']?.toDouble(),
    fixedMonthlyFee: json['fixedMonthlyFee']?.toDouble(),
    powerFee: json['powerFee']?.toDouble(),
    transportFee: json['transportFee']?.toDouble(),
    systemCharges: json['systemCharges']?.toDouble(),
    vat: json['vat']?.toDouble(),
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );

  double getTotalEnergyCost(String fascia) {
    switch (fascia) {
      case 'F1': return f1Price;
      case 'F2': return f2Price;
      case 'F3': return f3Price;
      default: return f1Price;
    }
  }
}