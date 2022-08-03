/datum/component/neckfire
	var/mutable_appearance/neckfire_MA
	
	var/color

	var/obj/effect/dummy/luminescent_glow/glowth //shamelessly copied from glowy which copied luminescents

	var/light = 1
	var/is_glowing = FALSE
	
	var/plane = 19

/datum/component/neckfire/Initialize(fire_color)
	. = ..()
	if(!isdullahan(parent))
		return COMPONENT_INCOMPATIBLE
	
	neckfire_MA = mutable_appearance('modular_splurt/icons/mob/dullahan_neckfire.dmi')
	neckfire_MA.icon_state = "neckfire"

	color = "#[fire_color]"
	lit(color)
	RegisterSignal(parent, COMSIG_MOB_DEATH, .proc/unlit)

/datum/component/neckfire/proc/setup_neckfireMA()
	neckfire_MA.icon_state = "neckfire"
	neckfire_MA.color = color
	neckfire_MA.plane = plane // glowy i hope

/datum/component/neckfire/proc/lit(fire_color)
	var/mob/living/carbon/M = parent

	if(!neckfire_MA || M.stat == DEAD)
		return

	unlit(M)
	setup_neckfireMA()

	var/datum/action/neckfire/A = new /datum/action/neckfire(src)
	A.Grant(M)

	M.add_overlay(neckfire_MA)

/datum/component/neckfire/proc/unlit(mob/living/carbon/M)
	if(M)
		M.cut_overlay(neckfire_MA)
	qdel(glowth)
	is_glowing = FALSE

/datum/component/neckfire/Destroy(force=FALSE, silent=FALSE)
	. = ..()
	unlit(parent)
	UnregisterSignal(parent, COMSIG_MOB_DEATH)


/datum/action/neckfire
	name = "Toggle Neckfire Glow"
	icon_icon = 'modular_splurt/icons/mob/dullahan_neckfire.dmi'
	button_icon_state = "neckfire_action"

/datum/action/neckfire/Trigger()
	. = ..()
	var/datum/component/neckfire/N = target
	if(!N.neckfire_MA)
		return
	if(!N.is_glowing)
		N.glowth = new(N.parent)
		N.glowth.set_light(N.light, N.light, N.color)
		N.is_glowing = TRUE
	else 
		qdel(N.glowth)
		N.is_glowing = FALSE

/datum/species/dullahan/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	if(H.dna.features["neckfire"] && !istype(H, /mob/living/carbon/human/dummy))
		H.AddComponent(/datum/component/neckfire, H.dna.features["neckfire_color"])
	