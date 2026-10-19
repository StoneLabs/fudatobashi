#!/bin/sh
# Renders one mock card per skin to refs/ at 748x1050.
D=$(cd "$(dirname "$0")/.." && pwd)
shot(){ # out hash
  chromium --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --window-size=748,1050 --virtual-time-budget=4000 --screenshot="$D/refs/$1.png" \
    "file://$D/src/refpage.html#$2" 2>/dev/null
}
for k in standard washi seigaiha asanoha shippo yagasuri kikko sakura fuji ariake urushi nishiki; do shot $k "id=$k"; done
for p in red:C8372D:12 pink:E8749A:84 orange:EE8A2A:12 yellow:EDC531:26 green:5FAE4A:17 blue:2B7FD0:17 purple:7A4FA0:17 black:2D2C2A:2; do
  n=${p%%:*}; r=${p#*:}; c=${r%%:*}; po=${r#*:}
  shot basic_$n "id=basic_$n&trim=%23$c&poem=$po"
done
