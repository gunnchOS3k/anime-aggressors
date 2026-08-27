extends RefCounted
class_name ArtDirectionContract

## Wave021 canonical art-direction flags — faceless abstract heads, humanoid bodies.

const REALISTIC_HUMANOID_FACE_AS_DEFAULT := false
const FACELESS_ABSTRACT_HEAD_DIRECTION := true

## Abstract head: smooth geometric cap / element mask — never photoreal eyes/nose/mouth.
const HEAD_PRESENTATION := "faceless_abstract_cap"

## Body remains readable humanoid silhouette at all forms.
const BODY_PRESENTATION := "stylized_humanoid"

static func head_is_faceless() -> bool:
	return FACELESS_ABSTRACT_HEAD_DIRECTION and not REALISTIC_HUMANOID_FACE_AS_DEFAULT


static func roster_art_flags() -> Dictionary:
	return {
		"REALISTIC_HUMANOID_FACE_AS_DEFAULT": REALISTIC_HUMANOID_FACE_AS_DEFAULT,
		"FACELESS_ABSTRACT_HEAD_DIRECTION": FACELESS_ABSTRACT_HEAD_DIRECTION,
		"HEAD_PRESENTATION": HEAD_PRESENTATION,
		"BODY_PRESENTATION": BODY_PRESENTATION,
	}
