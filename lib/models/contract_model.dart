class EnergyContract {
  String provider;
  String userName;
  double f1Price;      // Prezzo FINITO (già ivato e con oneri dall'IA)
  double f2Price;      
  double f3Price;      
  bool isMonorario;
  
  double? f1Pure;       // Prezzo puro (materia energia)
  double? f2Pure;       
  double? f3Pure;       
  
  double? fixedMonthlyFee;
  double? powerFee;
  double? transportFee;
  double? systemCharges;
  double? vat;

  EnergyContract({
    this.provider = "Nuovo Fornitore",
    this.userName = "Utente",
    this.f1Price = 0.0, // 👈 Azzerato default
    this.f2Price = 0.0, // 👈 Azzerato default
    this.f3Price = 0.0, // 👈 Azzerato default
    this.isMonorario = false,
    this.f1Pure,
    this.f2Pure,
    this.f3Pure,
    this.fixedMonthlyFee,
    this.powerFee,
    this.transportFee,
    this.systemCharges,
    this.vat,
  });

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'userName': userName,
    'f1Price': f1Price,
    'f2Price': f2Price,
    'f3Price': f3Price,
    'isMonorario': isMonorario,
    if (f1Pure != null) 'f1Pure': f1Pure,
    if (f2Pure != null) 'f2Pure': f2Pure,
    if (f3Pure != null) 'f3Pure': f3Pure,
    if (fixedMonthlyFee != null) 'fixedMonthlyFee': fixedMonthlyFee,
    if (powerFee != null) 'powerFee': powerFee,
    if (transportFee != null) 'transportFee': transportFee,
    if (systemCharges != null) 'systemCharges': systemCharges,
    if (vat != null) 'vat': vat,
  };

  factory EnergyContract.fromJson(Map<String, dynamic> json) => EnergyContract(
    provider: json['provider'] ?? "",
    userName: json['userName'] ?? "Utente",
    f1Price: (json['f1Price'] ?? 0.0).toDouble(), // 👈 Azzerato default
    f2Price: (json['f2Price'] ?? 0.0).toDouble(),
    f3Price: (json['f3Price'] ?? 0.0).toDouble(),
    isMonorario: json['isMonorario'] ?? false,
    f1Pure: json['f1Pure']?.toDouble(),
    f2Pure: json['f2Pure']?.toDouble(),
    f3Pure: json['f3Pure']?.toDouble(),
    fixedMonthlyFee: json['fixedMonthlyFee']?.toDouble(),
    powerFee: json['powerFee']?.toDouble(),
    transportFee: json['transportFee']?.toDouble(),
    systemCharges: json['systemCharges']?.toDouble(),
    vat: json['vat']?.toDouble(),
  );

  // 🔥 MODIFICATO: Restituisce il prezzo così com'è, senza aggiungere tasse extra
  double getTotalEnergyCost(String fascia) {
    switch (fascia) {
      case 'F1': return f1Price;
      case 'F2': return f2Price;
      case 'F3': return f3Price;
      default: return f1Price;
    }
  }

  double getTotalFixedMonthlyCost() {
    double total = 0;
    if (fixedMonthlyFee != null) total += fixedMonthlyFee!;
    if (powerFee != null) total += powerFee! * 3;
    return total;
  }

  double getFixedCostPerKwh(double monthlyKwh) {
    if (monthlyKwh <= 0) return 0;
    return getTotalFixedMonthlyCost() / monthlyKwh;
  }
}