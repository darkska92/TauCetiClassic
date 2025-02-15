
/**********************Ore box**************************/

/obj/structure/ore_box
	icon = 'icons/obj/mining.dmi'
	icon_state = "orebox0"
	name = "Ore Box"
	desc = "A heavy box used for storing ore."
	density = TRUE
	var/last_update = 0
	var/list/stored_ore = list()

/obj/structure/ore_box/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/weapon/ore))
		user.drop_from_inventory(W, src)
	else if(istype(W, /obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = W
		user.SetNextMove(CLICK_CD_INTERACT)
		for(var/obj/item/weapon/ore/O in S.contents)
			S.remove_from_storage(O, src) //This will move the item to this item's contents
		to_chat(user, "<span class='notice'>You empty the satchel into the box.</span>")
	return

/obj/structure/ore_box/Entered(atom/movable/ORE)
	if(istype(ORE, /obj/item/weapon/ore))
		stored_ore[ORE.name]++

/obj/structure/ore_box/Exited(atom/movable/ORE)
	if(istype(ORE, /obj/item/weapon/ore))
		stored_ore[ORE.name]--
	if(!contents.len)
		stored_ore = list()

/obj/structure/ore_box/attack_hand(mob/user)
	var/dat = ""
	for(var/ore in stored_ore)
		dat += "[ore]: [stored_ore[ore]]<br>"

	dat += "<br><br><A href='?src=\ref[src];removeall=1'>Empty box</A>"

	var/datum/browser/popup = new(user, "orebox", "The contents of the ore box reveal...")
	popup.set_content(dat)
	popup.open()

	return

/obj/structure/ore_box/examine(mob/user)
	..()

	// Borgs can now check contents too.
	if((!ishuman(user)) && (!isrobot(user)))
		return

	if(!Adjacent(user)) //Can only check the contents of ore boxes if you can physically reach them.
		return

	add_fingerprint(user)

	if(!contents.len)
		to_chat(user, "It is empty.")
		return

	to_chat(user, "It holds:")
	for(var/ore in stored_ore)
		to_chat(user, "- [stored_ore[ore]] [ore]")
	return

/obj/structure/ore_box/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	add_fingerprint(usr)
	if(href_list["removeall"])
		for (var/obj/item/weapon/ore/O in contents)
			O.Move(src.loc)
		to_chat(usr, "<span class='notice'>You empty the box</span>")
	updateUsrDialog()
	return

/obj/structure/ore_box/verb/empty_box()
	set name = "Empty Ore Box"
	set category = "Object"
	set src in view(1)

	if(!ishuman(usr)) //Only living, intelligent creatures with hands can empty ore boxes.
		to_chat(usr, "<span class='warning'>You are physically incapable of emptying the ore box.</span>")
		return

	if(usr.incapacitated())
		return

	if(!Adjacent(usr)) //You can only empty the box if you can physically reach it
		to_chat(usr, "You cannot reach the ore box.")
		return

	add_fingerprint(usr)

	if(contents.len < 1)
		to_chat(usr, "<span class='warning'>The ore box is empty</span>")
		return

	for (var/obj/item/weapon/ore/O in contents)
		O.Move(src.loc)

	to_chat(usr, "<span class='notice'>You empty the ore box</span>")

	return
