/obj/structure/displaycase
	name = "display case"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "glassbox1"
	desc = "A display case for prized possessions. It taunts you to kick it."
	density = TRUE
	anchored = TRUE
	unacidable = 1//Dissolving the case would also delete the gun.
	var/health = 30
	var/occupied = 1
	var/destroyed = 0

/obj/structure/displaycase/ex_act(severity)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			new /obj/item/weapon/shard( src.loc )
			if (occupied)
				new /obj/item/weapon/gun/energy/laser/selfcharging/captain( src.loc )
				occupied = 0
			qdel(src)
			return
		if(EXPLODE_HEAVY)
			if(prob(50))
				src.health -= 15
		if(EXPLODE_LIGHT)
			if(prob(50))
				src.health -= 5
	healthcheck()


/obj/structure/displaycase/bullet_act(obj/item/projectile/Proj)
	health -= Proj.damage
	..()
	healthcheck()
	return


/obj/structure/displaycase/blob_act()
	if (prob(75))
		new /obj/item/weapon/shard( src.loc )
		if (occupied)
			new /obj/item/weapon/gun/energy/laser/selfcharging/captain( src.loc )
			occupied = 0
		qdel(src)

/obj/structure/displaycase/proc/healthcheck()
	if (src.health <= 0)
		if (!( src.destroyed ))
			src.density = FALSE
			src.destroyed = 1
			new /obj/item/weapon/shard( src.loc )
			playsound(src, pick(SOUNDIN_SHATTER), VOL_EFFECTS_MASTER)
			update_icon()
	else
		playsound(src, 'sound/effects/Glasshit.ogg', VOL_EFFECTS_MASTER)
	return

/obj/structure/displaycase/update_icon()
	if(src.destroyed)
		src.icon_state = "glassboxb[src.occupied]"
	else
		src.icon_state = "glassbox[src.occupied]"
	return


/obj/structure/displaycase/attackby(obj/item/weapon/W, mob/user)
	. = ..()
	if(!.)
		return FALSE

	health -= W.force
	healthcheck()

/obj/structure/displaycase/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/displaycase/attack_hand(mob/user)
	if (src.destroyed && src.occupied)
		new /obj/item/weapon/gun/energy/laser/selfcharging/captain( src.loc )
		to_chat(user, "<b>You deactivate the hover field built into the case.</b>")
		src.occupied = 0
		add_fingerprint(user)
		update_icon()
		return
	else
		user.SetNextMove(CLICK_CD_MELEE)
		visible_message("<span class='userdanger'>[user] kicks the display case.</span>")
		src.health -= 2
		healthcheck()
		return


