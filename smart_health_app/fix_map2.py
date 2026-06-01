
with open('lib/screens/maps_integration_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('\'Enlem: \\nBoylam: \\n(Harita entegrasyonu buraya gelecek)\'', '\'Enlem: \\nBoylam: \\n(Harita entegrasyonu buraya gelecek)\'')

with open('lib/screens/maps_integration_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

