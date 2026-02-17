import 'package:flutter/material.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/core/constants.dart';

class CarSelector extends StatelessWidget {
  final CarModel selectedCar;
  final List<CarModel> allCars; // Nuova lista dinamica
  final ValueChanged<CarModel?> onCarChanged;

  const CarSelector({
    super.key, 
    required this.selectedCar, 
    required this.allCars, 
    required this.onCarChanged
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButton<CarModel>(
        value: allCars.contains(selectedCar) ? selectedCar : allCars.first,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.cardBg,
        items: allCars.map((CarModel car) {
          return DropdownMenuItem<CarModel>(
            value: car,
            child: Text("${car.brand} ${car.model}", style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: onCarChanged,
      ),
    );
  }
}