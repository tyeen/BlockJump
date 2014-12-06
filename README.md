### What is this
I'm a beginner of Cocoa developing, and just started using Xcode recently.
In my immature opinion, Xcode is lack of navigating skills.
This plug-in lets you jump between methods, or other items in the source editor.

### How does it work
A simple illumination:

![](https://raw.github.com/tyeen/BlockJump/master/screen_record.gif)

I did some research about DVTKit and related sources, and found some ways to get the
range of the methods and other items in the current source file.
Then I just wrote some code that check the current location and find where to go next.

When you press the key combination specified by yourself, you can move around
the source code more easier and faster.

Default Key Combination:

* `CTRL` + `[` :  jump up
* `CTRL` + `]` :  jump down

You can change the key combination by selecting:

    Editor -> Change BlockJump Shortcut

### Limitation
The targets where the caret could jump to are the same as items displayed in

    Menu -> View -> Standard Editor -> Show Document Items

For now, I couldn't do more beyond that.

This plug-in is built under OS X 10.9.2 & Xcode 5.1.

### Installation
You can either

* Use [Alcatraz](http://alcatraz.io/)
* Download(Clone) the source and build it(`cmd` + `B`) in Xcode.

Then restart Xcode and it should work.

### Uninstallation
Just delete the bundle with the name of `BlockJump.xcplugin` in

    ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins

You may also want to remove two keys called: (Remaining is OK, they won't harm anything.)

* com.tyeen.xcplugin.blockjump.jumppreviousblockkey
* com.tyeen.xcplugin.blockjump.jumpnextblockkey

in the file:

    ~/Library/Preferences/com.apple.dt.Xcode.plist
