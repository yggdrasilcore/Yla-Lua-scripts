-- Multistate: Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end

-- Event registration
function OnGossipHello(event, player, creature)
   player:GossipClearMenu()
   --player:GossipMenuAddItem(0, "What do you want to ask about?", 0, 1) 
   player:GossipMenuAddItem(0, "Tell me where I am", 0, 20) 
   player:GossipMenuAddItem(0, "Portals", 0, 2)
   player:GossipMenuAddItem(0, "Professions", 0, 3)
   player:GossipMenuAddItem(0, "Vendors", 0, 4)
   player:GossipMenuAddItem(0, "Auction House", 0, 5)
   player:GossipMenuAddItem(0, "Mailbox", 0, 21)
   player:GossipMenuAddItem(0, "Guild Services", 0, 6)
   player:GossipMenuAddItem(0, "Character Services", 0, 7)
   player:GossipMenuAddItem(0, "Transmogrification", 0, 8)
   player:GossipMenuAddItem(0, "Class Trainers", 0, 9)
   player:GossipMenuAddItem(0, "Flight and Riding Services", 0, 10)
   player:GossipMenuAddItem(0, "Pet Services", 0, 11)
   player:GossipMenuAddItem(0, "Repair", 0, 12)
   player:GossipMenuAddItem(0, "Enchantments", 0, 13)
   player:GossipSendMenu(12, creature)
end

-- Select handler
function OnGossipSelect(event, player, creature, sender, intid, code)
   if(intid == 1) then -- What do you want to ask about
       OnGossipHello(event, player, creature)
       
   elseif(intid == 2) then -- Portals
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Each faction has its own set of portals in their own portal tower in the main base. In the base over the bridge, see the towers on the left and right of the entrance. As you enter, the left tower contains Horde portals while the right building contains Alliance portals.", 0, 2)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 20) then -- where am I
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Welcome to Yggdrasil!\n \nThis is the last dominion of Yggdrasil, the world tree holding together the stiching between the realms of our world. Though, technically, we are in the Azshara Crater right now.\n \nThis area is the remnant of a terrible cosmic event that shattered the realm between the realms of the world and sent a meteor from the Twisting Nether down on Azshara.\n \nThis part of Azshara was blown out of Azshara to form a separate continent that the Twiggies have come to call home. As this event took place eons ago, fragments of Yggdrasil, virtually wiped out in the outside world, were preserved here.\n \nEvery Twiggy has since been formed by the fragments that live in the fauna and flora here.\n \nYggdrasil welcomes you to one of its last realms of dominion!\n \n", 0, 20)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 21) then -- mailbox
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "There are mailboxes outside of the central building immediately ahead as you pass the gate on the hill ahead.", 0, 21)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 3) then -- Professions
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Alchemy", 0, 30)
       player:GossipMenuAddItem(0, "Herbalism", 0, 30)
       player:GossipMenuAddItem(0, "Inscription", 0, 30)
       player:GossipMenuAddItem(0, "Blacksmithing", 0, 31)
       player:GossipMenuAddItem(0, "Engineering", 0, 31)
       player:GossipMenuAddItem(0, "Jewelcrafting", 0, 31)
       player:GossipMenuAddItem(0, "Mining", 0, 31)
       player:GossipMenuAddItem(0, "Enchanting", 0, 32)
       player:GossipMenuAddItem(0, "Leatherworking", 0, 32)
       player:GossipMenuAddItem(0, "Skinning", 0, 32)
       player:GossipMenuAddItem(0, "Tailoring", 0, 32)
       player:GossipMenuAddItem(0, "Cooking", 0, 33)
       player:GossipMenuAddItem(0, "Fishing", 0, 33)
       player:GossipMenuAddItem(0, "First Aid", 0, 32)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 4) then -- Vendors
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Transmogrification items", 0, 41)
       player:GossipMenuAddItem(0, "Bartender", 0, 42)
       player:GossipMenuAddItem(0, "Poison", 0, 43)
       player:GossipMenuAddItem(0, "Flight paths", 0, 44)
       player:GossipMenuAddItem(0, "Reagents", 0, 45)
       player:GossipMenuAddItem(0, "Heirlooms", 0, 46)
       player:GossipMenuAddItem(0, "Currency exchanger", 0, 47)
       player:GossipMenuAddItem(0, "Guild", 0, 48)
       player:GossipMenuAddItem(0, "Hunter pets", 0, 49)
       player:GossipMenuAddItem(0, "Professions", 0, 50)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 5) then -- ah
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "There is an auctioneer offering access to all auction houses at the central building immediately ahead as you pass the gate on the hill ahead.", 0, 5)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 6) then -- guild
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "If you are interested in purchasing or renaming a guild, please visit the westernmost building on the hill ahead. If you are looking for a guild vault, check the building immediately ahead as you cross the hill's gate.", 0, 6)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 7) then -- character services
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "In the westernmost building on the hill ahead, you can find both a barbershop and a character customizer, offering to change your Name, Faction, Race, and customizations.", 0, 7)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 8) then -- tmog
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Find all the transmogrification items you may need at the building west to the training dummies atop the hill.", 0, 8)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 9) then -- Class
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "All class trainers are present in the ground floor of the inn atop the hill.", 0, 10)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 10) then -- Flight/riding
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can both purchase the flight paths of the old world and train your riding skill at the medium floor of the inn atop the hill. If you wish to fly in the old world, visit the tent by the westernmost precipice to learn more.", 0, 10)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 11) then -- Pet
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "By the barn in the northwestern part of the hill above, you can access pet services such as renaming demon pets, purchasing beast master pets, and stabling your hunter pets.", 0, 10)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 12) then -- repair
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can repair your items on the top floor of the inn on the hill ahead, or in the blacksmithing guild on the northeasternmost part of the path.", 0, 12)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 13) then -- Enchanter
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can find a skilled Enchanter that can handle all your Enchantment needs at the westernmost building atop the hill ahead.", 0, 13)
       player:GossipMenuAddItem(0, "Go back", 0, 1)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 30) then -- alchemy etc
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Alchemy, Inscription and Herblaism trainers are present in the tower in the southern quadrant of the valley, south of the moonwell. You can also find raw materials, herbs, for these professions growing around the valley.", 0, 30)
       player:GossipMenuAddItem(0, "Go back", 0, 3)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 31) then -- mining etc
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "The earthern professions, Engineering, Blacksmithing, Jewelcrafting, and Mining are being served by the blacksmithing guild on the northeastern hill behind me. They have a forge for smelting, and access to minerals in both the mine next to it and in the mine digging into Yggdrasil's roots in the southwestern valley.", 0, 31)
       player:GossipMenuAddItem(0, "Go back", 0, 3)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 32) then -- enchanting and other unavailable services
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "This profession is not served here.", 0, 32)
       player:GossipMenuAddItem(0, "Go back", 0, 3)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 33) then -- enchanting and other unavailable services
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "At the northeastern part of the valley's river, there is a cooking and fishing camp. The camp serves these professions and offers a picnic area.", 0, 33)
       player:GossipMenuAddItem(0, "Go back", 0, 3)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 41) then -- Transmog items submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "Find both a transmogrifier and all the transmogrification items you may need at the building west to the training dummies atop the hill.", 0, 41)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 42) then -- Bartender submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "There are drinks served at the ground floor of the inn overlooking the hill and by the river underneath.", 0, 42)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 43) then -- Poison submenu 
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can purchase poison at the ground floor of the inn overlooking the hill.", 0, 43)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 44) then -- Flight paths submenu
       player:GossipClearMenu() 
       player:GossipMenuAddItem(0, "You can purchase flight paths at the medium floor of the inn overlooking the hill.", 0, 44)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 45) then -- Reagents submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can purchase reagents at the ground floor of the inn overlooking the hill.", 0, 45)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 46) then -- Heirlooms submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can purchase heirlooms in the inn overlooking the hill. The vendors are in the top story.", 0, 46)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 47) then -- Currency exchanger submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can exchange Yggdrasil currencies, including Vote Tokens, Community Tokens, and Activity Tokens, next to the auction house in the building just past the mall entrance gate.", 0, 47)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 48) then -- Guild submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can purchase guilds and guild services at the westernmost building atop the hill ahead.", 0, 48)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 49) then -- Beast master submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can purchase beast master hunter pets at the barn atop the hill ahead.", 0, 49)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
       
   elseif(intid == 50) then -- Professions submenu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "You can purchase Grandmaster professions at the westernmost building atop the hill ahead.", 0, 50)
       player:GossipMenuAddItem(0, "Go back", 0, 4)
       player:GossipSendMenu(12, creature)
   end
   
   if(intid == 0) then -- Do nothing for info texts
       player:GossipComplete()
   end
end

RegisterCreatureGossipEvent(110005, 1, OnGossipHello)
RegisterCreatureGossipEvent(110005, 2, OnGossipSelect)