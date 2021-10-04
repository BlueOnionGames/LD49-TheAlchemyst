extends Resource
class_name Upgrade

export var name: String
export var description: String
export var identifier: String
export var cost := 0
export var texture: Texture
export var purchased := false
export var order := 0
export var level := 0
export var single_purchase := true

export var custom_effect := false
export(Array, Resource) var effects
