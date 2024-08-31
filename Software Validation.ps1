# Using the Registry to Valide whether software is installed. Intent is to mass replicate this information accross a Domain
#Tests whether the software is stored in the 64 bit directory.
Test-path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ #Software PSPath
#Tests whether the software is stored in the x86 directory.
Test-path HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ #Software PSPath



