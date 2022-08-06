/* 
* Add new worn icons to modular_splurt/icons/mob/clothing/current_head_accessories.dmi and their type to this list
* with the same icon_state from it's respective item
* 	"welding" if the item gives flash protection
* 	"none" if it's a normal item
* (subtypes included)
*/
#define HEAD_ACCESSORIES_LIST list(\
							/obj/item/clothing/head/welding = "welding",\
							/obj/item/clothing/glasses/welding = "welding",\
							/obj/item/clothing/head/beret = "none",\
							/obj/item/clothing/head/caphat = "none",\
							/obj/item/clothing/head/hopcap = "none",\
							/obj/item/clothing/head/fedora = "none",\
							/obj/item/clothing/head/centhat = "none",\
							/obj/item/clothing/head/pirate/captain,\
							/obj/item/clothing/head/chefhat = "none",\
							/obj/item/reagent_containers/glass/bucket = "none",\
							/obj/item/reagent_containers/rag/towel = "none",\
							/obj/item/paper = "none",\
							/obj/item/clothing/head/cowboyhat = "none",\
							/obj/item/clothing/head/morningstar = "none",\
							/obj/item/nullrod/fedora = "none",\
							/obj/item/clothing/head/maid = "none",\
							/obj/item/clothing/head/crown = "none"\
							)

/datum/species/dullahan
	name = "Dullahan"
	id = SPECIES_DULLAHAN
	default_color = "FFFFFF"
	species_traits = list(EYECOLOR,HAIR,FACEHAIR,LIPS,HAS_FLESH,HAS_BONE)
	inherent_traits = list(TRAIT_NOHUNGER,TRAIT_NOTHIRST,TRAIT_NOBREATH)
	mutant_bodyparts = list("tail_human" = "None", "ears" = "None", "deco_wings" = "None")
	use_skintones = USE_SKINTONES_GRAYSCALE_CUSTOM
	mutant_brain = /obj/item/organ/brain/dullahan
	mutanteyes = /obj/item/organ/eyes/dullahan
	mutanttongue = /obj/item/organ/tongue/dullahan
	mutantears = /obj/item/organ/ears/dullahan
	blacklisted = TRUE
	limbs_id = SPECIES_HUMAN
	skinned_type = /obj/item/stack/sheet/animalhide/human
	has_field_of_vision = FALSE //Too much of a trouble, their vision is already bound to their severed head.
	species_category = SPECIES_CATEGORY_UNDEAD
	var/pumpkin = FALSE
	wings_icons = SPECIES_WINGS_SKELETAL //seems suitable for an undead.

	var/obj/item/dullahan_relay/myhead
	var/obj/item/bodypart/head/head

/datum/species/dullahan/pumpkin
	name = "Pumpkin Head Dullahan"
	id = "pumpkindullahan"
	pumpkin = TRUE

/datum/species/dullahan/check_roundstart_eligible()
	if(SSevents.holidays && SSevents.holidays[HALLOWEEN])
		return TRUE
	return ..()

/datum/species/dullahan/on_species_gain(mob/living/carbon/human/H, datum/species/old_species)
	. = ..()
	H.flags_1 &= (~HEAR_1)
	head = H.get_bodypart(BODY_ZONE_HEAD)

	RegisterSignal(H, COMSIG_MOB_SAY, .proc/handle_speech)

	if(head)
		if(pumpkin)//Pumpkinhead!
			head.animal_origin = 100
			head.icon = 'icons/obj/clothing/hats.dmi'
			head.icon_state = "hardhat1_pumpkin_j"
			head.custom_head = TRUE
		head.drop_limb()
		if(!QDELETED(head)) //drop_limb() deletes the limb if it's no drop location and dummy humans used for rendering icons are located in nullspace. Do the math.
			head.throwforce = 25
			myhead = new /obj/item/dullahan_relay (head, H)
			H.put_in_hands(head)
			var/obj/item/organ/eyes/E = H.getorganslot(ORGAN_SLOT_EYES)
			for(var/datum/action/item_action/organ_action/OA in E.actions)
				OA.Trigger()

/datum/species/dullahan/on_species_loss(mob/living/carbon/human/H)
	H.flags_1 |= HEAR_1
	H.reset_perspective(H)
	if(myhead)
		var/obj/item/dullahan_relay/DR = myhead
		myhead = null
		DR.owner = null
		qdel(DR)
	H.regenerate_limb(BODY_ZONE_HEAD,FALSE)
	..()

/datum/species/dullahan/spec_life(mob/living/carbon/human/H)
	if(QDELETED(myhead))
		myhead = null
		H.gib()
	var/obj/item/bodypart/head/head2 = H.get_bodypart(BODY_ZONE_HEAD)
	if(head2)
		myhead = null
		H.gib()

/datum/species/dullahan/proc/update_vision_perspective(mob/living/carbon/human/H)
	var/obj/item/organ/eyes/dullahan/DE = H.getorganslot(ORGAN_SLOT_EYES)
	if(DE)
		H.update_tint()
		if(DE.tint > DE.default_tint)
			H.reset_perspective(H)
		else
			H.reset_perspective(myhead)

/obj/item/organ/brain/dullahan
	decoy_override = TRUE
	organ_flags = ORGAN_NO_SPOIL//Do not decay

/obj/item/organ/tongue/dullahan
	zone = "abstract"
	accents = list(/datum/accent/dullahan)

/obj/item/organ/ears/dullahan
	zone = "abstract"

/obj/item/organ/eyes/dullahan
	name = "head vision"
	desc = "An abstraction."
	actions_types = list(/datum/action/item_action/organ_action/dullahan)
	zone = "abstract"
	tint = 0 // used to switch the vision perspective to the head on species_gain().

	var/default_tint = 0

/datum/action/item_action/organ_action/dullahan
	name = "Toggle Perspective"
	desc = "Switch between seeing normally from your head, or blindly from your body."

/datum/action/item_action/organ_action/dullahan/Trigger()
	. = ..()
	var/obj/item/organ/eyes/dullahan/DE = target
	if(DE.tint > DE.default_tint)
		DE.tint = DE.default_tint
	else
		DE.tint = INFINITY

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(isdullahan(H))
			var/datum/species/dullahan/D = H.dna.species
			D.update_vision_perspective(H)

/obj/item/dullahan_relay
	name = "dullahan relay"
	var/mob/living/carbon/human/owner
	flags_1 = HEAR_1
	
	var/interacting_genital
	var/last_interacting_user // Ew, I'm sorry

	var/obj/item/clothing/head_accessory
	var/mutable_appearance/head_accessory_MA

/obj/item/dullahan_relay/Initialize(mapload, mob/living/carbon/human/new_owner)
	. = ..()
	if(!new_owner)
		return INITIALIZE_HINT_QDEL
	owner = new_owner

	START_PROCESSING(SSobj, src)
	RegisterSignal(owner, COMSIG_MOB_CLICKED_SHIFT_ON, .proc/examinate_check)
	RegisterSignal(src, COMSIG_ATOM_HEARER_IN_VIEW, .proc/include_owner)
	RegisterSignal(owner, COMSIG_LIVING_REGENERATE_LIMBS, .proc/unlist_head)
	RegisterSignal(owner, COMSIG_LIVING_REVIVE, .proc/retrieve_head)
	
	if(istype(loc, /obj/item/bodypart/head))
		RegisterSignal(loc, COMSIG_ITEM_ATTACK_SELF, .proc/head_interact)
		RegisterSignal(loc, COMSIG_CLICK_ALT, .proc/change_interaction)

		RegisterSignal(loc, COMSIG_MOUSEDROPPED_ONTO, .proc/on_mouse_dropped)
		RegisterSignal(loc, COMSIG_MOUSEDROP_ONTO, .proc/on_mouse_drop)

		RegisterSignal(loc, COMSIG_MOVABLE_MOVED, .proc/head_moved)

/obj/item/dullahan_relay/proc/examinate_check(mob/source, atom/target)
	if(source.client.eye == src)
		return COMPONENT_ALLOW_EXAMINATE

/obj/item/dullahan_relay/proc/include_owner(datum/source, list/processing_list, list/hearers)
	if(!QDELETED(owner))
		hearers += owner

/obj/item/dullahan_relay/proc/unlist_head(datum/source, noheal = FALSE, list/excluded_limbs)
	excluded_limbs |= BODY_ZONE_HEAD // So we don't gib when regenerating limbs.

//Retrieving the owner's head for better ahealing.
/obj/item/dullahan_relay/proc/retrieve_head(datum/source, full_heal, admin_revive)
	if(admin_revive)
		var/obj/item/bodypart/head/H = loc
		var/turf/T = get_turf(owner)
		if(H && istype(H) && T && !(H in owner.GetAllContents()))
			H.forceMove(T)

/obj/item/dullahan_relay/process()
	head_moved()
	if(!istype(loc, /obj/item/bodypart/head) || QDELETED(owner))
		. = PROCESS_KILL
		qdel(src)

/obj/item/dullahan_relay/Destroy()
	if(!QDELETED(owner))
		var/mob/living/carbon/human/H = owner
		if(isdullahan(H))
			var/datum/species/dullahan/D = H.dna.species
			D.myhead = null
			owner.gib()
	owner = null
	..()

//TODO: Make them able to whisper. 
/datum/species/dullahan/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	head.speech_span = null
	var/message = speech_args[SPEECH_MESSAGE]

	if(message[1] != "*")
		head.say(trim(message))
	
	speech_args[SPEECH_MESSAGE] = "" // Temporary I swear

/obj/item/dullahan_relay/proc/head_interact(datum/source, mob/living/carbon/user)
	if(!ishuman(user))
		return

	if(user.a_intent == INTENT_HELP && COOLDOWN_FINISHED(user, last_interaction_time))
		if(owner.stat == DEAD)
			to_chat(user, "<span class='warning'>[owner] is dead, oh no!</span>")
			return
		switch(user.zone_selected)
			if(BODY_ZONE_HEAD)
				if(!user.has_mouth()) // Ikr
					return
				user.visible_message("<span clas='notice'>\The <b>[user]</b> headpats \the <b>[owner]</b>!</span>")

			if(BODY_ZONE_PRECISE_MOUTH)
				if(!user.has_mouth())
					return
				user.visible_message("<span class='lewd'>\The <b>[user]</b> kisses \the <b>[owner]</b> deeply.</span>")
			
			if(BODY_ZONE_PRECISE_GROIN)
				if(!(owner?.client.prefs.toggles & VERB_CONSENT))
					return

				if(!interacting_genital || last_interacting_user != user)
					change_interaction(H = user)

				switch(interacting_genital) // It's a bit hacky for now, people can't cum with this solution :<
					if("penis")
						user.visible_message("<span class='lewd'>\The <b>[user]</b> fucks \the <b>[owner]</b> with [user.p_their()] [pick(GLOB.dick_nouns)].</span>")
						playlewdinteractionsound(get_turf(user), pick(GLOB.bj_noises), 50, 1, -1)
					if("vagina")
						user.visible_message("<span class='lewd'>\The <b>[user]</b> forces \the <b>[owner]</b> against [user.p_their()] cunt.</span>")
						playlewdinteractionsound(get_turf(user), pick(GLOB.bj_noises), 50, 1, -1)
					if("butt")
						user.visible_message("<span class='lewd'>\The <b>[user]</b> makes \the <b>[owner]</b> eat [user.p_their()] [pick(GLOB.butt_nouns)].</span>")
					if("breasts")
						user.do_breastsmother(owner) // Apparently no verbs for the suckiesuckie (or even for the ones above)
					else
						return
			else
				return

		COOLDOWN_START(user, last_interaction_time, 0.6 SECONDS)

/obj/item/dullahan_relay/proc/change_interaction(datum/source, mob/living/carbon/human/H)
	var/list/truly_exposed_genitals = list() // The exposed_genitals list doesn't show exposed genitals so yeah
	for(var/obj/item/organ/genital/G in H.internal_organs)
		if(G.is_exposed())
			truly_exposed_genitals += G
	
	if(!truly_exposed_genitals.len)
		return

	var/obj/item/organ/genital = input(H, "What to use on the head?", loc) as null|anything in truly_exposed_genitals

	if(!genital)
		return
	
	interacting_genital = genital.name
	last_interacting_user = H

/obj/item/bodypart/head/attack(mob/living/carbon/target, mob/user)
	if(isdullahan(user))
		var/list/head_contents = src.GetAllContents()
		var/obj/item/dullahan_relay/relay = locate() in head_contents
		
		var/mob/living/L = user
		if(relay && L.a_intent == INTENT_HELP && L != relay.owner)
			if(L.zone_selected == BODY_ZONE_PRECISE_MOUTH && COOLDOWN_FINISHED(L, last_interaction_time))
				if(!target.has_mouth())
					return
				L.visible_message("<span class='lewd'>\The <b>[L]</b> kisses \the <b>[target]</b> deeply.</span>")
				COOLDOWN_START(L, last_interaction_time, 0.6 SECONDS)
			return

	..()

/obj/item/dullahan_relay/proc/add_head_accessory(obj/item/clothing/I)
	head_accessory_MA = mutable_appearance('modular_splurt/icons/mob/clothing/current_head_accessories.dmi')
	head_accessory_MA.icon_state = I.icon_state
	I.forceMove(src)

	head_accessory_MA.pixel_y = -8

	loc.add_overlay(head_accessory_MA)
	head_accessory = I

/obj/item/dullahan_relay/proc/remove_head_accessory(obj/item/clothing/I)
	loc.cut_overlay(head_accessory_MA)
	head_accessory = null

/obj/item/dullahan_relay/proc/on_mouse_dropped(datum/source, obj/item/I, mob/living/user)
	if(!owner)
		return

	if(istype(I, /obj/item) && !head_accessory)
		for(var/accessory in HEAD_ACCESSORIES_LIST)
			if(istype(I, accessory))
				if(HEAD_ACCESSORIES_LIST[accessory] == "welding")
					var/obj/item/organ/eyes/dullahan/DE = owner.getorganslot(ORGAN_SLOT_EYES)
					DE.flash_protect = 2

					DE.default_tint = 2
					DE.tint = DE.default_tint
					owner.update_tint()

				add_head_accessory(I)
	else
		to_chat(user, span_notice("You can't put \the [I.name] on the head of \the [owner.name]"))
		return

/obj/item/dullahan_relay/proc/on_mouse_drop(datum/source, atom/A, mob/living/user)
	if(!owner)
		return
	if(head_accessory)
		if(istype(A, /turf/open))
			head_accessory.forceMove(A)
		else if(istype(A, /atom/movable/screen/inventory/hand))
			var/atom/movable/screen/inventory/hand/H = A

			user.put_in_hand(head_accessory, H.held_index)
		else
			return
		
		for(var/accessory in HEAD_ACCESSORIES_LIST)
			if(istype(head_accessory, accessory))
				if(HEAD_ACCESSORIES_LIST[accessory] == "welding")
					var/obj/item/organ/eyes/dullahan/DE = owner.getorganslot(ORGAN_SLOT_EYES)
					DE.flash_protect = 0

					DE.default_tint = initial(DE.default_tint)
					DE.tint = DE.default_tint
					owner.update_tint()

				remove_head_accessory(head_accessory)

/obj/item/dullahan_relay/proc/head_moved()
	var/obj/item/bodypart/head/H = loc
	if(istype(H.loc, /obj/item/storage) || istype(H.loc, /obj/structure/closet))
		if(!istype(H.loc,/obj/item/storage/belt/headcarrier))
			owner.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/scaled/impaired, 1)
		return
	else
		owner.clear_fullscreen("remote_view", 0)

#undef HEAD_ACCESSORIES_LIST
