SHELL=/bin/bash
PICO8_PATH=../../pico-8/pico8
COMMON_DEPS = __gfx__ p8_template.txt

__gfx__: FORCE
	aseprite gfx.aseprite --batch --script gfx_export.lua > __gfx__
FORCE:

p1_tilebased.p8: p1_tilebased.lua $(COMMON_DEPS)
	cat p1_tilebased.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p1_tilebased.p8

p1: p1_tilebased.p8
	$(PICO8_PATH) -run p1_tilebased.p8

p2_lines.p8: p2_lines.lua $(COMMON_DEPS)
	cat p2_lines.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p2_lines.p8

p2: p2_lines.p8
	$(PICO8_PATH) -run p2_lines.p8

p3_lerp.p8: p3_lerp.lua $(COMMON_DEPS)
	cat p3_lerp.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p3_lerp.p8

p3: p3_lerp.p8
	$(PICO8_PATH) -run p3_lerp.p8

p4_fill.p8: p4_fill.lua $(COMMON_DEPS)
	cat p4_fill.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p4_fill.p8

p4: p4_fill.p8
	$(PICO8_PATH) -run p4_fill.p8

p5_droplets.p8: p5_droplets.lua $(COMMON_DEPS)
	cat p5_droplets.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p5_droplets.p8

p5: p5_droplets.p8
	$(PICO8_PATH) -run p5_droplets.p8

.PHONY: clean
clean:
	rm -f *.p8 __lua__
