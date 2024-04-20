In essence the Powershell script is working 
BUT
there is some kind of value to determine what the length between #factions and #end is
This is testable by adding a new byte with ghex or any other hex editor to the tech level of Ancom 1->10
Reducing the amount is not a problem (f. ex.) turning the powerlevel of Tezctlan 800->80
Taking a byte away from relation and adding to tech level is also not a problem. Same is true for one faction to another.

According to ChatGPT there is no real "length" field in resources.assets

The offset for the next block "#alliances" starts at 0xB41A73"
"#factions" starts at 0xB4118C

Taking away \x09 at the end of #end to add for values does not work

## Other notes

Power uses Technology as a factor


## Other examples

between #end and #monster_equipment are (values are from hashes)
0x18A457 - 0x18A40F = 0x48 = 72

between #end and #alliances are
0xB41A73 - 0xB41A49 = 0x2A = 42

between #end and #spaceobjects are
0xB41C96 - 0xB41C6C = 0x2A = 42