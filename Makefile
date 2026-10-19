TARGET = firmware

INCLUDES += -Iinclude/

OBJS_DIR = build/
OBJS += $(OBJS_DIR)/main.o

ELF_FILE = $(OBJS_DIR)/$(TARGET).elf

SRCS_DIR = src/

ARCH ?= armv6-m
FAMILY ?= stm32/l0
MCU ?= stm32l072czyx
DEVICE ?= stm32l072czyx

ZERORTOS_DIR = zeroRTOS/
ZERORTOS_LIB = zeroRTOS/lib/$(ARCH)/libzeroRTOS.a

OPENCM3_DIR = libopencm3/
OBJS += $(OBJS_DIR)/vector/vector.o

LDSCRIPT	= $(OBJS_DIR)/generated.$(DEVICE).ld
DEVICES_DATA = $(OPENCM3_DIR)/ld/devices.data

ARCH_FLAGS  ?= -mcpu=cortex-m0plus -mthumb -DSTM32L0 -DZRTOS_ARCH_ARMV6M
Q			:= @
PREFIX		?= arm-none-eabi
CC 			:= $(PREFIX)-gcc
AR 			:= $(PREFIX)-ar
CFLAGS += -Os -ggdb3
CPPFLAGS += -Ilibopencm3/include -MD $(INCLUDES)

all: $(ZERORTOS_LIB) $(OBJS) $(LDSCRIPT) $(ELF_FILE)

# Build zeroRTOS
$(ZERORTOS_LIB):
	@printf "	MAKE  zeroRTOS\n"
	$(MAKE) -C zeroRTOS ARCH=$(ARCH) FAMILY=$(FAMILY)

# Build all src files
$(OBJS_DIR)/%.o : $(SRCS_DIR)/%.c
	@mkdir -p $(dir $@)
	@printf " CC $<\n"
	$(Q)$(CC) $(CFLAGS) $(CPPFLAGS) $(ARCH_FLAGS) -o $@ -c $<

# Build vector table file
$(OBJS_DIR)/vector/vector.o : $(OPENCM3_DIR)/lib/cm3/vector.c
	@mkdir -p $(dir $@)
	@printf " CC $<\n"
	$(Q)$(CC) $(CFLAGS) $(CPPFLAGS) $(ARCH_FLAGS) -o $@ -c $<

# Generate LD
$(LDSCRIPT): $(OPENCM3_DIR)/ld/linker.ld.S $(DEVICES_DATA)
	@printf "  GENLNK  $(DEVICE)\n"
	$(Q)$(CPP) $(ARCH_FLAGS) $(shell $(OPENCM3_DIR)/scripts/genlink.py $(DEVICES_DATA) $(DEVICE) DEFS) -P -E $< -o $@

BUILD_OPTIONS = -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OBJS_DIR)/$(TARGET).map
LIB_INCLUDES = -LzeroRTOS/lib/$(ARCH) -lzeroRTOS -Llibopencm3/lib -lopencm3_$(subst /,,$(FAMILY))

# Generate the final elf file
$(ELF_FILE): $(OBJS) $(ZERORTOS_LIB) $(LDSCRIPT)
	@printf "	LD   $@\n"
	$(Q)$(CC) $(OBJS) $(LIB_INCLUDES) -T $(LDSCRIPT) $(BUILD_OPTIONS) -o $@

clean:
	rm -rf build