### What is this
I'm a beginner of Cocoa developing, and just started using Xcode recently.
In my immature opinion, Xcode is lack of navigatiing skills.
This plug-in let you jump between methods, or other items in the source editor.

### How does it work
A simple illumination:

![](https://raw.github.com/tyeen/BlockJump/master/screen_record.gif)

I did some research about DVTKit and related sources, and found some ways to get the
range of the methods and other items in the current source file.
Then I just wrote some code that check the current location and find where to go next.

When you press the key combination that I defined in this plug-in, you can move around
the source code more easier.

Key combination:

* `CTRL` + `[` :  jump up
* `CTRL` + `]` :  jump down

### Limitation
For now, I just fixed the key combination to `CTRL`+`[` and `CTRL`+`]`.
Maybe I'll consider adding a menu to customize the key combination later. But since it works great
for me, I don't know when that could happen:) So if you're not satisfied with these combinations,
you have to change it in the source code by yourself. I'm sorry for the inconvenience.

The targets where the caret could jump to are the same as items displayed in

    Menu -> View -> Standard Editor -> Show Document Items

For now, I couldn't do more beyond that.

This plug-in is built under OS X 10.9.2 & Xcode 5.1. I haven't tested it on other versions.

### Installation
Download the source and open it in Xcode. Build it(`cmd` + `B`) and that's all.
Now restart Xcode and it should work.

### Uninstallation
Just delete the bundle with the name of `BlockJump.xcplugin` in

    ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins