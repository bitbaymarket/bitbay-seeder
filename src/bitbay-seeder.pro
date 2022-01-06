TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
        bitcoin.cpp \
        db.cpp \
        dns.cpp \
        main.cpp \
        netbase.cpp \
        protocol.cpp \
        util.cpp

HEADERS += \
    bitcoin.h \
    compat.h \
    db.h \
    dns.h \
    netbase.h \
    protocol.h \
    serialize.h \
    strlcpy.h \
    uint256.h \
    util.h


LIBS += -pthread -lcrypto
