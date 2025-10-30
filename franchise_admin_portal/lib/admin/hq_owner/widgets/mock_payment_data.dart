class MockPaymentData {
  final String cardHolderName;
  final String maskedCardString;
  final String expiryDate;

  MockPaymentData({
    required this.cardHolderName,
    required this.maskedCardString,
    required this.expiryDate,
  });
}
