# LogFrog
> LogFrog is a QR/Barcode based inventory check-out/check-in system designed to use a mobile device's camera as a scanner. This application mimicks library transaction software and allows for recording of transaction history between items and members of an institution. The application uses the Flutter framework, Dart language, and Firebase's firestore backend to keep track of data.

![alt text](https://github.com/Bao-T/logfrog/blob/master/logfrog/assets/Full_Logo.png)

LogFrog allows users to create a database to inventory items and members of an institution. Each account gets allocated a site in which users can add members and items. Each member and item has stored fields with them to allow users to keep track of information about a site. Items and members will use QR or Barcodes to distinguish their identities. The application will allow members to self-use this system in order to make transaction. There is also admin access where users can access database information, view items and members, update information, or add and delete members.

![](header.png)

## Installation

Flutter Framework Package and Dart SDK required.

MacOS:

https://flutter.dev/docs/get-started/install/macos

Windows:

https://flutter.dev/docs/get-started/install/windows

## Usage
Root file - [main.dart](logfrog/lib/main.dart)

Android:

run ```flutter packages get``` for [pubspec.lock](logfrog/pubspec.lock)

iOS:

run ```flutter packages get``` for [pubspec.lock](logfrog/pubspec.lock)

run ```pod install``` for [Podfile](logfrog/ios/Podfile)

## Meta

Julia Abbot – jabbott19@my.whitworth.edu

Alyssa La Fleur – alafleur19@my.whitworth.edu

Bao Tran – btran19@my.whitworth.edu

