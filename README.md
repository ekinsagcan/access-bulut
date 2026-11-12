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

# Alternatif: Kendi Mac'ine kur (UTM)

Bulut yerine Windows'u kendi Mac'inde çalıştırmak istersen (saat sınırı yok, daha hızlı, internetsiz de açılır). Sadece **M1/M2/M3/M4** Mac'lerde çalışır ve **en az 37 GB boş yer** ister.

1. **Terminal**'i aç (Spotlight: ⌘ + Boşluk → "Terminal").
2. Şu satırı yapıştır, Enter'a bas:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/ekinsagcan/access-bulut/main/mac/Access-Kur.command | bash
   ```

3. Mac "Terminal, UTM'i denetlemek istiyor" derse **İzin Ver**.
4. Microsoft'un sayfası açılınca: *Windows 11 (Arm64 için çok sürümlü ISO)* → İndir → **Türkçe** → Onayla → İndir (~6 GB).
   Windows dosyası zaten İndirilenler klasöründeyse bu adım atlanır.
5. İndirme bitince her şey kendiliğinden devam eder: UTM'de Windows kurulur, sonra Word, Excel ve Access yüklenir (45–60 dk). Mac'i şarja tak, kapatma.
6. Sonraki açılışlar: Mac masaüstündeki **Windows (Access)** simgesine çift tıkla.

Kurulum kaydı: `~/Access-Windows/kurulum.log`. Windows dosyası (İndirilenler'deki `.iso`) kurulumdan sonra **silinmemeli**; silinirse Windows yine açılır ama UTM bir uyarı gösterebilir.

---

Teknik: [dockur/windows](https://github.com/dockur/windows) + GitHub Codespaces. Windows lisanssız (deneme) modda çalışır; Office lisansı okulun Microsoft 365 hesabından gelir.
