/mob/living/silicon/robot/gib()
	//robots don't die when gibbed. instead they drop their MMI'd brain
	var/atom/movable/overlay/animation = null
	notransform = TRUE
	canmove = 0
	icon = null
	invisibility = 101

	animation = new(loc)
	animation.icon_state = "blank"
	animation.icon = 'icons/mob/mob.dmi'
	animation.master = src

	flick("gibbed-r", animation)
	robogibs(loc, viruses)

	alive_mob_list -= src
	dead_mob_list -= src
	spawn(15)
		if(animation)	qdel(animation)
		if(src)			qdel(src)

/mob/living/silicon/robot/dust()
	dust_process()
	new /obj/effect/decal/cleanable/ash(loc)
	new /obj/effect/decal/remains/robot(loc)
	if(mmi)		qdel(mmi)	//Delete the MMI first so that it won't go popping out.
	dead_mob_list -= src

/mob/living/silicon/robot/death(gibbed)
	if(stat == DEAD)	return
	if(!gibbed)
		emote("deathgasp")
	stat = DEAD

	if(module)
		for(var/obj/item/I in module)
			SEND_SIGNAL(I, COMSIG_HAND_DROP_ITEM, null, src)

	update_canmove()
	if(camera)
		camera.status = 0

	update_sight()
	updateicon()

	tod = worldtime2text() //weasellos time of death patch
	if(mind)	mind.store_memory("Time of death: [tod]", 0)

	sql_report_cyborg_death(src)
	SSStatistics.add_death_stat(src)

	return ..(gibbed)
