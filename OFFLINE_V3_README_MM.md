# Offline Toolkit V3 — မြန်မာလို မှတ်စု

V2 ပေါ်တွင် တိုးချဲ့ထားပြီး အရင် Notes, Labs, Quiz, Dashboard, Bookmarks နှင့် Backup ကို ဆက်လက်ထိန်းထားသည်။

## အသစ်
- Virtual lab 8 ခုမှ 20 ခုသို့ တိုးချဲ့ထားသည်။
- Virtual terminal commands: `cp`, `mv`, `chmod`, `grep`, `wc`, `head`, `rmdir`, `mkdir -p`, `echo >`, `echo >>`။
- Verification သည် command history သာမက virtual filesystem state, file contents, permissions, removed paths ကို စစ်သည်။
- User က အရင် lab တစ်ခုကို ပြီးထားလျှင် V2 completed progress ကို ဆက်လက်သိမ်းထားသည်။

## ကန့်သတ်ချက်များ
- Android/Linux shell အစစ်မဟုတ်ပါ။ No subprocess, Docker daemon, Kubernetes cluster, SSH or network connection.
- `grep`, `wc`, `head`, `chmod` တို့သည် simplified simulation ဖြစ်သည်။
- Virtual filesystem state သည် app restart ပြီးနောက် reset ဖြစ်သည်; verified completion သာ persistence ရှိသည်။
- Flutter SDK မရှိသဖြင့် build/runtime verification မလုပ်ရသေးပါ။

## Build
`flutter pub get`
`flutter build apk --release`
`flutter build web --release --base-href "/linux_note/"`
