//Dummy object for holding items in vehicles.
//Prevents items from being interacted with.
/datum/vehicle_dummy_load
	var/name = "dummy load"
	var/actual_load

/obj/vehicle
	name = "vehicle"
	icon = 'icons/obj/vehicles.dmi'
	layer = MOB_LAYER + 0.1 //so it sits above objects including mobs
	density = TRUE
	anchored = TRUE
	animate_movement = 1
	light_range = 3

	can_buckle = 1
	buckle_movable = 1
	buckle_lying = 0

	w_class = SIZE_MASSIVE

	var/attack_log = null
	var/on = 0
	var/open = 0
	var/health = 0	//do not forget to set health for your vehicle!
	var/maxhealth = 0
	var/fire_dam_coeff = 1.0
	var/brute_dam_coeff = 1.0
	var/stat = 0
	var/move_delay = 1	//set this to limit the speed of the vehicle
	var/slow_cooef = 0

	var/atom/movable/load		//all vehicles can take a load, since they should all be a least drivable
	var/load_item_visible = 1	//set if the loaded item should be overlayed on the vehicle sprite
	var/load_offset_x = 0		//pixel_x offset for item overlay
	var/load_offset_y = 0		//pixel_y offset for item overlay
	var/mob_offset_y = 0		//pixel_y offset for mob overlay

//-------------------------------------------
// Standard procs
//-------------------------------------------
/obj/vehicle/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0)
	if(can_move())
		var/old_loc = get_turf(src)

		var/init_anc = anchored
		anchored = FALSE
		. = ..()
		if(!.)
			anchored = init_anc
			if(load && !istype(load, /datum/vehicle_dummy_load))
				load.set_dir(dir)
			return

		set_dir(get_dir(old_loc, loc))
		anchored = init_anc

		//Dummy loads do not have to be moved as they are just an overlay
		//See load_object() proc in cargo_trains.dm for an example
		if(load && !istype(load, /datum/vehicle_dummy_load))
			load.Move(loc, dir)

	else
		return FALSE

/obj/vehicle/proc/can_move()
	if(world.time <= l_move_time + move_delay)
		return 0
	if(!on)
		return 0
	if(isspaceturf(loc) && !istype(src, /obj/vehicle/space))
		return 0
	return 1

/obj/vehicle/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/weapon/hand_labeler))
		return
	else if(isscrewdriver(W))
		open = !open
		playsound(src, 'sound/items/Screwdriver.ogg', VOL_EFFECTS_MASTER)
		if(on && open)
			turn_off()
		update_icon()
		to_chat(user, "<span class='notice'>Maintenance panel is now [open ? "opened" : "closed"].</span>")
	else if(iswelder(W))
		var/obj/item/weapon/weldingtool/T = W
		user.SetNextMove(CLICK_CD_INTERACT)
		if(T.isOn())
			if(health < maxhealth)
				if(open)
					health = min(maxhealth, health + 20)
					playsound(src, 'sound/items/welder.ogg', VOL_EFFECTS_MASTER)
					user.visible_message("<span class='red'>[user] repairs \the [src]!</span>","<span class='notice'>You repair \the [src]!</span>")
					check_move_delay()
				else
					to_chat(user, "<span class='notice'>Unable to repair \the [src] with the maintenance panel closed.</span>")
			else
				to_chat(user, "<span class='notice'>[src] does not need a repair.</span>")
		else
			to_chat(user, "<span class='notice'>Unable to repair while [src] is off.</span>")
	else
		switch(W.damtype)
			if("fire")
				health -= W.force * fire_dam_coeff
			if("brute")
				health -= W.force * brute_dam_coeff
		healthcheck()
		return ..()

/obj/vehicle/bullet_act(obj/item/projectile/Proj)
	health -= Proj.damage
	..()
	healthcheck()

/obj/vehicle/blob_act()
	src.health -= rand(20,40)*fire_dam_coeff
	healthcheck()
	return

/obj/vehicle/ex_act(severity)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			explode()
			return
		if(EXPLODE_HEAVY)
			health -= rand(5,10)*fire_dam_coeff
			health -= rand(10,20)*brute_dam_coeff
		if(EXPLODE_LIGHT)
			if(prob(50))
				health -= rand(1,5)*fire_dam_coeff
				health -= rand(1,5)*brute_dam_coeff
	healthcheck()

/obj/vehicle/attack_ai(mob/user)
	return

/obj/vehicle/Process_Spacemove(direction)
	if(has_gravity(src))
		return 1

	if(pulledby)
		return 1

	return 0

/obj/vehicle/space/Process_Spacemove(direction)
	return 1
//-------------------------------------------
// Vehicle procs
//-------------------------------------------
/obj/vehicle/proc/turn_on()
	if(stat)
		return 0
	on = 1
	update_icon()
	return 1

/obj/vehicle/proc/turn_off()
	on = 0
	update_icon()

/obj/vehicle/proc/explode()
	visible_message("<span class='danger'>[src] blows apart!</span>")
	var/turf/Tsec = get_turf(src)

	new /obj/item/stack/rods(Tsec)
	new /obj/item/stack/rods(Tsec)
	new /obj/item/stack/cable_coil/red(Tsec, 2)

	//stuns people who are thrown off a train that has been blown up
	if(isliving(load))
		var/mob/living/M = load
		M.apply_effects(5, 5)

	unload()

	new /obj/effect/gibspawner/robot(Tsec)
	new /obj/effect/decal/cleanable/blood/oil(src.loc)

	qdel(src)

/obj/vehicle/proc/healthcheck()
	check_move_delay()
	if(health <= 0)
		explode()

/obj/vehicle/proc/RunOver(mob/living/carbon/human/H)
	return		//write specifics for different vehicles

//-------------------------------------------
// Loading/unloading procs
//
// Set specific item restriction checks in
// the vehicle load() definition before
// calling this parent proc.
//-------------------------------------------
/obj/vehicle/proc/load(atom/movable/C)
	//This loads objects onto the vehicle so they can still be interacted with.
	//Define allowed items for loading in specific vehicle definitions.
	if(!isturf(C.loc)) //To prevent loading things from someone's inventory, which wouldn't get handled properly.
		return 0
	if(load || C.anchored)
		return 0

	// if a create/closet, close before loading
	var/obj/structure/closet/crate = C
	if(istype(crate))
		crate.close()

	C.forceMove(loc)
	C.set_dir(dir)
	C.anchored = TRUE

	load = C

	if(load_item_visible)
		C.pixel_x += load_offset_x
		if(ismob(C))
			C.pixel_y += mob_offset_y
		else
			C.pixel_y += load_offset_y
		C.layer = layer + 0.1		//so it sits above the vehicle

	if(ismob(C))
		buckle_mob(C)

	return 1


/obj/vehicle/proc/unload(mob/user, direction)
	if(!load)
		return

	var/turf/dest = null

	//find a turf to unload to
	if(direction)	//if direction specified, unload in that direction
		dest = get_step(src, direction)
	else if(user)	//if a user has unloaded the vehicle, unload at their feet
		dest = get_turf(user)

	if(!dest)
		dest = get_step_to(src, get_step(src, turn(dir, 90))) //try unloading to the side of the vehicle first if neither of the above are present

	//if these all result in the same turf as the vehicle or nullspace, pick a new turf with open space
	if(!dest || dest == get_turf(src))
		var/list/options = new()
		for(var/test_dir in alldirs)
			var/new_dir = get_step_to(src, get_step(src, test_dir))
			if(new_dir && load.Adjacent(new_dir))
				options += new_dir
		if(options.len)
			dest = pick(options)
		else
			dest = get_turf(src)	//otherwise just dump it on the same turf as the vehicle

	if(!isturf(dest))	//if there still is nowhere to unload, cancel out since the vehicle is probably in nullspace
		return 0

	load.forceMove(dest)
	load.set_dir(get_dir(loc, dest))
	load.anchored = initial(load.anchored)
	load.pixel_x = initial(load.pixel_x)
	load.pixel_y = initial(load.pixel_y)
	load.layer = initial(load.layer)
	load.plane = initial(load.plane)

	load = null

	return 1

/obj/vehicle/proc/check_move_delay()
	var/health_procent = (health / maxhealth) * 100
	if(health_procent >= 66)
		slow_cooef = 0
		return
	if(health_procent >= 33)
		slow_cooef = 1
		return
	slow_cooef = 2
	return


//-------------------------------------------------------
// Stat update procs
//-------------------------------------------------------
/obj/vehicle/proc/update_stats()
	return

/obj/vehicle/attack_hand(mob/user, damage, attack_message)
	if(!damage)
		return
	user.SetNextMove(CLICK_CD_MELEE)
	visible_message("<span class='danger'>[user] [attack_message] the [src]!</span>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>attacked [src.name]</font>")
	src.health -= damage
	if(prob(10))
		new /obj/effect/decal/cleanable/blood/oil(src.loc)
	healthcheck()
	return 1
