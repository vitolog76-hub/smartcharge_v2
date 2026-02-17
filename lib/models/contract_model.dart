class EnergyContract {
  String provider;
  String userName; // Dichiarata correttamente
  double f1Price;
  double f2Price;
  double f3Price;
  bool isMonorario;

  EnergyContract({
    this.provider = "Nuovo Fornitore",
    this.userName = "Utente", // AGGIUNTA AL COSTRUTTORE
    this.f1Price = 0.20,
    this.f2Price = 0.18,
    this.f3Price = 0.15,
    this.isMonorario = false,
  });

  // Utile per salvare/caricare da SharedPreferences e Cloud
  Map<String, dynamic> toJson() => {
    'provider': provider,
    'userName': userName, // AGGIUNTA AL JSON
    'f1Price': f1Price,
    'f2Price': f2Price,
    'f3Price': f3Price,
    'isMonorario': isMonorario,
  };

  factory EnergyContract.fromJson(Map<String, dynamic> json) => EnergyContract(
    provider: json['provider'] ?? "",
    userName: json['userName'] ?? "Utente", // AGGIUNTA AL PARSING
    f1Price: (json['f1Price'] ?? 0.0).toDouble(),
    f2Price: (json['f2Price'] ?? 0.0).toDouble(),
    f3Price: (json['f3Price'] ?? 0.0).toDouble(),
    isMonorario: json['isMonorario'] ?? false,
  );
}