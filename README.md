You must install PowerShell 2.0 for this script to work. PowerShell 2.0 requires .NET 2.0 to also be installed.

Install by running xpfetch.bat as administator, or just running the xpfetch_ps.ps1 file directly in PowerShell. Once installed, the script can be ran by typing xpfetch in normal command prompt.

By default Windows XP has a super narrow max window width for Command Prompt. You will need to go through Properties -> Layout and change the buffer width. This is not necessary when running the script in PowerShell.

The configuration file is located at %appdata%\xpfetch\xpconf.ini

## Examples
Here's an example image of the script running on my Precision M6300
<img width="1060" height="538" alt="image" src="https://github.com/user-attachments/assets/203a0a36-e2e6-44cd-8d3a-4cb93dfc4014" />


Here's the same script running on my main desktop PC
<img width="960" height="477" alt="image" src="https://github.com/user-attachments/assets/86d245ae-0c8f-4953-90a1-5eab894ad50c" />


## Custom Logos
Here's a quick rundown on the theming engine for ASCII art. To add new ASCII art,  make a file at %appdata%\xpfetch\logos\logo<number>.txt containing your artwork. Set the logoId parameter in %appdata%\xpfetch\xpconf.ini to that number to switch to that. Colors can be set both on lines and specific characters using tags. {r}example{} would print "example"  in red. 

| Key  | Color Name    |
|------|--------------|
| k    | Black         | 
| d    | Dark Gray     |
| l    | Gray          | 
| w    | White         | 
| r    | Red           | 
| g    | Green         | 
| b    | Blue          | 
| c    | Cyan          | 
| m    | Magenta       |
| y    | Yellow        | 
| dr   | Dark Red      | 
| dg   | Dark Green    | 
| db   | Dark Blue     |
| dc   | Dark Cyan     |
| dm   | Dark Magenta  |
| dy   | Dark Yellow   |
