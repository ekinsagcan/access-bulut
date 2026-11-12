# Access Bulut

Tarayıcıdan açılan, içinde Word, Excel ve **Microsoft Access** kurulu bir Windows 11. Mac'e hiçbir şey kurulmaz, hiçbir şey indirilmez.

[![GitHub Codespaces'te aç](https://github.com/codespaces/badge.svg)](https://codespaces.new/ekinsagcan/access-bulut?quickstart=1)

## İlk açılış (bir kere, ~45 dakika)

1. Ücretsiz bir GitHub hesabı aç: <https://github.com/signup>
2. **Önemli:** <https://github.com/settings/codespaces> → **Default idle timeout** kutusuna `240` yaz → **Save**.
   Yoksa GitHub 30 dakika sonra "kimse kullanmıyor" sanıp Windows'u kapatıyor (kurulum yarıda kalır, ödev yaparken de kapanır).
3. Yukarıdaki **"Open in GitHub Codespaces"** butonuna bas → **Create codespace**.
4. Bekle. Windows bulutta kendi kendine kuruluyor. Bir süre sonra yeni bir sekmede Windows ekranı açılır.
   - Sekme açılmazsa: alttaki **PORTS** sekmesi → `Windows (8006)` satırındaki 🌐 simgesine bas.
   - Ekranda "Office kuruluyor" penceresi görünecek. Kapatma, bitince kendisi kapanır.
5. Masaüstündeki **Access** simgesine çift tıkla → okul hesabınla giriş yap: `öğrencino@emu.edu.tr` + öğrenci portalı şifresi.

## Sonraki açılışlar (~1 dakika)

Aynı butona bas (ya da <https://github.com/codespaces> → codespace'ine tıkla). Windows kaldığı yerden açılır. Sekme açılmazsa yine **PORTS** → 🌐.

## Dosyalarını kaybetme

- En kolayı: Access dosyalarını **OneDrive**'a kaydet (okul hesabında var). Okulun bilgisayarından da, telefondan da açılır.
- Mac'e almak istersen: Windows masaüstündeki **Shared** klasörüne (Z: sürücüsü) koy. Sonra codespace'in VS Code sekmesinde sol taraftaki **Dosyalar** klasörünü aç → dosyaya sağ tık → **Download**.

## Önemli: limitler

- Ücretsiz GitHub hesabı **ayda ~60 saat** kullanım veriyor (2 çekirdekli makinede). Bitince sekmeyi kapatman yeter, 30 dakika işlem yapılmazsa codespace kendini durdurur. Hemen durdurmak için: <https://github.com/codespaces> → `...` → **Stop codespace**.
- Kart bilgisi girmediysen **asla para çekilmez**; limit dolarsa ay başına kadar açılmaz, o kadar.
- Daha fazla saat için DAÜ mailinle **GitHub Student Pack** al (ücretsiz): <https://education.github.com/pack>
- Codespace'i **silme**; silersen Windows'u baştan kurar. 30 gün hiç açılmazsa GitHub kendisi siler.

## Kullanıcı bilgisi

Windows giriş: kullanıcı `Ogrenci`, şifre `access` (otomatik giriş yapıyor, genelde sormaz).

---

Teknik: [dockur/windows](https://github.com/dockur/windows) + GitHub Codespaces. Windows lisanssız (deneme) modda çalışır; Office lisansı okulun Microsoft 365 hesabından gelir.
