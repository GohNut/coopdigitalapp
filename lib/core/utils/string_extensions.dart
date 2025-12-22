
extension StringExtension on String {
  String formatCitizenId() {
    if (this.length != 13) return this;
    return '${this.substring(0, 1)}-${this.substring(1, 5)}-${this.substring(5, 10)}-${this.substring(10, 12)}-${this.substring(12, 13)}';
  }
}
