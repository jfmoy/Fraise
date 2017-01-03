# Fraise

This is a fork of Fraise 3.7.3 providing the missing support for macOS Sierra (10.12).
Forked in 2016 from a github repository discontinued long ago, my main interest is to keep the popular app alive.

Author: Andreas Bentele
Website: http://github.com/abentele/Fraise

[Fraise 3.7.3](https://github.com/jfmoy/Fraise) was maintained by Jean-Francois Moy, but discontinued.
Fraise originally was forked from [Smultron 3.5.1](https://sourceforge.net/projects/smultron/), maintained by Peter Borg.

# Releases

see [Releases](https://github.com/abentele/Fraise/releases)

# Roadmap

Currently my main interest is to fix bugs, enhance already existing features and implement some new features while retaining the original focus and feature-set of Fraise:
* powerful, but easy to use
* provide many helpful tools to edit texts
* support for many code languages (e.g. syntax highlighting)

For more details, see the [Issues list](https://github.com/abentele/Fraise/issues).

# Contribution

Please add bugs and wishes to the issues list, or discuss existing issues with me and the community.
If you would like to contribute, please let me know.

# Changelog

## Fraise 3.7.6

Release date: 2016-12-31

Bug fixes:
* fixed a crash on launch (https://github.com/abentele/Fraise/issues/18)
* fixed a crash when loading binary files (https://github.com/abentele/Fraise/issues/10)
* fixed a crash when printing to PDF
* fixed margins when printing with header (https://github.com/abentele/Fraise/issues/5)

[Commit list](https://github.com/abentele/Fraise/compare/3.7.5...3.7.6)

## Fraise 3.7.5

Release date: 2016-12-25

New features:
* added markdown to supported document types
* added russian translation (thanks to gpongelli)

Enhancements:
* replaced proprietary full screen mode with macOS full screen mode (https://github.com/abentele/Fraise/issues/1)
* improved layout for some dialogs
* improved some translations
* changed icons in preferences dialog
* ignore .git folder when opening the contents of a folder

Bug fixes:
* no icons in document list panel (https://github.com/abentele/Fraise/issues/12)
* wrong Window sizes on retina display (https://github.com/abentele/Fraise/issues/16)
* print space character with color defined in settings didn't work (https://github.com/abentele/Fraise/issues/13)
* fixed a crash when trying to open a folder

This release also fixes many deprecations and code cleanup not done with release 3.7.4.

[Commit list](https://github.com/abentele/Fraise/compare/3.7.4...3.7.5)

## Fraise 3.7.4

Release date: 2016-10-04

* forked from [Fraise 3.7.3](https://github.com/jfmoy/Fraise)
* support for macOS Sierra (10.12); removed support for OS X 10.11 and earlier
* removed 32bit support
* removed auto-update feature (because it did't work for a long time, and currently there is no maintainer providing releases)

[Commit list](https://github.com/abentele/Fraise/compare/3.7.3...3.7.4)
