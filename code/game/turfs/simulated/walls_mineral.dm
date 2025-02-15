/turf/simulated/wall/mineral
	name = "mineral wall"
	desc = "This shouldn't exist."
	icon_state = "box"
	canSmoothWith = null
	smooth = SMOOTH_TRUE

/turf/simulated/wall/mineral/uranium
	name = "uranium wall"
	desc = "Стена с урановым покрытием. Наверное, это плохая идея."
	icon = 'icons/turf/walls/has_false_walls/uranium_wall.dmi'
	mineral = "uranium"
	sheet_type = /obj/item/stack/sheet/mineral/uranium
	canSmoothWith = list(/turf/simulated/wall/mineral/uranium, /obj/structure/falsewall/uranium)

	var/last_event = 0
	var/active = null

/turf/simulated/wall/mineral/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event + 15)
			active = 1
			for(var/mob/living/L in range(3, src))
				L.apply_effect(12, IRRADIATE, 0)
			for(var/turf/simulated/wall/mineral/uranium/T in range(3, src))
				T.radiate()
			last_event = world.time
			active = null

/turf/simulated/wall/mineral/uranium/attack_hand(mob/user)
	radiate()
	..()

/turf/simulated/wall/mineral/uranium/attackby(obj/item/weapon/W, mob/user)
	radiate()
	..()

/turf/simulated/wall/mineral/uranium/Bumped(AM)
	radiate()
	..()

/turf/simulated/wall/mineral/gold
	name = "gold wall"
	desc = "Стена с золотым покрытием. Оу-eeee!"
	icon = 'icons/turf/walls/has_false_walls/gold_wall.dmi'
	mineral = "gold"
	sheet_type = /obj/item/stack/sheet/mineral/gold
	canSmoothWith = list(/turf/simulated/wall/mineral/gold, /obj/structure/falsewall/gold)

/turf/simulated/wall/mineral/silver
	name = "silver wall"
	desc = "Стена с серебряным покрытием. Блестит!"
	icon = 'icons/turf/walls/has_false_walls/silver_wall.dmi'
	mineral = "silver"
	sheet_type = /obj/item/stack/sheet/mineral/silver
	canSmoothWith = list(/turf/simulated/wall/mineral/silver, /obj/structure/falsewall/silver)

/turf/simulated/wall/mineral/diamond
	name = "diamond wall"
	desc = "Стена с алмазным покрытием. Вы чудовище."
	icon = 'icons/turf/walls/has_false_walls/diamond_wall.dmi'
	mineral = "diamond"
	sheet_type = /obj/item/stack/sheet/mineral/diamond
	canSmoothWith = list(/turf/simulated/wall/mineral/diamond, /obj/structure/falsewall/diamond)

/turf/simulated/wall/mineral/bananium
	name = "bananium wall"
	desc = "Стена с бананиумовым покрытием. Хонк!"
	icon = 'icons/turf/walls/has_false_walls/bananium_wall.dmi'
	mineral = "bananium"
//	sheet_type = /obj/item/stack/sheet/mineral/bananium
	canSmoothWith = list(/turf/simulated/wall/mineral/bananium, /obj/structure/falsewall/bananium)

/turf/simulated/wall/mineral/sandstone
	name = "sandstone wall"
	desc = "Стена с песчаным покрытием."
	icon = 'icons/turf/walls/has_false_walls/sandstone_wall.dmi'
	mineral = "sandstone"
	sheet_type = /obj/item/stack/sheet/mineral/sandstone
	canSmoothWith = list(/turf/simulated/wall/mineral/sandstone, /obj/structure/falsewall/sandstone)



/turf/simulated/wall/mineral/phoron
	name = "phoron wall"
	desc = "Стена с фороновым покрытием. Определенно плохая идея."
	icon = 'icons/turf/walls/has_false_walls/phoron_wall.dmi'
	mineral = "phoron"
	sheet_type = /obj/item/stack/sheet/mineral/phoron
	canSmoothWith = list(/turf/simulated/wall/mineral/phoron, /obj/structure/falsewall/phoron)

/turf/simulated/wall/mineral/phoron/attackby(obj/item/weapon/W, mob/user)
	var/W_temp = W.get_current_temperature()
	if(W_temp > 300)//If the temperature of the object is over 300, then ignite
		ignite(W_temp)
		return
	..()

/turf/simulated/wall/mineral/phoron/proc/PhoronBurn(temperature)
	spawn(2)
	new /obj/structure/girder(src)
	ChangeTurf(/turf/simulated/floor)
	for(var/turf/simulated/floor/target_tile in range(0,src))
		/*if(target_tile.parent && target_tile.parent.group_processing)
			target_tile.parent.suspend_group_processing()*/
		target_tile.assume_gas("phoron", 20)
		target_tile.hotspot_expose(400 + T0C, 400)
	for(var/obj/structure/falsewall/phoron/F in range(3,src))//Hackish as fuck, but until temperature_expose works, there is nothing I can do -Sieve
		var/turf/T = get_turf(F)
		T.ChangeTurf(/turf/simulated/wall/mineral/phoron)
		qdel(F)
	for(var/turf/simulated/wall/mineral/phoron/W in range(3,src))
		W.ignite((temperature/4))//Added so that you can't set off a massive chain reaction with a small flame
	for(var/obj/machinery/door/airlock/phoron/D in range(3,src))
		D.ignite(temperature/4)

/turf/simulated/wall/mineral/phoron/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)//Doesn't fucking work because walls don't interact with air :(
	if(exposed_temperature > 300)
		PhoronBurn(exposed_temperature)

/turf/simulated/wall/mineral/phoron/proc/ignite(exposed_temperature)
	if(exposed_temperature > 300)
		PhoronBurn(exposed_temperature)

/turf/simulated/wall/mineral/phoron/bullet_act(obj/item/projectile/Proj)
	if(istype(Proj,/obj/item/projectile/beam))
		PhoronBurn(2500)
	else if(istype(Proj,/obj/item/projectile/ion))
		PhoronBurn(500)
	..()

/*
/turf/simulated/wall/mineral/proc/shock()
	if (electrocute_mob(user, C, src))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
		return 1
	else
		return 0

/turf/simulated/wall/mineral/proc/attackby(obj/item/weapon/W, mob/user)
	if((mineral == "gold") || (mineral == "silver"))
		if(shocked)
			shock()
*/
