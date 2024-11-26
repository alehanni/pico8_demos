SHELL=/bin/bash
PICO8_PATH=../../pico-8/pico8
COMMON_DEPS = p8_template.txt intersect.lua

p1_elements.p8: p1_elements.lua $(COMMON_DEPS)
	cat p1_elements.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p1_elements.p8

p1: p1_elements.p8
	$(PICO8_PATH) -run p1_elements.p8

p2_capsule.p8: p2_capsule.lua $(COMMON_DEPS)
	cat p2_capsule.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p2_capsule.p8

p2: p2_capsule.p8
	$(PICO8_PATH) -run p2_capsule.p8

p3_pebbles.p8: p3_pebbles.lua $(COMMON_DEPS)
	cat p3_pebbles.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p3_pebbles.p8

p3: p3_pebbles.p8
	$(PICO8_PATH) -run p3_pebbles.p8

p4_softbody.p8: p4_softbody.lua $(COMMON_DEPS)
	cat p4_softbody.lua > __lua__
	gcc -xc -E -P p8_template.txt -o p4_softbody.p8

p4: p4_softbody.p8
	$(PICO8_PATH) -run p4_softbody.p8

clean:
	rm -f p1_elements.p8 p2_capsule.p8 p3_pebbles.p8 p4_softbody.p8 __lua__
