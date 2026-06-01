export THEOS = /home/runner/theos
ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MoustacheMod
MoustacheMod_FILES = main.mm
# أضفنا مسار مكتبة KeyAuth للبحث فيها
MoustacheMod_CFLAGS = -I/home/runner/theos/KeyAuth
MoustacheMod_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
