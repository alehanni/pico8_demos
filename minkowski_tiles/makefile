SHELL=/bin/bash
PICO8_PATH=../../pico-8/pico8
COMMON_DEPS = __gfx__ __gff__ __map__ p8_template.txt

p1_bresenham.p8: p1_bresenham.lua $(COMMON_DEPS)
	cat p1_bresenham.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p1_bresenham.p8

p1: p1_bresenham.p8
	$(PICO8_PATH) -run p1_bresenham.p8

p2_raycast.p8: p2_raycast.lua $(COMMON_DEPS)
	cat p2_raycast.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p2_raycast.p8

p2: p2_raycast.p8
	$(PICO8_PATH) -run p2_raycast.p8

p3_shapecast.p8: p3_shapecast.lua $(COMMON_DEPS)
	cat p3_shapecast.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p3_shapecast.p8

p3: p3_shapecast.p8
	$(PICO8_PATH) -run p3_shapecast.p8

p4_character.p8: p4_character.lua $(COMMON_DEPS)
	cat p4_character.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p4_character.p8

p4: p4_character.p8
	$(PICO8_PATH) -run p4_character.p8

clean:
	rm -f p1_bresenham.p8 p2_raycast.p8 p3_shapecast.p8 p4_character.p8 __lua__
