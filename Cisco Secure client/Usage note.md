This recipe is to be used with a .dmg from the network team.  It 's helpful to add the organisations VPN profile too.

autopkg run UoS.CiscoSecureClient.pkg.recipe.yaml -p <PATH TO .DMG FILE> --key PROFILES=< PATH TO FOLDER WITH VPN PROFILE >

The VPN profile must be in a subfolder called 'vpn'.
