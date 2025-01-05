### Android Release KeyStore - Command

keytool -genkey -v -keystore keystorespacemate.keystore -alias spacemate-key-alias -keyalg RSA -keysize 2048 -validity 10000

### Android Release Key Properties

storePassword=spacemate
keyPassword=spacemate
keyAlias=spacemate-key-alias
storeFile=keystorespacemate.keystore

## Android SigningReport
./gradlew signingReport
keytool -keystore keystorespacemate.keystore -list -v
