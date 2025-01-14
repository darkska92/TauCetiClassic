/datum/disease/appendicitis
	form = "Condition"
	name = "Appendicitis"
	max_stages = 4
	spread = "Acute"
	cure = "Surgery"
	agent = "Appendix"
	affected_species = list(HUMAN)
	permeability_mod = 1
	contagious_period = 9001 //slightly hacky, but hey! whatever works, right?
	desc = "If left untreated the subject will become very weak, and may vomit often."
	severity = "Medium"
	longevity = 1000
	hidden = list(0, 1)
	stage_minimum_age = 160 // at least 200 life ticks per stage

/datum/disease/appendicitis/stage_act()
	..()

	if(ishuman(affected_mob))
		var/mob/living/carbon/human/H = affected_mob
		if(H.get_species() in list(DIONA, PODMAN, IPC, VOX))
			cure()

	if(stage == 1)
		if(affected_mob.op_stage.appendix == 2.0)
			// appendix is removed, can't get infected again
			cure()
		if(prob(5))
			to_chat(affected_mob, "<span class='warning'>You feel a stinging pain in your abdomen!</span>")
			affected_mob.emote("groan")
	if(stage > 1)
		if(prob(3))
			to_chat(affected_mob, "<span class='warning'>You feel a stabbing pain in your abdomen!</span>")
			affected_mob.emote("groan")
			affected_mob.adjustToxLoss(1)
	if(stage > 2)
		if(prob(1))
			if (affected_mob.nutrition > 100)
				var/mob/living/carbon/human/H = affected_mob
				H.vomit()
			else
				to_chat(affected_mob, "<span class='warning'>You gag as you want to throw up, but there's nothing in your stomach!</span>")
				affected_mob.Weaken(10)
				affected_mob.adjustToxLoss(3)
	if(stage > 3)
		if(prob(1) && ishuman(affected_mob))
			var/mob/living/carbon/human/H = affected_mob
			to_chat(H, "<span class='warning'>Your abdomen is a world of pain!</span>")
			H.Weaken(10)
			H.op_stage.appendix = 2.0

			var/obj/item/organ/external/BP = H.bodyparts_by_name[BP_GROIN]
			BP.sever_artery()
			BP.germ_level = max(INFECTION_LEVEL_TWO, BP.germ_level)
			H.adjustToxLoss(25)
			cure()
