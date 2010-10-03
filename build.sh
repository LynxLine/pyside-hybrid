#!/bin/sh

cd hybrid
qmake
make
cd ..

cd hybridpy

QTGUI_INC=/Library/Frameworks/QtGui.framework/Versions/4/Headers
QTCORE_INC=/Library/Frameworks/QtCore.framework/Versions/4/Headers
QTTYPESYSTEM=/usr/local/share/PySide/typesystems

generatorrunner --generatorSet=shiboken \
    ../data/global.h \
    --include-paths=../hybrid:$QTCORE_INC:$QTGUI_INC:/usr/include \
    --typesystem-paths=data:$QTTYPESYSTEM \
    --output-directory=. \
    ../data/typesystem.xml

qmake
make
cd ..

rm -rf PyHybrid.so
ln -s libPyHybrid.dylib PyHybrid.so

