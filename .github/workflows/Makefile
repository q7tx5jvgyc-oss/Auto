TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

# اسم الأداة هنا تم تعديله إلى Autotouh
TWEAK_NAME := Autotouh

# تأكد أن اسم ملف الكود الخاص بك هو main.mm
Autotouh_FILES := main.mm
Autotouh_FRAMEWORKS := UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
