enum CalculationMethod {
  diyanet(13, 'Diyanet (Türkiye / Europe)'),
  mwl(3, 'Muslim World League'),
  isna(2, 'ISNA (North America)'),
  makkah(4, 'Umm Al-Qura (Makkah)'),
  egypt(5, 'Egyptian General Authority');

  final int id;
  final String title;

  const CalculationMethod(this.id, this.title);

  static CalculationMethod fromId(int? id) {
    if (id == null) return CalculationMethod.diyanet;
    return CalculationMethod.values.firstWhere(
      (m) => m.id == id,
      orElse: () => CalculationMethod.diyanet,
    );
  }
}
