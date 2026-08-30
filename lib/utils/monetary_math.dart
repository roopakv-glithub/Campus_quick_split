class MonetaryMath {
  /// Rounds a double to 2 decimal places.
  static double round(double value) {
    return (value * 100).round() / 100;
  }

  /// Distributes an amount equally among [count] participants.
  /// Handles rounding by assigning the remainder to the first participant.
  static List<double> distributeEqually(double total, int count) {
    if (count <= 0) return [];
    double share = round(total / count);
    List<double> distributions = List.filled(count, share);
    
    double sum = round(share * count);
    double diff = round(total - sum);
    
    if (diff != 0) {
      distributions[0] = round(distributions[0] + diff);
    }
    
    return distributions;
  }
}
