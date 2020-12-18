# Weeb Manager

For all your weeb needs
This will use your myanimelist.net account, to check what currently airing shows you're watching.
It will then display all the shows in which you're not caught up and display the amount of episodes
that you still have to watch

## Building
if you want to build this from scratch, you need to include the client id for myanimelist
in lib/api/clientId.dart.
To do that, just create the file lib/api/clientId.dart and add the following content to it
```dart
final clientId = '<your client id>';
```

![demo](https://user-images.githubusercontent.com/24765381/100393523-36c44180-303a-11eb-8353-f265298e3b4b.jpg)
