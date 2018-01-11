/* Tables and Racks
 * Contains:
 *		Tables
 *		Glass Tables
 *		Wooden Tables
 *		Reinforced Tables
 *		Racks
 *		Rack Parts
 */

/*
 * Tables
 */

/obj/structure/table
	name = "table"
	desc = "A square piece of metal standing on four metal legs. It can not move."
	icon = 'icons/obj/smooth_structures/table.dmi'
	icon_state = "table"
	density = TRUE
	anchored = TRUE
	layer = TABLE_LAYER
	pass_flags = LETPASSTHROW
	climbable = TRUE
	max_integrity = 100
	integrity_failure = 30
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/table, /obj/structure/table/reinforced)
	var/frame = /obj/structure/table_frame
	var/framestack = /obj/item/stack/rods
	var/buildstack = /obj/item/stack/sheet/metal
	var/busy = FALSE
	var/buildstackamount = 1
	var/framestackamount = 2
	var/deconstruction_ready = TRUE
	var/flipped = 0

/obj/structure/table/New()
	..()
	if(flipped)
		update_icon()

/obj/structure/table/examine(mob/user)
	..()
	deconstruction_hints(user)

/obj/structure/table/proc/deconstruction_hints(mob/user)
	to_chat(user, "<span class='notice'>The top is <b>screwed</b> on, but the main <b>bolts</b> are also visible.</span>")

/obj/structure/table/update_icon()
	if(smooth && !flipped)
		icon_state = ""
		smooth_icon(src)
		smooth_icon_neighbors(src)

	if(flipped)
		clear_smooth_overlays()

		var/type = 0
		var/subtype = null
		for(var/direction in list(turn(dir,90), turn(dir,-90)) )
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
			if(T && T.flipped)
				type++
				if(type == 1)
					subtype = direction == turn(dir,90) ? "-" : "+"
		var/base = "table"
		if(istype(src, /obj/structure/table/wood))
			base = "wood"
		if(istype(src, /obj/structure/table/reinforced))
			base = "rtable"

		icon_state = "[base]flip[type][type == 1 ? subtype : ""]"

		return 1

/obj/structure/table/narsie_act()
	new /obj/structure/table/wood(loc)
	qdel(src)

/obj/structure/table/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
			return
		if(2)
			if(prob(50))
				qdel(src)
				return
		if(3)
			if(prob(25))
				deconstruct(FALSE)
		else
	return

/obj/structure/table/blob_act()
	if(prob(75))
		qdel(src)

/obj/structure/table/attack_alien(mob/living/user)
	user.do_attack_animation(src)
	playsound(loc, 'sound/weapons/bladeslice.ogg', 50, 1)
	visible_message("<span class='danger'>[user] slices [src] apart!</span>")
	deconstruct(FALSE)

/obj/structure/table/mech_melee_attack(obj/mecha/M)
	visible_message("<span class='danger'>[M] smashes [src] apart!</span>")
	deconstruct(FALSE)

/obj/structure/table/attack_animal(mob/living/simple_animal/user)
	if(user.environment_smash)
		user.do_attack_animation(src)
		playsound(loc, 'sound/weapons/Genhit.ogg', 50, 1)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		deconstruct(FALSE)

/obj/structure/table/attack_hand(mob/living/user)
	if(HULK in user.mutations)
		user.do_attack_animation(src)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		playsound(loc, 'sound/effects/bang.ogg', 50, 1)
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		deconstruct(FALSE)
	else
		..()
	if(climber)
		climber.Weaken(2)
		climber.visible_message("<span class='warning'>[climber.name] has been knocked off the table", "You've been knocked off the table", "You see [climber.name] get knocked off the table</span>")

/obj/structure/table/attack_tk() // no telehulk sorry
	return

/obj/structure/table/CanPass(atom/movable/mover, turf/target, height=0)
	if(height == 0)
		return 1
	if(istype(mover,/obj/item/projectile))
		return (check_cover(mover,target))
	if(ismob(mover))
		var/mob/M = mover
		if(M.flying)
			return 1
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	if(mover.throwing)
		return 1
	if(locate(/obj/structure/table) in get_turf(mover))
		return 1
	if(flipped)
		if(get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 0

/obj/structure/table/CanAStarPass(ID, dir, caller)
	. = !density
	if(ismovableatom(caller))
		var/atom/movable/mover = caller
		. = . || mover.checkpass(PASSTABLE)

//checks if projectile 'P' from turf 'from' can hit whatever is behind the table. Returns 1 if it can, 0 if bullet stops.
/obj/structure/table/proc/check_cover(obj/item/projectile/P, turf/from)
	var/turf/cover = flipped ? get_turf(src) : get_step(loc, get_dir(from, loc))
	if(get_dist(P.starting, loc) <= 1) //Tables won't help you if people are THIS close
		return 1
	if(get_turf(P.original) == cover)
		var/chance = 20
		if(ismob(P.original))
			var/mob/M = P.original
			if(M.lying)
				chance += 20				//Lying down lets you catch less bullets
		if(flipped)
			if(get_dir(loc, from) == dir)	//Flipped tables catch mroe bullets
				chance += 20
			else
				return 1					//But only from one side
		if(prob(chance))
			obj_integrity -= P.damage/2
			if(obj_integrity > 0)
				visible_message("<span class='warning'>[P] hits \the [src]!</span>")
				return 0
			else
				visible_message("<span class='warning'>[src] breaks down!</span>")
				deconstruct(FALSE)
				return 1
	return 1

/obj/structure/table/CheckExit(atom/movable/O, turf/target)
	if(istype(O) && O.checkpass(PASSTABLE))
		return 1
	if(flipped)
		if(get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 1

/obj/structure/table/MouseDrop_T(obj/O, mob/user)
	..()
	if((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return
	if(isrobot(user))
		return
	if(!user.drop_item())
		return
	if(O.loc != src.loc)
		step(O, get_dir(O, src))
	return

/obj/structure/table/proc/tablepush(obj/item/I, mob/user)
	if(get_dist(src, user) < 2)
		var/obj/item/weapon/grab/G = I
		if(G.affecting.buckled)
			to_chat(user, "<span class='warning'>[G.affecting] is buckled to [G.affecting.buckled]!</span>")
			return 0
		if(G.state < GRAB_AGGRESSIVE)
			to_chat(user, "<span class='warning'>You need a better grip to do that!</span>")
			return 0
		if(!G.confirm())
			return 0
		G.affecting.forceMove(get_turf(src))
		G.affecting.Weaken(2)
		G.affecting.visible_message("<span class='danger'>[G.assailant] pushes [G.affecting] onto [src].</span>", \
									"<span class='userdanger'>[G.assailant] pushes [G.affecting] onto [src].</span>")
		add_logs(G.assailant, G.affecting, "pushed onto a table")
		qdel(I)
		return 1
	qdel(I)

/obj/structure/table/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/grab))
		tablepush(I, user)
		return
	if(can_deconstruct)
		if(isscrewdriver(I) && deconstruction_ready)
			to_chat(user, "<span class='notice'>You start disassembling [src]...</span>")
			playsound(loc, I.usesound, 50, 1)
			if(do_after(user, 20*I.toolspeed, target = src))
				deconstruct(TRUE)
			return

		if(iswrench(I) && deconstruction_ready)
			to_chat(user, "<span class='notice'>You start deconstructing [src]...</span>")
			playsound(loc, I.usesound, 50, 1)
			if(do_after(user, 40*I.toolspeed, target = src))
				playsound(loc, 'sound/items/deconstruct.ogg', 50, 1)
				deconstruct(TRUE, 1)
			return

	if(isrobot(user))
		return

	if(istype(I, /obj/item/weapon/melee/energy/blade))
		var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
		spark_system.set_up(5, 0, loc)
		spark_system.start()
		playsound(loc, I.usesound, 50, 1)
		playsound(loc, "sparks", 50, 1)
		for(var/mob/O in viewers(user, 4))
			O.show_message("<span class='notice'>The [src] was sliced apart by [user]!</span>", 1, "<span class='warning'>You hear [src] coming apart.</span>", 2)
		deconstruct(FALSE)
		return

	if(!(I.flags & ABSTRACT))
		if(user.drop_item())
			I.Move(loc)
			var/list/click_params = params2list(params)
			//Center the icon where the user clicked.
			if(!click_params || !click_params["icon-x"] || !click_params["icon-y"])
				return
			//Clamp it so that the icon never moves more than 16 pixels in either direction (thus leaving the table turf)
			I.pixel_x = Clamp(text2num(click_params["icon-x"]) - 16, -(world.icon_size/2), world.icon_size/2)
			I.pixel_y = Clamp(text2num(click_params["icon-y"]) - 16, -(world.icon_size/2), world.icon_size/2)

	return

/obj/structure/table/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(can_deconstruct)
		var/turf/T = get_turf(src)
		new buildstack(T, buildstackamount)
		if(!wrench_disassembly)
			new frame(T)
		else
			new framestack(T, framestackamount)
	qdel(src)

/obj/structure/table/proc/straight_table_check(direction)
	var/obj/structure/table/T
	for(var/angle in list(-90,90))
		T = locate() in get_step(loc,turn(direction,angle))
		if(T && !T.flipped)
			return 0
	T = locate() in get_step(loc,direction)
	if(!T || T.flipped)
		return 1
	if(istype(T,/obj/structure/table/reinforced/))
		if(!T.deconstruction_ready)
			return 0
	return T.straight_table_check(direction)

/obj/structure/table/verb/do_flip()
	set name = "Flip table"
	set desc = "Flips a non-reinforced table"
	set category = null
	set src in oview(1)

	if(!can_touch(usr) || ismouse(usr))
		return

	if(!flip(get_cardinal_dir(usr,src)))
		to_chat(usr, "<span class='notice'>It won't budge.</span>")
		return

	usr.visible_message("<span class='warning'>[usr] flips \the [src]!</span>")

	if(climbable)
		structure_shaken()

	return

/obj/structure/table/proc/do_put()
	set name = "Put table back"
	set desc = "Puts flipped table back"
	set category = "Object"
	set src in oview(1)

	if(!unflip())
		to_chat(usr, "<span class='notice'>It won't budge.</span>")
		return


/obj/structure/table/proc/flip(direction)
	if(flipped)
		return 0

	if( !straight_table_check(turn(direction,90)) || !straight_table_check(turn(direction,-90)) )
		return 0

	verbs -=/obj/structure/table/verb/do_flip
	verbs +=/obj/structure/table/proc/do_put

	var/list/targets = list(get_step(src,dir),get_step(src,turn(dir, 45)),get_step(src,turn(dir, -45)))
	for(var/atom/movable/A in get_turf(src))
		if(!A.anchored)
			spawn(0)
				A.throw_at(pick(targets),1,1)

	dir = direction
	if(dir != NORTH)
		layer = 5
	flipped = 1
	smooth = SMOOTH_FALSE
	flags |= ON_BORDER
	for(var/D in list(turn(direction, 90), turn(direction, -90)))
		if(locate(/obj/structure/table,get_step(src,D)))
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,D))
			T.flip(direction)
	update_icon()

	return 1

/obj/structure/table/proc/unflip()
	if(!flipped)
		return 0

	var/can_flip = 1
	for(var/mob/A in oview(src,0))//loc)
		if(istype(A))
			can_flip = 0
	if(!can_flip)
		return 0

	verbs -=/obj/structure/table/proc/do_put
	verbs +=/obj/structure/table/verb/do_flip

	layer = initial(layer)
	flipped = 0
	smooth = initial(smooth)
	flags &= ~ON_BORDER
	for(var/D in list(turn(dir, 90), turn(dir, -90)))
		if(locate(/obj/structure/table,get_step(src,D)))
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,D))
			T.unflip()
	update_icon()

	return 1


/*
 * Glass Tables
 */

/obj/structure/table/glass
	name = "glass table"
	desc = "Looks fragile. You should totally flip it. It is begging for it."
	icon = 'icons/obj/smooth_structures/glass_table.dmi'
	icon_state = "glass_table"
	buildstack = /obj/item/stack/sheet/glass
	max_integrity = 70
	canSmoothWith = null
	var/list/debris = list()

/obj/structure/table/glass/New()
	. = ..()
	debris += new frame
	debris += new /obj/item/weapon/shard

/obj/structure/table/glass/Destroy()
	for(var/i in debris)
		qdel(i)
	. = ..()

/obj/structure/table/glass/Crossed(atom/movable/AM)
	. = ..()
	if(!can_deconstruct)
		return
	if(!isliving(AM))
		return
	// Don't break if they're just flying past
	if(AM.throwing)
		addtimer(src, "throw_check", 5, FALSE, AM)
	else
		check_break(AM)

/obj/structure/table/glass/proc/throw_check(mob/living/M)
	if(M.loc == get_turf(src))
		check_break(M)

/obj/structure/table/glass/proc/check_break(mob/living/M)
	if(has_gravity(M) && M.mob_size > MOB_SIZE_SMALL)
		table_shatter(M)

/obj/structure/table/glass/flip(direction)
	deconstruct(FALSE)

/obj/structure/table/glass/proc/table_shatter(mob/living/L)
	visible_message("<span class='warning'>[src] breaks!</span>",
		"<span class='danger'>You hear breaking glass.</span>")
	var/turf/T = get_turf(src)
	playsound(T, "shatter", 50, 1)
	for(var/I in debris)
		var/atom/movable/AM = I
		AM.forceMove(T)
		debris -= AM
		if(istype(AM, /obj/item/weapon/shard))
			AM.throw_impact(L)
	L.Weaken(5)
	qdel(src)

/obj/structure/table/glass/deconstruct(disassembled = TRUE, wrench_disassembly = 0)
	if(can_deconstruct)
		if(disassembled)
			..()
			return
		else
			var/turf/T = get_turf(src)
			playsound(T, "shatter", 50, 1)
			for(var/X in debris)
				var/atom/movable/AM = X
				AM.forceMove(T)
				debris -= AM
	qdel(src)

/*
 * Wooden tables
 */
/obj/structure/table/wood
	name = "wooden table"
	desc = "Do not apply fire to this. Rumour says it burns easily."
	icon = 'icons/obj/smooth_structures/wood_table.dmi'
	icon_state = "wood_table"
	frame = /obj/structure/table_frame/wood
	framestack = /obj/item/stack/sheet/wood
	buildstack = /obj/item/stack/sheet/wood
	max_integrity = 70
	canSmoothWith = list(/obj/structure/table/wood, /obj/structure/table/wood/poker)
	burn_state = FLAMMABLE
	burntime = 20

/obj/structure/table/wood/narsie_act()
	return

/obj/structure/table/wood/poker //No specialties, Just a mapping object.
	name = "gambling table"
	desc = "A seedy table for seedy dealings in seedy places."
	icon = 'icons/obj/smooth_structures/poker_table.dmi'
	icon_state = "poker_table"
	buildstack = /obj/item/stack/tile/carpet

/obj/structure/table/wood/poker/narsie_act()
	new /obj/structure/table/wood(loc)
	qdel(src)

/*
 * Fancy Tables
 */

/obj/structure/table/wood/fancy
	name = "fancy table"
	desc = "A standard metal table frame covered with an amazingly fancy, patterned cloth."
	icon = 'icons/obj/structures.dmi'
	icon_state = "fancy_table"
	frame = /obj/structure/table_frame
	framestack = /obj/item/stack/rods
	buildstack = /obj/item/stack/tile/carpet
	canSmoothWith = list(/obj/structure/table/wood/fancy, /obj/structure/table/wood/fancy/black)

/obj/structure/table/wood/fancy/New()
	icon = 'icons/obj/smooth_structures/fancy_table.dmi' //so that the tables place correctly in the map editor
	..()

/obj/structure/table/wood/fancy/black
	icon_state = "fancy_table_black"
	buildstack = /obj/item/stack/tile/carpet/black

/obj/structure/table/wood/fancy/black/New()
	..()
	icon = 'icons/obj/smooth_structures/fancy_table_black.dmi' //so that the tables place correctly in the map editor

/*
 * Reinforced tables
 */
/obj/structure/table/reinforced
	name = "reinforced table"
	desc = "A reinforced version of the four legged table."
	icon = 'icons/obj/smooth_structures/reinforced_table.dmi'
	icon_state = "r_table"
	deconstruction_ready = FALSE
	buildstack = /obj/item/stack/sheet/plasteel
	canSmoothWith = list(/obj/structure/table/reinforced, /obj/structure/table)
	max_integrity = 200
	integrity_failure = 50

/obj/structure/table/reinforced/deconstruction_hints(mob/user)
	if(deconstruction_ready)
		to_chat(user, "<span class='notice'>The top cover has been <i>welded</i> loose and the main frame's <b>bolts</b> are exposed.</span>")
	else
		to_chat(user, "<span class='notice'>The top cover is firmly <b>welded</b> on.</span>")

/obj/structure/table/reinforced/flip(direction)
	if(!deconstruction_ready)
		return 0
	else
		return ..()

/obj/structure/table/reinforced/attackby(obj/item/weapon/W, mob/user, params)
	if(iswelder(W))
		var/obj/item/weapon/weldingtool/WT = W
		if(WT.remove_fuel(0, user))
			playsound(loc, W.usesound, 50, 1)
			if(deconstruction_ready)
				to_chat(user, "<span class='notice'>You start strengthening the reinforced table...</span>")
				if (do_after(user, 50*W.toolspeed, target = src))
					if(!src || !WT.isOn())
						return
					to_chat(user, "<span class='notice'>You strengthen the table.</span>")
					deconstruction_ready = FALSE
			else
				to_chat(user, "<span class='notice'>You start weakening the reinforced table...</span>")
				if (do_after(user, 50*W.toolspeed, target = src))
					if(!src || !WT.isOn())
						return
					to_chat(user, "<span class='notice'>You weaken the table.</span>")
					deconstruction_ready = TRUE
	else
		. = ..()

/*
 * Racks
 */
/obj/structure/rack
	name = "rack"
	desc = "Different from the Middle Ages version."
	icon = 'icons/obj/objects.dmi'
	icon_state = "rack"
	layer = TABLE_LAYER
	density = 1
	anchored = 1
	pass_flags = LETPASSTHROW
	max_integrity = 20

/obj/structure/rack/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>It's held together by a couple of <b>bolts</b>.</span>")

/obj/structure/rack/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			qdel(src)
			if(prob(50))
				new /obj/item/weapon/rack_parts(loc)
		if(3)
			if(prob(25))
				qdel(src)
				new /obj/item/weapon/rack_parts(loc)

/obj/structure/rack/blob_act()
	if(prob(75))
		qdel(src)
		return
	else if(prob(50))
		new /obj/item/weapon/rack_parts(loc)
		qdel(src)
		return

/obj/structure/rack/CanPass(atom/movable/mover, turf/target, height=0)
	if(height==0)
		return 1
	if(density == 0) //Because broken racks -Agouri |TODO: SPRITE!|
		return 1
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	if(mover.throwing)
		return 1
	else
		return 0

/obj/structure/rack/CanAStarPass(ID, dir, caller)
	. = !density
	if(ismovableatom(caller))
		var/atom/movable/mover = caller
		. = . || mover.checkpass(PASSTABLE)

/obj/structure/rack/MouseDrop_T(obj/O, mob/user)
	if((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return
	if(isrobot(user))
		return
	if(!user.drop_item())
		return
	if(O.loc != src.loc)
		step(O, get_dir(O, src))

/obj/structure/rack/attackby(obj/item/weapon/W, mob/user, params)
	if(iswrench(W) && can_deconstruct)
		playsound(loc, W.usesound, 50, 1)
		deconstruct(TRUE)
		return
	if(isrobot(user))
		return
	if(!(W.flags & ABSTRACT))
		if(user.drop_item())
			W.Move(loc)
	return

/obj/structure/rack/attack_hand(mob/user)
	if(HULK in user.mutations)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		deconstruct()
	else
		user.changeNext_move(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		playsound(loc, 'sound/items/dodgeball.ogg', 80, 1)
		user.visible_message("<span class='warning'>[user] kicks [src].</span>", \
							 "<span class='danger'>You kick [src].</span>")
		obj_integrity -= rand(1,2)
		healthcheck()

/obj/structure/rack/mech_melee_attack(obj/mecha/M)
	visible_message("<span class='danger'>[M] smashes [src] apart!</span>")
	deconstruct()

/obj/structure/rack/attack_alien(mob/living/user)
	user.do_attack_animation(src)
	visible_message("<span class='danger'>[user] slices [src] apart!</span>")
	deconstruct()

/obj/structure/rack/attack_animal(mob/living/simple_animal/user)
	if(user.environment_smash)
		user.do_attack_animation(src)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		deconstruct()

/obj/structure/rack/attack_tk() // no telehulk sorry
	return

/obj/structure/rack/proc/healthcheck()
	if(obj_integrity <= 0)
		deconstruct()

/obj/structure/rack/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(damage_amount)
				playsound(loc, 'sound/items/dodgeball.ogg', 80, 1)
			else
				playsound(loc, 'sound/weapons/tap.ogg', 50, 1)
		if(BURN)
			playsound(loc, 'sound/items/welder.ogg', 40, 1)

/obj/structure/rack/skeletal_bar
	name = "skeletal minibar"
	desc = "Made with the skulls of the fallen."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "minibar"

/obj/structure/rack/skeletal_bar/left
	icon_state = "minibar_left"

/obj/structure/rack/skeletal_bar/right
	icon_state = "minibar_right"

/*
 * Rack destruction
 */

/obj/structure/rack/deconstruct(disassembled = TRUE)
	if(can_deconstruct)
		density = FALSE
		var/obj/item/weapon/rack_parts/newparts = new(loc)
		transfer_fingerprints_to(newparts)
	qdel(src)

/*
 * Rack Parts
 */

/obj/item/weapon/rack_parts
	name = "rack parts"
	desc = "Parts of a rack."
	icon = 'icons/obj/items.dmi'
	icon_state = "rack_parts"
	flags = CONDUCT
	materials = list(MAT_METAL=2000)
	var/building = FALSE

/obj/item/weapon/rack_parts/attackby(obj/item/weapon/W, mob/user, params)
	if(iswrench(W))
		new /obj/item/stack/sheet/metal(user.loc)
		qdel(src)
	else
		. = ..()

/obj/item/weapon/rack_parts/attack_self(mob/user)
	if(building)
		return
	building = TRUE
	to_chat(user, "<span class='notice'>You start constructing a rack...</span>")
	if(do_after(user, 50, target = user, progress=TRUE))
		if(!user.drop_item(src))
			return
		var/obj/structure/rack/R = new /obj/structure/rack(user.loc)
		user.visible_message("<span class='notice'>[user] assembles \a [R].\
			</span>", "<span class='notice'>You assemble \a [R].</span>")
		R.add_fingerprint(user)
		qdel(src)
	building = FALSE
