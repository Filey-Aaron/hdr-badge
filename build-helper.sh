#!/bin/bash
# 构建 helper.apk（纯命令行，无需 Gradle）
set -e
export JAVA_HOME="C:/Users/Yaohui/WorkBuddy/2026-10-23-18-19-30/hdr-badge/build-tools/jdk-17.0.20.1+1"
export PATH="$JAVA_HOME/bin:$PATH"
ROOT="/c/Users/Yaohui/WorkBuddy/2026-10-23-18-19-30/hdr-badge"
BT="$ROOT/build-tools/android-14"
JDK="$ROOT/build-tools/jdk-17.0.20.1+1"
JAR="$ROOT/build-tools/android-34/android.jar"
H="$ROOT/helper"
OUT="$ROOT/build-tools/out"

rm -rf "$OUT"; mkdir -p "$OUT/classes" "$OUT/dex"

echo "[1/5] 编译资源..."
"$BT/aapt2.exe" compile --dir "$H/res" -o "$OUT/res.zip"

echo "[2/5] 链接资源..."
"$BT/aapt2.exe" link -o "$OUT/base.apk" \
  -I "$JAR" \
  --manifest "$H/AndroidManifest.xml" \
  --java "$OUT/gen" \
  "$OUT/res.zip" \
  --min-sdk-version 29 --target-sdk-version 33 \
  --auto-add-overlay

echo "[3/5] 编译 Java..."
"$JDK/bin/javac.exe" -source 11 -target 11 -encoding UTF-8 \
  -classpath "$JAR" -classpath "$JAR" -Xlint:-options \
  -d "$OUT/classes" \
  $(find "$H/src" "$OUT/gen" -name "*.java")

echo "[4/5] dex..."
cd "$OUT/classes" && "$JDK/bin/jar.exe" cf "$OUT/classes.jar" . && cd "$ROOT"
"$BT/d8.bat" --release --lib "$JAR" --min-api 29 \
  --output "$OUT/dex" "$OUT/classes.jar"

echo "[5/5] 打包 + 签名..."
cd "$OUT" && cp base.apk unsigned.apk && cd "$ROOT"
(cd "$OUT" && "$JDK/bin/jar.exe" uf unsigned.apk -C dex classes.dex)

if [ ! -f "$ROOT/build-tools/keystore.jks" ]; then
  "$JDK/bin/keytool.exe" -genkeypair -v -keystore "$ROOT/build-tools/keystore.jks" \
    -alias hdrbadge -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass hdrbadge -keypass hdrbadge \
    -dname "CN=HDRBadge, OU=Mod, O=Local, L=Local, S=Local, C=CN" 2>/dev/null
fi

"$BT/zipalign.exe" -f 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"
"$BT/apksigner.bat" sign --ks "$ROOT/build-tools/keystore.jks" \
  --ks-pass pass:hdrbadge --key-pass pass:hdrbadge \
  --out "$ROOT/module/helper.apk" "$OUT/aligned.apk"

ls -la "$ROOT/module/helper.apk"
echo "构建完成"
