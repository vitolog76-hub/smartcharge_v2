class CarModel {
  final String brand;
  final String model;
  final double batteryCapacity;

  CarModel({
    required this.brand,
    required this.model,
    required this.batteryCapacity,
  });

  // Getter per il nome completo (es. "Renault Megane E-Tech")
  String get name => "$brand $model";

  // Trasforma il JSON (cap) nel modello (batteryCapacity)
  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      brand: json['brand'] as String,
      model: json['model'] as String,
      batteryCapacity: (json['cap'] as num).toDouble(),
    );
  }
}

// Lista statica aggiornata per non mandare in crash l'app all'avvio
List<CarModel> myCars = [
  CarModel(brand: "Renault", model: "Megane E-Tech", batteryCapacity: 60.0),
  CarModel(brand: "Tesla", model: "Model 3", batteryCapacity: 75.0),
  CarModel(brand: "Fiat", model: "500e", batteryCapacity: 42.0),
];