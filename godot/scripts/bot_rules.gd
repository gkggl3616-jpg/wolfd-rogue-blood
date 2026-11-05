extends RefCounted
# New local AI parameters. These are not measured human IQ or PC server rules.
const DAMAGE=8
const HEALTH=100
const LEVELS={
 "easy":{"name":"Kolay","skillRating":80,"reaction":0.70,"think":0.32,"spread":0.075,"memory":2.5,"dodgeChance":0.12,"dodgeCooldown":5.0,"coverSamples":6},
 "normal":{"name":"Normal","skillRating":95,"reaction":0.40,"think":0.22,"spread":0.040,"memory":5.0,"dodgeChance":0.35,"dodgeCooldown":3.5,"coverSamples":10},
 "hard":{"name":"Zor","skillRating":110,"reaction":0.22,"think":0.14,"spread":0.018,"memory":8.0,"dodgeChance":0.65,"dodgeCooldown":2.5,"coverSamples":14}
}
static func profile(key):return LEVELS.get(key,LEVELS.normal).duplicate(true)
