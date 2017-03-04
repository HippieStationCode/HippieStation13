/obj/item/weapon/hockeypack
	name = "Ka-Nada Special Sport Forces Hockey Pack"
	desc = "Holds and powers a Ka-Nada SSF Hockey Stick, A devastating weapon capable of knocking men around like toys and batting objects at deadly velocities."
	icon = 'icons/obj/items.dmi'
	icon_state = "hockey_bag"
	item_state = "hockey_bag"
	w_class = 4
	slot_flags = SLOT_BACK
	flags = NODROP
	actions_types = list(/datum/action/item_action/toggle_stick)

	var/obj/item/weapon/twohanded/hockeystick/packstick
	var/on = 0
	var/volume = 500


/obj/item/weapon/hockeypack/New() //A lot of this is copied from how backpack watertanks work, ain't broke, don't fix.
	packstick = make_stick()

/obj/item/weapon/hockeypack/ui_action_click()
	toggle_stick()

/obj/item/weapon/hockeypack/verb/toggle_stick()
	set name = "Get stick"
	set category = "Object"
	if (usr.get_item_by_slot(usr.getHockeypackSlot()) != src)
		usr << "<span class='warning'>The pack must be worn properly to use!</span>"
		return
	if(usr.incapacitated())
		return
	on = !on

	var/mob/living/carbon/human/user = usr
	if(on)
		if(packstick == null)
			packstick = make_stick()

		if(!user.put_in_hands(packstick))
			on = 0
			user << "<span class='warning'>You need a free hand to hold the stick!</span>"
			return
		packstick.loc = user
	else
		remove_stick()
	return

/obj/item/weapon/hockeypack/proc/make_stick()
	return new /obj/item/weapon/twohanded/hockeystick(src)

/obj/item/weapon/hockeypack/equipped(mob/user, slot) //The Pack is cursed so this should not happen, but i'm going to play it safe.
	if (slot != slot_back)
		remove_stick()

/obj/item/weapon/hockeypack/proc/remove_stick()
	if(ismob(packstick.loc))
		var/mob/M = packstick.loc
		M.unEquip(packstick, 1)
	return

/obj/item/weapon/hockeypack/Destroy()
	if (on)
		packstick.unwield()
		remove_stick()
		qdel(packstick)
		packstick = null
	return ..()

/obj/item/weapon/hockeypack/attack_hand(mob/user)
	if(src.loc == user)
		ui_action_click()
		return
	..()

/obj/item/weapon/hockeypack/MouseDrop(obj/over_object)
	var/mob/M = src.loc
	if(istype(M) && istype(over_object, /obj/screen/inventory/hand))
		var/obj/screen/inventory/hand/H = over_object
		if(!M.temporarilyRemoveItemFromInventory(src))
			return
		M.put_in_hand(src, H.held_index)

/obj/item/weapon/hockeypack/attackby(obj/item/W, mob/user, params)
	if(W == packstick)
		remove_stick()
		return
	..()


/mob/proc/getHockeypackSlot()
	return slot_back



/obj/item/weapon/twohanded/hockeystick
	icon_state = "hockeystick0"
	name = "Ka-Nada SSF Hockey Stick"
	desc = "A Ka-Nada specification Power Stick designed after the implement of a violent sport, it is locked to and powered by the back mounted pack."
	force = 5
	w_class = 4
	//item_state = "hockey_stick"
	slot_flags = SLOT_BACK
	force_unwielded = 10
	force_wielded = 18 //Might seem a little weak but if the target hits a wall they take an extra 10 damage and get stunned.
	//special_throw = 1
	//specthrowsound = 'sound/weapons/resonator_blast.ogg'
	throwforce = 3
	throw_speed = 4
	flags = NODROP
	attack_verb = list("smacked", "thwacked", "bashed", "struck", "battered")
	//throwforce_mult = 1.4 //More powerful than a baseball bat because it costs 20 fucking tc and more or less denies you any ranged option.
	//specthrow_maxwclass = 4 //If you have the time to build a spear on the fly with no backpack to keep the bits in you deserve to be able to chuck it around freely.
	//specthrowmsg = "chipped"
	sharpness = IS_SHARP_ACCURATE //Very sharp to make up for the comparativly low damage.
	var/click_delay = 1.3

	var/obj/item/weapon/hockeypack/pack

/obj/item/weapon/twohanded/hockeystick/update_icon()
	icon_state = "hockeystick[wielded]"
	return

/obj/item/weapon/twohanded/hockeystick/New(parent_pack)
	..()
	if(check_pack_exists(parent_pack, src))
		pack = parent_pack
		loc = pack

	return


/obj/item/weapon/twohanded/hockeystick/attack(mob/living/target, mob/living/user) //Sure it's the powerfist code, right down to the sound effect. Gonna be fun though.

	if(!wielded)
		return ..()
	/*
	if(istype(target, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = target
		var/obj/item/organ/limb/affecting = H.get_organ(ran_zone(user.zone_sel.selecting))
		var/armor_block = H.run_armor_check(affecting, "melee")
		target.apply_damage(force, BRUTE, affecting, armor_block)
	else
	*/

	target.apply_damage(force, BRUTE)	//If it's a mob but not a humanoid, just give it plain brute damage.

	target.visible_message("<span class='danger'>[target.name] was pucked by [user] 'eh!</span>", \
		"<span class='userdanger'>You hear a loud crack 'eh!</span>", \
		"<span class='italics'>You hear the sound of bones crunching 'eh!</span>")

	var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))
	spawn(1)
		target.throw_at(throw_target, 10, 0.2)	//Throws the target 10 tiles

	playsound(loc, 'sound/weapons/resonator_blast.ogg', 50, 1)

	add_logs(user, target, "used a hockey stick on", src) //Very unlikeley non-antags are going to get their hands on this but just in case...

	user.changeNext_move(CLICK_CD_MELEE * click_delay)


	return

/obj/item/weapon/twohanded/hockeystick/dropped(mob/user) //The Stick is undroppable but just in case they lose an arm better put this here.
		..()
		user << "<span class='notice'>The stick is drawn back to the backpack 'eh!</span>"
		pack.on = 0
		loc = pack


/proc/check_pack_exists(parent_pack, mob/living/carbon/human/M, obj/O)
	if(!parent_pack || !istype(parent_pack, /obj/item/weapon/hockeypack))
		qdel(0)
		return 0
	else
		return 1

/obj/item/weapon/twohanded/hockeystick/Move()
	..()
	if(loc != pack.loc)
		loc = pack.loc

/obj/item/weapon/storage/belt/hockey
	name = "Holopuck Generator"
	desc = "A Belt mounted device that quickly fabricates hard-light holopucks that when thrown will stall and slow down foes dealing minor damage. Has a pouch to store a pair of spare pucks"
	icon_state = "hockey_belt"
	item_state = "hockey_belt"
	actions_types = list(/datum/action/item_action/produce_puck)
	storage_slots = 2
	flags = NODROP
	can_hold = list(/obj/item/holopuck)
	var/recharge_time = 100
	var/charged = 1
	var/timerid
	var/obj/item/holopuck/newpuck

/obj/item/weapon/storage/belt/hockey/ui_action_click()
	make_puck()

/obj/item/weapon/storage/belt/hockey/verb/make_puck()
	set name = "Produce Puck"
	set category = "Object"
	if (usr.get_item_by_slot(usr.getHockeybeltSlot()) != src)
		usr << "<span class='warning'>The belt must be worn properly to use!</span>"
		return
	if(usr.incapacitated())
		return

	var/mob/living/carbon/human/user = usr

	if(charged != 1)
		user << "<span class='warning'>The generator is still charging!</span>"
		return

	newpuck = build_puck()
	timerid = addtimer(src,"reset_puck",recharge_time)
	if(!user.put_in_hands(newpuck))
		user << "<span class='warning'>You need a free hand to hold the stick!</span>"
		return

	charged = 0

/obj/item/weapon/storage/belt/hockey/proc/build_puck()
	return new /obj/item/holopuck(src)

/mob/proc/getHockeybeltSlot()
	return slot_belt

/obj/item/weapon/storage/belt/hockey/proc/reset_puck()
	charged = 1
	var/mob/M = get(src, /mob)
	M << "<span class='notice'>The belt is now ready to fabricate another holopuck!</span>"


/obj/item/holopuck
	name = "HoloPuck"
	desc = "A small disk of hard light energy that's been electrically charged, will daze and damage a foe on impact."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "eshield0"
	item_state = "eshield0"
	w_class = 1
	stamina_percentage = 0.75
	force = 3
	throwforce = 30


/mob/living/carbon/human/hitby(atom/movable/PP, blocked = 0)
	..()
	if(blocked <= 0)
		if(istype(PP, /obj/item/holopuck))
			apply_effect(2, STUN)
			playsound(src, 'sound/effects/snap.ogg', 50, 1)
			visible_message("<span class='danger'>[src] has been dazed by a holopuck!</span>", \
											"<span class='userdanger'>[src] has been dazed by a holopuck!</span>")
			qdel(PP)

/obj/item/clothing/suit/armor/hockey
	name = "Ka-Nada winter sport combat suit"
	desc = "A suit of armour used by Ka-Nada Special Sport Forces teams. Protects you from the elements as well as your opponents."
	icon_state = "hockey_suit"
	item_state = "hockey_suit"
	blood_overlay_type = "armor"
	allowed = list(/obj/item/weapon/tank/internals/oxygen)
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	flags = THICKMATERIAL | NODROP | STOPSPRESSUREDMAGE
	armor = list(melee = 65, bullet = 75, laser = 60, energy = 45, bomb = 75, bio = 0, rad = 30)
	unacidable = 1

/obj/item/clothing/shoes/hockey
	name = "Ka-Nada Hyperblades"
	desc = "A pair of all terrain techno-skates, enabling a skilled skater to move freely and quickly."
	icon_state = "hockey_shoes"
	item_state = "hockey_shoes"
	flags = NODROP
	slowdown = -1

/obj/item/clothing/mask/gas/hockey
	name = "Ka-Nada Hokcey Mask"
	desc = "The iconic mask of the Ka-Nada special sports forces, guaranteed to strike terror into the hearts of men and goalies."
	icon_state = "hockey_mask"
	item_state = "hockey_mask"
	flags = BLOCK_GAS_SMOKE_EFFECT | MASKINTERNALS | NODROP

/obj/item/clothing/head/helmet/hockey
	name = "Ka-Nada winter sport combat helmet."
	desc = "A combat helmet used by Ka-Nada extreme environment teams. Protects you from the elements as well as your opponents."
	icon_state = "hockey_helmet"
	item_state = "hockey_helmet"
	armor = list(melee = 80, bullet = 60, laser = 50,energy = 25, bomb = 50, bio = 10, rad = 0, fire = 100, acid = 100)
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_HELM_MAX_TEMP_PROTECT
	flags = STOPSPRESSUREDMAGE | NODROP
