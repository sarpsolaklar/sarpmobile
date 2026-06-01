
with open('lib/screens/scanner_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('\'Barkod bulundu: \\\'', '\'Barkod bulundu: \'')
text = text.replace('\'Barkod okundu: \\\'', '\'Barkod okundu: \'')

with open('lib/screens/scanner_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

