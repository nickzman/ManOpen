# ManOpen

ManOpen provides a graphical interface for viewing Unix man pages, which are the standard documentation format on macOS for command line programs, programmer libraries, and other system processes.

ManOpen also supports Apropos, which performs a keyword search on the man pages installed on the computer. All Apropos searches are performed locally on your computer; ManOpen will not connect to the Internet for any reason whatsoever.

ManOpen can be useful for opening a man page without using the command line, browsing and searching through man pages, or for printing them out. Customization options for power users are provided.

ManOpen 3.x is based on ManOpen 2.x by Carl Lindberg, and ManOpen 1.x by Harald Schlangmann. This version has been greatly enhanced, with a new UI for macOS 11 ("Big Sur"), support for Dark Mode, native support for Apple Silicon Macs, plus several internal refactors and rewrites so the app will run on modern macOS releases. ManOpen requires macOS 10.9 ("Mavericks") or later.

ManOpen is free software, licensed under the 3-clause (modified) BSD license. This program is provided "as is" and without any warranty. Source code is available on [GitHub](https://github.com/nickzman/ManOpen).

### Installation

Simply copy ManOpen.app to your computer's Applications folder, or wherever you want to put it.

ManOpen adds three services to your computer:

- **Open File in ManOpen** will attempt to open the selected file(s) in ManOpen, or fail silently if any can't be opened.
- **Open man Page in ManOpen** will take the selected text, and attempt to open a man page for each selected word.
- **Search man Page Index in ManOpen** will take the selected text, and search for man pages for each selected word.

As of macOS 11.0, like other macOS services, you can enable and disable these services in System Preferences, in the Keyboard preference pane, under the Shortcuts tab, under the Services table item. You may need to log out and log back in again after installing the app before the services will appear. Also, do note that some third party apps, particularly antivirus apps, are known to interfere with services.

### Searching for man Pages

By default, ManOpen will look for man pages in the following locations:

1. `/usr/share/man` (where built-in macOS command line tool man pages are stored)
2. `/usr/local/man` (where third-party macOS command line tool man pages are stored)
3. Several additional paths used by commonly used first- and third-party developer tools and package managers, if they are installed:
   1. `/opt/X11/share/man` (XQuartz)
   2. `/sw/share/man` and `/opt/sw/share/man` (Fink)
   3. `/opt/local/share/man` (MacPorts)
   4. `/opt/homebrew/share/man` (Homebrew)
   5. `/Applications/Xcode.app/Contents/Developer/usr/share/man` (Xcode, used for its developer tools)
   6. `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man` (Xcode, used for the standard C library, and other macOS APIs)
   7. `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man` (Xcode, used for its compilers)
   8. `/Applications/CMake.app/Contents/man` (CMake GUI)

You can add additional paths as necessary in the Preferences window, under the Advanced tab. You can add a path by clicking the + button. If the path is inside a hidden folder or an application bundle, you can navigate into them by pressing Shift-Command-G to navigate to any arbitrary path.

### Version History

Version 3.0:

- ManOpen now runs natively on Apple Silicon Macs, and requires macOS 10.9 or later. Support for older Macs has been discontinued.
- The UI has been updated to look like a modern macOS app as of macOS 11 ("Big Sur").
- The app has been internally rewritten in places to use modern memory management, auto-layout, the hardened runtime, and new APIs.
- Searching man pages is now done through a search bar instead of a find panel.
- The app now supports auto-termination, so it will disappear from the Dock when all its windows have been closed, and it'll automatically quit if it hasn't been used in a while. You don't have to manually quit the app anymore.
- The services have been renamed to make their function more clear.
- Fixed a bug where the "Copy URL" menu item used the incorrect URL scheme.