#define NODERANGE 2

/obj/effect/alien/weeds
	name = "weeds"
	desc = "Weird black weeds..."
	icon = 'icons/Xeno/weeds.dmi'
	icon_state = "base"
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	var/parent_node
	max_integrity = 25

/obj/effect/alien/weeds/deconstruct(disassembled = TRUE)
	GLOB.round_statistics.weeds_destroyed++
	SSblackbox.record_feedback("tally", "round_statistics", 1, "weeds_destroyed")
	return ..()

/obj/effect/alien/weeds/Initialize(mapload, obj/effect/alien/weeds/node/node)
	. = ..()

	parent_node = node

	update_sprite()
	update_neighbours()


/obj/effect/alien/weeds/Destroy()

	if(parent_node)
		SSweeds.add_weed(src)

	for(var/obj/effect/alien/A in loc.contents)
		if(QDELETED(A) || A == src || A.ignore_weed_destruction)
			continue
		A.obj_destruction("melee")

	var/oldloc = loc
	. = ..()
	update_neighbours(oldloc)


/obj/effect/alien/weeds/examine(mob/user)
	..()
	var/turf/T = get_turf(src)
	if(isfloorturf(T))
		T.ceiling_desc(user)


/obj/effect/alien/weeds/Crossed(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.next_move_slowdown += 1


/obj/effect/alien/weeds/proc/update_neighbours(turf/U)
	if(!U)
		U = loc
	if(istype(U))
		for (var/dirn in GLOB.cardinals)
			var/turf/T = get_step(U, dirn)

			if (!istype(T))
				continue

			var/obj/effect/alien/weeds/W = locate() in T
			if(W)
				W.update_sprite()


/obj/effect/alien/weeds/proc/update_sprite()
	var/my_dir = 0
	for (var/check_dir in GLOB.cardinals)
		var/turf/check = get_step(src, check_dir)

		if (!istype(check))
			continue
		if(istype(check, /turf/closed/wall/resin))
			my_dir |= check_dir

		else if (locate(/obj/effect/alien/weeds) in check)
			my_dir |= check_dir

	if (my_dir == 15) //weeds in all four directions
		icon_state = "weed[rand(0,15)]"
	else if(my_dir == 0) //no weeds in any direction
		icon_state = "base"
	else
		icon_state = "weed_dir[my_dir]"


/obj/effect/alien/weeds/weedwall
	layer = RESIN_STRUCTURE_LAYER
	plane = GAME_PLANE
	icon_state = "weedwall"

/obj/effect/alien/weeds/weedwall/update_sprite()
	if(iswallturf(loc))
		var/turf/closed/wall/W = loc
		if(W.junctiontype)
			icon_state = "weedwall[W.junctiontype]"



/obj/effect/alien/weeds/weedwall/window
	layer = ABOVE_TABLE_LAYER

/obj/effect/alien/weeds/weedwall/window/update_sprite()
	var/obj/structure/window/framed/F = locate() in loc
	if(F && F.junction)
		icon_state = "weedwall[F.junction]"

/obj/effect/alien/weeds/weedwall/frame
	layer = ABOVE_TABLE_LAYER

/obj/effect/alien/weeds/weedwall/frame/update_sprite()
	var/obj/structure/window_frame/WF = locate() in loc
	if(WF && WF.junction)
		icon_state = "weedframe[WF.junction]"



/obj/effect/alien/weeds/node
	name = "purple sac"
	desc = "A weird, pulsating node."
	icon_state = "weednode"
	var/node_range = NODERANGE
	max_integrity = 60

	var/node_turfs = list() // list of all potential turfs that we can expand to

	ignore_weed_destruction = TRUE

/obj/effect/alien/weeds/node/strong
	name = "strong purple sac"
	desc = "A weird, pulsating node. This looks pretty tough."
	node_range = NODERANGE*2
	max_integrity = 120

/obj/effect/alien/weeds/node/Destroy()
	. = ..()
	SSweeds_decay.decay_weeds(node_turfs)


/obj/effect/alien/weeds/node/update_icon()
	overlays.Cut()
	overlays += "weednode"

/obj/effect/alien/weeds/node/Initialize(mapload, obj/effect/alien/weeds/node/node, mob/living/carbon/xenomorph/X)
	for(var/obj/effect/alien/weeds/W in loc)
		if(W != src)
			qdel(W) //replaces the previous weed
			break

	overlays += "weednode"
	. = ..(mapload, src)

	// Generate our full graph before adding to SSweeds
	node_turfs = filled_turfs(src, node_range, "square")
	SSweeds.add_node(src)
#undef NODERANGE
