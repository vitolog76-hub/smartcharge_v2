class EnergyContract {
  final String id;           
  String contractName;      
  String provider;
  String userName;
  double f1Price;      // Rappresenta la Materia Prima inserita dall'utente
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
  double spread;            // 🔥 NUOVO: Spread, Omega o costi extra kWh (es. 0.06)
  DateTime? createdAt;      

  EnergyContract({
    required this.id,       
    this.contractName = "Contratto Standard",
    this.provider = "Nuovo Fornitore",
    this.userName = "Utente",
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
    this.spread = 0.0,      // Default a 0
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'contractName': contractName,
    'provider': provider,
    'userName': userName,
    'f1Price': f1Price,
    'f2Price': f2Price,
    'f3Price': f3Price,
    'isMonorario': isMonorario,
    'spread': spread,        // Salvataggio spread
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
    userName: json['userName'] ?? "Utente",
    f1Price: (json['f1Price'] ?? 0.0).toDouble(), 
    f2Price: (json['f2Price'] ?? 0.0).toDouble(),
    f3Price: (json['f3Price'] ?? 0.0).toDouble(),
    isMonorario: json['isMonorario'] ?? false,
    spread: (json['spread'] ?? 0.0).toDouble(), // Caricamento spread
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

  // Nota: Questo metodo verrà superato dalla logica del CostCalculator
  // ma lo manteniamo per compatibilità.
  double getTotalFixedMonthlyCost() {
    double total = 0;
    if (fixedMonthlyFee != null) total += fixedMonthlyFee!;
    if (powerFee != null) total += (powerFee! * 1.79); // 1.79€ è la media quota potenza/mese/kW
    return total;
  }
}