class TransferInfo {
  final String fromAccountId;
  final String toAccount;
  final String? counterpartyName;
  final String? bankId;
  final String bankName;
  final String description;
  final double amount;
  final String clientRequestId;
  final String? accountNumber; // Added field for account number

  TransferInfo({
    required this.fromAccountId,
    required this.toAccount,
    required this.counterpartyName,
    required this.bankId,
    required this.bankName,
    required this.description,
    required this.amount,
    required this.clientRequestId,
    required this.accountNumber,
  });
}
