CC=zcc
AS=zcc

#TARGET=+zx81
ifeq ("$(TARGET)", "")
	TARGET=+zx
endif

#VERBOSITY=-Ca-v -V

#C_OPT_FLAGS=-SO3 --max-allocs-per-node200000
C_OPT_FLAGS=-O3

ASFLAGS=$(TARGET) $(VERBOSITY) -c 
CFLAGS=$(TARGET) $(VERBOSITY)  -compiler sdcc -c $(C_OPT_FLAGS)
LDFLAGS=$(TARGET) $(VERBOSITY) -compiler sdcc

EXEC_OUTPUT=build/space-invaders

OBJS = 	build/utils_asm.o \
		build/Point.o \
		build/round_routines.o \
		build/screens_routines.o \
		build/PutSprite.o \
		build/charset.o \
		build/sprites.o \
		build/utils.o \
		build/input.o \
		build/tables.o \
		build/common.o \
		build/round.o \
		build/screens.o \
		build/space-invaders.o

ifeq ("$(TARGET)","+zx")
	#build/RotateTables.o
	OBJECTS=build/Screentables.o \
			build/fxsound.o \
			build/isr.o \
			build/sound.o \
			$(OBJS)
	FXSOUND_H=fxsound.h
	SOUND_H=sound.h
	ISR_H=isr.h
	ASFLAGS+=-Ca-D__SPECTRUM__ --opt-code-speed --list --c-code-in-asm
	CFLAGS+=-pragma-include:zpragma.inc -clib=sdcc_iy --opt-code-speed --list --c-code-in-asm
#	LDFLAGS+=-nostdlib -zorg 24800 -pragma-include:zpragma.inc -clib=sdcc_iy -startup=31 -Cz--screen -Czspace3.scr --opt-code-speed --list --c-code-in-asm
	LDFLAGS+=-nostdlib -zorg 27000 -pragma-include:zpragma.inc -clib=sdcc_iy -startup=31 -Cz--merge -Czloader.tap -Cz--screen -Czspace3.scr --opt-code-speed --list --c-code-in-asm
	EXEC=$(EXEC_OUTPUT).tap
endif

ifeq ("$(TARGET)","+zx81")

	OBJECTS=$(OBJS) build/sound.o
	ASFLAGS+=-Ca-D__ZX81__ --opt-code-speed --list --c-code-in-asm
	CFLAGS+=-pragma-include:zx81pragma.inc --opt-code-speed --list --c-code-in-asm

#	OBJECTS=$(OBJS)
#	ASFLAGS+=-Ca-D__ZX81__ -Ca-D__NOSOUND__ --opt-code-speed --list --c-code-in-asm
#	CFLAGS+=-pragma-include:zx81pragma.inc --opt-code-speed --list --c-code-in-asm -D__NOSOUND__

	# Full Choma81
#	LDFLAGS+=-nostdinc -pragma-include:zx81pragma.inc -subtype=chroma -clib=wrx -startup=23 --opt-code-speed

	# Basic Chroma81
	LDFLAGS+=-nostdinc -pragma-include:zx81pragma.inc -subtype=wrx -clib=wrx -startup=3 --opt-code-speed

	# --list --c-code-in-asm
	EXEC=$(EXEC_OUTPUT).P
endif

all: $(EXEC)

build/Screentables.o: Screentables.asm
	$(AS) $(ASFLAGS) -o $@ $<

build/RotateTables.o: RotateTables.asm
	$(AS) $(ASFLAGS) -o $@ $<

build/Point.o: Point.asm Point.h
	$(AS) $(ASFLAGS) -o $@ $<

build/round_routines.o: round_routines.asm
	$(AS) $(ASFLAGS) -o $@ $<

build/sound.o: sound.asm sound.h $(FXSOUND_H)
	$(AS) $(ASFLAGS) -o $@ $<

build/screens_routines.o: screens_routines.asm
	$(AS) $(ASFLAGS) -o $@ $<

build/fxsound.o: fxsound.asm fxsound.h
	$(AS) $(ASFLAGS) -o $@ $<

build/PutSprite.o: PutSprite.asm.m4 PutSprite.h
	$(AS) $(ASFLAGS) -o $@ $<

build/input.o: input.asm input.h
	$(AS) $(ASFLAGS) -o $@ $<

build/utils_asm.o: utils_asm.asm utils_asm.h
	$(AS) $(ASFLAGS) -o $@ $<

build/charset.o: charset.c charset.h
	$(CC) $(CFLAGS) -o $@ $<

build/common.o: common.c common.h player.h
	$(CC) $(CFLAGS) -o $@ $<

build/isr.o: isr.c isr.h screens.h common.h round.h sound.h round_routines.h
	$(CC) $(CFLAGS) -o $@ $<

build/round.o: round.c round.h common.h utils_asm.h Point.h sprites.h utils.h tables.h screens.h sound.h player.h input.h PutSprite.h round_routines.h
	$(CC) $(CFLAGS) -o $@ $<

build/screens.o: screens.c screens.h common.h utils_asm.h sprites.h utils.h PutSprite.h screens.h
	$(CC) $(CFLAGS) -o $@ $<

build/space-invaders.o: space-invaders.c utils_asm.h utils.h $(ISR_H) screens.h round.h common.h charset.h $(SOUND_H) input.h round_routines.h
	$(CC) $(CFLAGS) -o $@ $<

build/sprites.o: sprites.c sprites.h
	$(CC) $(CFLAGS) -o $@ $<

build/tables.o: tables.c tables.h
	$(CC) $(CFLAGS) -o $@ $<

build/utils.o: utils.c utils.h common.h PutSprite.h
	$(CC) $(CFLAGS) -o $@ $<

$(EXEC) : $(OBJECTS)
	 $(CC) $(LDFLAGS) $(OBJECTS) -o $(EXEC_OUTPUT) -create-app -m

.PHONY: clean
clean:
	rm -f build/*.o build/*.bin $(EXEC) $(EXEC_OUTPUT).map
