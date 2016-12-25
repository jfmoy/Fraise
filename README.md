# Fraise

Author: Andreas Bentele

Website: http://github.com/abentele/Fraise

This is a fork of Fraise 3.7.3 providing the missing support for macOS Sierra (10.12).
Fraise 3.7.3 was maintained by Jean-Francois Moy (https://github.com/jfmoy/Fraise).
Fraise was originally forked from an earlier version of Smultron, maintained by Peter Borg (https://www.peterborgapps.com/smultron/).

# Releases

see https://github.com/abentele/Fraise/releases

# Roadmap

Currently I'm working on a more stable release with many bug fixes and some minor features.
If you would like to contribute, please let me know.

# Changelog

## 3.7.5

New features:
* added markdown to supported document types
* replaced proprietary full screen mode with macOS full screen mode (https://github.com/abentele/Fraise/issues/1)
* added russian translation (thanks to gpongelli)

Enhancements:
* improved layout for some dialogs
* improved some translations
* changed icons in preferences dialog

Bug fixes:
* no icons in document list panel (https://github.com/abentele/Fraise/issues/12)
* wrong Window sizes on retina display (https://github.com/abentele/Fraise/issues/16)
* print space character with color defined in settings didn't work (https://github.com/abentele/Fraise/issues/13)

This release also fixes many deprecations and code cleanup not done with release 3.7.4.

## 3.7.4

* forked from Fraise 3.7.3 (https://github.com/jfmoy/Fraise)
* support for macOS Sierra (10.12); removed support for OS X 10.11 and earlier
* removed 32bit support
* removed auto-update feature (because it did't work for a long time, and currently there is no maintainer providing releases)
