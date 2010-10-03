TEMPLATE = lib
QT += core gui

INCLUDEPATH += hybrid
INCLUDEPATH += ../hybrid

INCLUDEPATH += /usr/include/python2.6
INCLUDEPATH += /usr/local/include/shiboken
INCLUDEPATH += /usr/local/include/PySide
INCLUDEPATH += /usr/local/include/PySide/QtCore
INCLUDEPATH += /usr/local/include/PySide/QtGui

LIBS += -ldl -lpython2.6
LIBS += -lpyside
LIBS += -lshiboken
LIBS += -L.. -lHybrid

TARGET = ../PyHybrid

SOURCES += \
    pyhybrid/pyhybrid_module_wrapper.cpp \
    pyhybrid/mainwindow_wrapper.cpp \
