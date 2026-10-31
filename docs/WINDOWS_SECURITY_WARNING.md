# "Virus detected" / SmartScreen warning on the Windows download

**Short version:** the game is an *unsigned* Godot 4.3 export. Windows Defender, SmartScreen and some browsers
flag unsigned, little-downloaded `.exe` files from unknown publishers, and Godot builds are a very common false
positive. Nothing in the project touches your system outside its own save folder. **This has not been verified by an
antivirus scan or launched on Windows by the developer**, so treat this page as how to check, not as a guarantee.

## What the build is
- `TheHollowOath.exe` is the stock Godot 4.3 Windows template; `TheHollowOath.pck` is the game's data. They are shipped
  as two files (not one big exe with the data glued on) because "an exe with a large appended blob" is a classic
  heuristic trigger.
- No code signing certificate (they cost money and need a registered publisher), so SmartScreen will say "unknown publisher".

## Check it yourself
1. **Hashes**: `SHA256SUMS.txt` in `dist/` lists the hash of the zip and each file. In PowerShell: `Get-FileHash .\TheHollowOath.exe`.
2. **VirusTotal**: upload the zip at virustotal.com. One to a few generic "Heuristic / Trojan.Generic / Wacatac"-style hits from
   minor engines is the usual false-positive pattern. Named malware from several major vendors is NOT; do not run it then.
3. **Build it yourself (no download at all)**: install Godot 4.3 + its Windows export templates, open the project, and run
   `godot --headless --path . --export-release "Windows Desktop" build/windows/TheHollowOath.exe`
   (or just press F5 / "Run" in the Godot editor to play without exporting).
4. **Tell Microsoft it is safe** (only if step 2 looked like noise): https://www.microsoft.com/en-us/wdsi/filesubmission
   ("I think this file is not malware"). Then Defender → Protection history → Allow on device.

## What would actually remove the warning
- Buying a code-signing certificate and signing the exe (the developer cannot do this from the cloud build).
- Publishing through a store (itch.io, Steam) whose installers are scanned and trusted.
- A browser (HTML5) export, which never downloads an exe. Not built yet.
