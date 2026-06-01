TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := AutoTouchMenu

# هنا نحدد ملف الكود الرئيسي الخاص بك
AutoTouchMenu_FILES := main.mm
AutoTouchMenu_FRAMEWORKS := UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
