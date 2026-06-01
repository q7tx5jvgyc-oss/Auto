TARGET := iphone:clang:latest:14.5
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoTouchCore
AutoTouchCore_FILES = main.mm
AutoTouchCore_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
