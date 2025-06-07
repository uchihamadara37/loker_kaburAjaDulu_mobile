class VigenereCipher {
  // Fungsi ini mengenkripsi teks menggunakan kunci Vigenère.
  // Hanya akan mengenkripsi huruf (a-z, A-Z). Karakter lain akan diabaikan.
  static String encrypt(String text, String key) {
    if (key.isEmpty) return text;

    String encryptedText = '';
    int keyIndex = 0;

    // Ubah kunci ke huruf kecil untuk konsistensi
    final String lowerKey = key.toLowerCase();

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      
      // Cek apakah karakter adalah huruf besar (A-Z)
      if (charCode >= 65 && charCode <= 90) {
        int keyChar = lowerKey.codeUnitAt(keyIndex % lowerKey.length) - 97;
        int newCharCode = ((charCode - 65 + keyChar) % 26) + 65;
        encryptedText += String.fromCharCode(newCharCode);
        keyIndex++;
      } 
      // Cek apakah karakter adalah huruf kecil (a-z)
      else if (charCode >= 97 && charCode <= 122) {
        int keyChar = lowerKey.codeUnitAt(keyIndex % lowerKey.length) - 97;
        int newCharCode = ((charCode - 97 + keyChar) % 26) + 97;
        encryptedText += String.fromCharCode(newCharCode);
        keyIndex++;
      } 
      // Jika bukan huruf, tambahkan karakter asli tanpa enkripsi
      else {
        encryptedText += text[i];
      }
    }
    return encryptedText;
  }

  // Fungsi dekripsi bisa dibuat jika perlu, tapi untuk registrasi hanya butuh enkripsi.
  // static String decrypt(String encryptedText, String key) { ... }
}