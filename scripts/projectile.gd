extends Area2D

var target_position = Vector2.ZERO
const SPEED = 1500.0

func _ready():
	$LifespanTimer.start()

func _physics_process(delta):
	var direction = position.direction_to(target_position)
	position += direction * SPEED * delta

func _on_body_entered(body):
	if body.is_in_group("zombies"):
		var roll = randf()
		if roll < 0.25: # 1 in 4 chance
			print("Zombie hit! Roll: ", roll, " - SUCCESS, zombie is down.")
			body.go_down()
		else:
			print("Zombie hit! Roll: ", roll, " - FAILED, zombie survives.")
		queue_free() # Destroy the projectile

func _on_lifespan_timer_timeout():
	queue_free()
