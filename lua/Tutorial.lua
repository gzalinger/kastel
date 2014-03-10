--everything (non-UI) related to the tutorial level

Tutorial = {}
Tutorial.__index = Tutorial


function Tutorial.create()
	--create a new instance of tutorial every time you start a tutorial level
	local temp = {}
	setmetatable(temp, Tutorial)
	--define all steps:
	temp.steps = {}
	temp.currentStep = 1
	temp.steps[1] = {text = "Welcome to the Kastel tutorial! This panel will give you instructions on how to play. Press 'proceed' to move on to the next step when you're ready (you'll always be able to navigate back to old instructions.", triggerType = "manual"}
	temp.steps[2] = {text = "Unfortunately, this is a low-tech tutorial. If you deviate from the directions (e.g. build the wrong structure) you'll probably never get back on track. In this case you'd have to quit (press 'q') and start over.", triggerType = "manual"}
	temp.steps[3] = {text = "Let's start with some \"camera\" controls. You can navigate around the map using the arrow keys.", triggerType = "manual"}
	temp.steps[4] = {text = "You can zoom in or out with the \"+\" and \"-\" keys or the mouse wheel. More details are shown when you're zoomed in. Use different zoom levels to survey the whole battle or focus on a single melee.", triggerType = "manual"}
	temp.steps[5] = {text = "To see more information (such as health bars) at any zoom level, hold the \"tab\" key.", triggerType = "manual"}
	temp.steps[6] = {text = "The UI might seem intimidating at first, but don't worry. Along the top of the screen is important information about your resources, population, and current wave. That will all start to make sense as we go.", triggerType = "manual"}
	temp.steps[7] = {text = "The bottom of the UI shows information about your curent selection (more on that in a moment). The palette to your right is where you will build new structures, towers, and walls.", triggerType = "manual"}
	temp.steps[8] = {text = "You can select tiles by clicking on them (\"tiles\" are the hexagons that make up the map). Selecting a tile will display information about the structure there and give you access to structure-specific controls.", triggerType = "manual"}
	temp.steps[9] = {text = "Your realm is made up of the city and it's surrounding village.", triggerType = "manual"}
	temp.steps[10] = {text = "The city is represented by blue structures. It can be heavily defended by walls and towers and contains your most important structures.", triggerType = "manual"}
	temp.steps[11] = {text = "At the center of your city is the \"Town Hall\". If this is ever destroyed, you lose. Later, you'll upgrade the Town Hall in order to unlock more advanced structures.", triggerType = "manual"}
	temp.steps[12] = {text = "Outside the city limits lies the \"village\", represented by brown structures. Your village and the peasants who live there are your economic engine and produce the raw materials you need to expand your realm.", triggerType = "manual"}
	temp.steps[13] = {text = "However, without the protection of your city walls the village is very vulnerable.", triggerType = "manual"}
	temp.steps[14] = {text = "Next, let's build our first structure.", triggerType = "manual"}
	temp.steps[15] = {text = "We're going to build a \"woodlot\", a village structure that produces timber. Timber is a vital resource, especially for expanding your village.", triggerType = "manual"}
	temp.steps[16] = {text = "First, click the brown house on the build palette that's along the right side of your screen. This will open the palette of village structures.", triggerType = "manual"}
	temp.steps[17] = {text = "Click the woodlot button, then click a tile to build the new structure there. Village structures must be placed next to existing structures and cannot be built on roads (the tan-colored tiles).", triggerType = "manual"}
	temp.steps[18] = {text = "You should now have a new woodlot! Village structures are completed as soon as they're placed; this is not true of city structures, as we'll see later on.", triggerType = "manual"}
	temp.steps[19] = {text = "Next, let's talk about your peasant workforce.", triggerType = "manual"}
	temp.steps[20] = {text = "Your village has a labor pool of peasants who work at structures like woodlots, quarries, and farms. Without workers, these structures won't produce resources.", triggerType = "manual"}
	temp.steps[21] = {text = "Peasants live at hamlets. As your peasant population grows, you'll need to build or upgrade hamlets to accomodate them.", triggerType = "manual"}
	temp.steps[22] = {text = "If you select your hamlet, you can see how many peasants live there in the bottom-left panel. You can also see your total peasant population in the top-left.", triggerType = "manual"}
	temp.steps[23] = {text = "Your peasants are currently working at the only structure they can; your woodlot.", triggerType = "manual"}
	temp.steps[24] = {text = "If you select or zoom in on your woodlot, you'll see three blue circles. These represent the woodlot's \"employee slots\". When a slot is filled by an employee, it will be blue. The more employees at a woodlot, the faster it will produce timber.", triggerType = "manual"}
	temp.steps[25] = {text = "In the bottom-right of the screen are the employee controls. You'll use these to distribute workers where you want them once you have more structures.", triggerType = "manual"}
	temp.steps[26] = {text = "Peasants are the key to your economy and are one of your most valuable resources. They are also very vulnerable to raiders; protect them well.", triggerType = "manual"}
	temp.steps[27] = {text = "Next, we'll build another village structure: the farm", triggerType = "manual"}
	temp.steps[28] = {text = "Follow the same steps as you did with the woodlot, but keep in mind that farms must be built next to hamlets.", triggerType = "manual"}
	temp.steps[29] = {text = "Farms can produce either wheat or bread. For now, ours will produce wheat. Wheat is stored and used to feed peasants during the winter (more on that later).", triggerType = "manual"}
	temp.steps[30] = {text = "Select the farm. See how not all it's employee slots are filled? This is because you don't have enough peasants to work at both your woodlot and farm. Play around with the employee controls to redistribute your workers.", triggerType = "manual"}
	temp.steps[31] = {text = "Now, let's build our first new city structure.", triggerType = "manual"}
	temp.steps[32] = {text = "Click the blue structure button on the build palette, then select the \"Granary\". City structure must be placed next to other city structures; there can't be village structures between them.", triggerType = "manual"}
	temp.steps[33] = {text = "The \"hammer and saw\" icon over your granary means it's still under construction. Unlike village structures, most city structures require more than one wave to finish. It's important to anticipate your need for city structures and start them ahead of time.", triggerType = "manual"}
	temp.steps[34] = {text = "Speaking of which, we're going to start building some more city structures we'll need soon.", triggerType = "manual"}
	temp.steps[35] = {text = "But first, we'll need to build more housing for our city residents.", triggerType = "manual"}
	temp.steps[36] = {text = "In addition to gold, timber, and stone, city structures require \"population\" in order to be built. Population represents skilled laborers who live inside the city's walls.", triggerType = "manual"}
	temp.steps[37] = {text = "Population is created by building \"house\" structures. A house gives you additional population when it's first built; it doesn't produce more over time like the resources made in the village.", triggerType = "manual"}
	temp.steps[38] = {text = "Now construct a \"Warehouse\" and \"Shelter\". These structures are critical for preparing for winter. More on that later.", triggerType = "manual"}
	temp.steps[39] = {text = "Next we'll build our first tower.", triggerType = "manual"}
	temp.steps[40] = {text = "Towers are the workhorses of your defense. They fire projectiles at monsters as they approach and can put out fearsome amounts of damage, especially once they've been upgraded.", triggerType = "manual"}
	temp.steps[41] = {text = "Click the blue tower button on the build palette, then select the archer tower. As you place it, you'll see that towers are built on the corner of tiles, instead of on the tiles themselves.", triggerType = "manual"}
	temp.steps[42] = {text = "Towers can be built on any outside corner of your city, but not in the village. This is a big part of why the city is better defended than the village is. That said, our village is small enough that this one towers can protect everything.", triggerType = "manual"}
	temp.steps[43] = {text = "Now that our realm is prepared, we'll start our first \"defend\" phase.", triggerType = "manual"}
	temp.steps[44] = {text = "During the defend phase you don't build new structures. Instead, your realm will be attacked by monsters hoping to tear down your city and murder your people.", triggerType = "manual"}
	temp.steps[45] = {text = "On later levels, you'll control your own troops and spells during the defend phase but for now you'll sit back and watch how well your defenses work.", triggerType = "manual"}
	temp.steps[46] = {text = "To start the defend phase, click the \"End Build Phase\" button on the bottom-left of the map.", triggerType = "manual"}
	temp.steps[47] = {text = "You can see monsters moving towards your city and your tower attacking them automatically. Hold \"tab\" to see the monsters' health bars.", triggerType = "manual"}
	temp.steps[48] = {text = "The defend phase is also when the village produces resources. The numbers that appear above village structures represent resources being deposited into your treasury.", triggerType = "manual"}
	temp.steps[49] = {text = "After your defenses have killed all the attackers, you will move on to the next build phase.", triggerType = "manual"}
	temp.steps[50] = {text = "At the top of the screen, you can see that the indicator has moved to wave two. That part of the UI shows you how close you are to completing a level and represents different seasons with different colors.", triggerType = "manual"}
	temp.steps[51] = {text = "As you can see, your new city structures have been completed.", triggerType = "manual"}
	temp.steps[52] = {text = "Granaries store wheat for the winter. It's important to have enough granaries to store the wheat you produce during the summer. Without enough stored wheat, peasants will starve during the winter.", triggerType = "manual"}
	temp.steps[53] = {text = "The shelter provides a place for peasants to live during the winter. Together with wheat in granaries, shelters allow your peasant population to carry over between summers while the village is gone.", triggerType = "manual"}
	temp.steps[54] = {text = "Warehouses store the peasants' belongings while they're sheltering for winter. Village structures can be put into storage for a small fee, then rebuilt for free when the snow melts. This process is critical for keeping an economy rolling.", triggerType = "manual"}
	temp.steps[55] = {text = "Those three structures constitute your economic preparation for winter. Even while building defenses and economy, never neglect these structures.", triggerType = "manual"}
	temp.steps[56] = {text = "With our preparations complete, we'll begin the last defend phase before winter.", triggerType = "manual"}
	temp.steps[57] = {text = "Attacks will come from all sides. Red flags indicate where monsters will spawn during the next wave. Be sure to prepare your defenses accordingly.", triggerType = "manual"}
	temp.steps[58] = {text = "Now that you've survived the last defend phase of summer it's time for the \"autumn\" phase.", triggerType = "manual"}
	temp.steps[59] = {text = "During autumn you transition from summer into winter by deconstructing the village.", triggerType = "manual"}
	temp.steps[60] = {text = "During the harsh and dangerous winter, peasants abandon their village and shelter inside the city, eating the wheat you've stored.", triggerType = "manual"}
	temp.steps[61] = {text = "This means you will not have the income from village structures and must rely on resources you've saved. To compensate, your gold income will be much higher during the winter.", triggerType = "manual"}
	temp.steps[62] = {text = "Although the village will disappear during the winter, it's not entirerly lost. Instead, village structures can be stored inside warehouses and rebuilt in the spring.", triggerType = "manual"}
	temp.steps[63] = {text = "During the autumn phase, you select the village structures you want stored. It is much cheaper to store structures than rebuild them and allows you to quickly restart your economy next summer.", triggerType = "manual"}
	temp.steps[64] = {text = "Once you've highlighted your village structures, press the \"End Autumn\" button.", triggerType = "manual"}
	temp.steps[65] = {text = "Winter build phases require a different focus than summer ones.", triggerType = "manual"}
	temp.steps[66] = {text = "Instead of expanding your village, you will concentrate on shoring up your city's defenses. This is also when you'll have the opportunity to repair structures damaged in previous attacks.", triggerType = "manual"}
	temp.steps[67] = {text = "Attacks during the winter are much more powerful.", triggerType = "manual"}
	temp.steps[68] = {text = "Although you have no fragile village to protect, the monsters you'll face during the winter will threaten your city itself, despite it's walls and towers.", triggerType = "manual"}
	temp.steps[69] = {text = "To ensure you're adequately prepared, build another house and a second archer tower.", triggerType = "manual"}
	temp.steps[70] = {text = "Now let's begin the defend phase.", triggerType = "manual"}
	temp.steps[71] = {text = "During the winter, you'll face many of the same monsters as the summer but in much greater numbers.", triggerType = "manual"}
	temp.steps[72] = {text = "With winter over, it's time for the \"spring\" phase.", triggerType = "manual"}
	temp.steps[73] = {text = "Like autumn, spring serves as a transition between seasons.", triggerType = "manual"}
	temp.steps[74] = {text = "During the spring, you rebuild your village using the structures you stored last autumn.", triggerType = "manual"}
	temp.steps[75] = {text = "Select the icons representing your stored structures on the right, then place them around your city.", triggerType = "manual"}
	temp.steps[76] = {text = "During this summer, we'll complete our village and city.", triggerType = "manual"}
	temp.steps[77] = {text = "First, build another farm.", triggerType = "manual"}
	temp.steps[78] = {text = "Select your new farm and switch it to bread production using the button in the lower-right portion of the screen.", triggerType = "manual"}
	temp.steps[79] = {text = "Farms can produce one of two things: wheat to be stored during the winter or bread to help grow your peasant population.", triggerType = "manual"}
	temp.steps[80] = {text = "New peasants are produced at hamlets, fueled by bread from adjacent farms. Selecting a hamlet to see progress towards new citizens. More bread means faster growth, but only to a point. Upgraded hamlets can accept more total bread.", triggerType = "manual"}
	temp.steps[81] = {text = "As you know by now, peasants are extremely important and always in short supply.", triggerType = "manual"}
	temp.steps[82] = {text = "With the village squared away, let's start preparing new defenses for next winter.", triggerType = "manual"}
	temp.steps[83] = {text = "Before we proceed, you'll need to build another house.", triggerType = "manual"}
	temp.steps[84] = {text = "First, we're going to build a barracks, but don't place it yet!", triggerType = "manual"}
	temp.steps[85] = {text = "City structures, such as your new barracks, can be built over existing village structures. When you do this, you can either lose the village structure but recieve some recycled resources, or choose to relocate the village structure for a small fee.", triggerType = "manual"}
	temp.steps[86] = {text = "Try relocating one of your structures by building over it now.", triggerType = "manual"}
	temp.steps[87] = {text = "Next, we'll build a gatehouse; a unique structure vital to your defenses.", triggerType = "manual"}
	temp.steps[88] = {text = "As you go to place the gatehouse, you'll see that the gate will occupy one of the structure's edges. Press \"r\" to rotate which edge the gate is on.", triggerType = "manual"}
	temp.steps[89] = {text = "The gatehouse is the only structure that can be built on roads, making them indispensable when expanding your city around a roadway.", triggerType = "manual"}
	temp.steps[90] = {text = "Gates act as a wall that can keep monsters at bay but can be opened to allow your regiments to exit and take the fight to the field.", triggerType = "manual"}
	temp.steps[91] = {text = "With those structures placed, end the build phase.", triggerType = "manual"}
	temp.steps[92] = {text = "One of the most dangerous threats you'll face is \"murdering monsters\".", triggerType = "manual"}
	temp.steps[93] = {text = "While normal monsters try to destroy structures, murdering monsters directly attack peasants. Even a few of these foes can cripple your economy very quickly.", triggerType = "manual"}
	temp.steps[94] = {text = "In order to counter this threat, we'll construct some peasant defenses.", triggerType = "manual"}
	temp.steps[95] = {text = "Village towers are placed on corners like city towers, but must be located away from tiles with city structures. Unlike village structures, they cannot be stored during the winter.", triggerType = "manual"}
	temp.steps[96] = {text = "The first village defense we'll build is the \"trapper\".", triggerType = "manual"}
	temp.steps[97] = {text = "This tower springs traps on monsters moving nearby, temporarily immobilizing them. This gives your towers time to finish them off and your troops time to get in position.", triggerType = "manual"}
	temp.steps[98] = {text = "Next, build a \"Militia HQ\".", triggerType = "manual"}
	temp.steps[99] = {text = "The militia HQ allows you to \"call up\" militia regiments at adjacent structures. This converts peasant employees into fighting regiments. When the threat has passed, you can disband the militia at their home structure to send the peasants back to work.", triggerType = "manual"}
	temp.steps[100] = {text = "Finally, build a quarry.", triggerType = "manual"}
	temp.steps[101] = {text = "The quarry is another economic structure that produces stone, very similar to the woodlot.", triggerType = "manual"}
	temp.steps[102] = {text = "While timber is used to build the village and low-tech structures, stone is used for powerful defenses and high-tech city structures.", triggerType = "manual"}
	temp.steps[103] = {text = "Your gatehouse has finished building.", triggerType = "manual"}
	temp.steps[104] = {text = "Select the gatehouse and you'll be able to open and close the gate during the defend phase. Use the button in the lower-right or press \"space\".", triggerType = "manual"}
	temp.steps[105] = {text = "Our village construction is now complete; end the build phase.", triggerType = "manual"}
	temp.steps[106] = {text = "During this defend phase, try using your new peasant defenses.", triggerType = "manual"}
	temp.steps[107] = {text = "This autumn is merely a formality because there are no more summer waves on this level.", triggerType = "manual"}	
	temp.steps[108] = {text = "Construction on your barracks has finally finished.", triggerType = "manual"}
	temp.steps[109] = {text = "Barracks are home to the powerful Footmen regiment. Now that you have a barracks, you'll have a regiment of footmen to control during the defend phase.", triggerType = "manual"}
	temp.steps[110] = {text = "Footmen are a powerful melee unit that's more than a match for goblins. Their mobility allows you to re-position them to meet new and emerging threats.", triggerType = "manual"}
	temp.steps[111] = {text = "Your regiment can replace a few losses each wave, but it can we worn down if it takes heavy casaulties.", triggerType = "manual"}
	temp.steps[112] = {text = "By changing the barracks' rally point, you can control where your footmen regiment will start the next defend phase.", triggerType = "manual"}
	temp.steps[113] = {text = "You can increase the size of your regiment at the barracks. Other upgrades for regiments (such as attack and defense improvements) are available at other structures such as the armory.", triggerType = "manual"}
	temp.steps[114] = {text = "Now, start the final defend phase and use your new footmen to help defend your realm.", triggerType = "manual"}
	temp.steps[115] = {text = "That completes the tutorial! More structures, defenses, and -of course- dangerous monsters will be avaiable in other levels.", triggerType = "manual"}
	return temp
end

-- ====================================================

function Tutorial:trigger(triggerType, triggerData)
	local step = self:getCurrentStep()
	if step.triggerType ~= triggerType then
		return false
	end
	self.currentStep = self.currentStep + 1
	if self.currentStep > #self.steps then
		currentGame.tutorial = nil
	end
	--todo: look at trigger data
	return true
end

-- ====================================================

function Tutorial:getCurrentStep()
	return self.steps[self.currentStep]
end

-- ====================================================