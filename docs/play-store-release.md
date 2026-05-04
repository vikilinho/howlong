# Google Play Release Checklist

HowLong is configured for Google Play release builds from Android Studio or the Flutter CLI.

## Requirements

- Android target SDK 35 or higher.
- A private upload keystore kept outside git.
- Play App Signing enabled in Play Console.
- Release builds signed with the upload key, not the debug key.
- Android App Bundle (`.aab`) for Play uploads.
- Split APKs only for physical-device smoke testing.

## Signing Setup

Create or reuse an upload keystore, then copy the template:

```sh
cp android/key.properties.example android/key.properties
```

Fill `android/key.properties` with the keystore passwords, alias, and path:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../upload-keystore.jks
```

`android/key.properties` and keystore files are ignored by git.

## Build For Google Play

```sh
/Users/victor/flutter/bin/flutter build appbundle --release
```

Upload the generated bundle from:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload the generated deobfuscation file with the same Play release:

```text
build/app/outputs/mapping/release/mapping.txt
```

The mapping file is generated because release builds use R8 minification and resource shrinking.

## Build Split APKs For Device Testing

```sh
/Users/victor/flutter/bin/flutter build apk --release --split-per-abi
```

The split APKs are generated in:

```text
build/app/outputs/flutter-apk/
```
