# Offline Toolkit V2 — မြန်မာလို အသုံးပြုနည်း

ဒီ Edition သည် Offline Toolkit V1 ကို ဆက်လက်တိုးချဲ့ထားသည်။ ရှိပြီးသား Notes, Labs, Quiz, Progress, Bookmarks, Roadmap, Incidents, Scratchpad, Topology, Search များကို ထိန်းထားသည်။

## V2 အသစ်

- **Verify Labs**: Virtual filesystem အတွင်း လက်တွေ့လုပ်ဆောင်ပြီး အဖြေကို state ဖြင့်စစ်သည့် Lab 8 ခု။ Terminal tab တွင် command ရိုက်ပြီး Verify Labs tab တွင် Verify ကိုနှိပ်ပါ။
- **Backup**: Offline progress JSON ကို clipboard သို့ Copy နှင့် JSON Paste/Import (merge) လုပ်နိုင်သည်။ Existing progress ကို မဖျက်ပါ။
- **Persistent Verified Labs**: စစ်ဆေးအောင်မြင်သည့် Virtual Labs ကို shared_preferences တွင် သိမ်းသည်။

## အရေးကြီးသော ကန့်သတ်ချက်

- Terminal သည် Simulator သာဖြစ်ပြီး Android/Linux shell အစစ်မဟုတ်ပါ။ Docker, Kubernetes, Terraform အစစ်ကို execute မလုပ်ပါ။
- Syntax Editor သည် အခြေခံ heuristic checks သာလုပ်သည်။ Full Bash/YAML/HCL parser မဟုတ်ပါ။
- Lab Verify သည် V2 virtual filesystem task 8 ခုကိုသာ auto-verify လုပ်သည်။ Bundled 600 Labs ကို အလိုအလျောက် execute/verify မလုပ်ပါ။
- JSON import သည် local app state ကို merge လုပ်သည်။ External Lab Pack import, PDF Certificate, multilingual full content, and advanced simulation remain incomplete.
- Flutter SDK မရှိသဖြင့် APK/Web runtime build ကို ဒီ environment မှာ မစမ်းနိုင်သေးပါ။

## Build

```powershell
flutter pub get
flutter build apk --release
flutter build web --release --base-href "/linux_note/"
```
