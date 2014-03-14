### What is this
I'm just a begginner of Cocoa developing, and started using Xcode just recently.
In my immature opinion, Xcode is lack of navigatiing skills.
This plugin let you jump between two methods or other items in the source editor.
A littel illumination shows how it looks like:

### How does it work
I did some research about DVTKit and related sources, found some information to get the
range of methods and other items in the current source file.

Then just write some code to check the current location and where to go next.

When you pressed the key combination that I defined in this plug-in, you can move around
the source code more easier.

Key combination:
 CTRL + [ : jump up
 CTRL + ] : jump down

### Limitation
For now, I just fix the key combination to <kbd>CTRL</kbd>+<kbd>[</kbd> and <kbd>CTRL+<kbd>]</kbd>.
Maybe I'll consider adding a menu to customize the key combination later. But since it works great
for me, I don't know when that could happen:) So if you're not satisfied with these combination,
you have to change it in the source code. I'm sorry for the inconvenience.

The targets could jump to are same as items displayed in
"Menu" -> "View" -> "Standard Editor" -> "Show Document Items".
For now, I couldn't do more beyond that.

This plug-in is built under OS X 10.9.2 & Xcode 5.1. I didn't test it on other versions.

### Installation
Download the source and open it in Xcode. Run build(cmd + B) and that's all.
Now restart Xcode and it should work now.

### Uninstallation
Just delete the bundle named BlockJump.xcplugin in
~/Library/Application Support/Developer/Shared/Xcode/Plug-ins