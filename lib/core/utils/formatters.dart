class Formatters {
  Formatters._();

  /// Shortens an Ethereum/EVM address to standard 0x1234...5678 format
  static String formatAddress(String? address, {int leading = 6, int trailing = 4}) {
    if (address == null || address.isEmpty) return '';
    if (address.length <= leading + trailing) return address;
    return '${address.substring(0, leading)}...${address.substring(address.length - trailing)}';
  }

  /// Cleans mnemonic input (removes extra spaces, newlines, lowercases)
  static String cleanMnemonic(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Cleans private key input (removes whitespace, ensures 0x prefix is handled)
  static String cleanPrivateKey(String input) {
    String cleaned = input.trim();
    if (cleaned.startsWith('0x') || cleaned.startsWith('0X')) {
      cleaned = cleaned.substring(2);
    }
    return cleaned;
  }
}
