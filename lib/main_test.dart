import 'dart:math';

void main() {
  double calculateFrictionFactor(
      double diameter, double roughness, double velocity, double viscosity) {
    double reynoldsNumber = (velocity * diameter) / viscosity;
    double frictionFactor = 0.02;

    for (int i = 0; i < 10; i++) {
      frictionFactor = 1.0 /
          pow(
              -2.0 *
                  log(roughness / (3.7 * diameter) +
                      2.51 / (reynoldsNumber * sqrt(frictionFactor))),
              2);
    }

    return frictionFactor;
  }

  double calculateConductance(double diameter, double length, double roughness,
      double velocity, double viscosity, double density) {
    double frictionFactor =
        calculateFrictionFactor(diameter, roughness, velocity, viscosity);
    double area = pi * pow(diameter, 2) / 4.0;
    double conductance =
        area * sqrt(2.0 / (frictionFactor * (length / diameter) * density));
    return conductance;
  }

  // Пример 1
  double diameter1 = 0.1;
  double length1 = 100;
  double roughness1 = 0.0001;
  double viscosity = 0.0000181;
  double density = 1.225;
  double velocity = 1.0;

  double conductance1 = calculateConductance(
      diameter1, length1, roughness1, velocity, viscosity, density);
  print('Conductance for example 1: $conductance1');

  // Пример 2
  double diameter2 = 0.5;
  double length2 = 200;
  double roughness2 = 0.0002;

  double conductance2 = calculateConductance(
      diameter2, length2, roughness2, velocity, viscosity, density);
  print('Conductance for example 2: $conductance2');

  // Пример 3
  double diameter3 = 1.0;
  double length3 = 500;
  double roughness3 = 0.0005;

  double conductance3 = calculateConductance(
      diameter3, length3, roughness3, velocity, viscosity, density);
  print('Conductance for example 3: $conductance3');
}
