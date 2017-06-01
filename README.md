# pyside-hybrid
Creation of “hybrid” applications consisting of one part of Qt/C++ code and another part is Python/PySide

Creation of “hybrid” applications consisting of one part of c++ code and another part is python based, plus both part access each other with Qt-like Api, so they understand QString, etc and can exchange qt signals between those two parts. Even more, c++ part of application can generate python qt-like code to execute during runtime, he-he… In my previous post I explained how to implement this based on PyQt libraries. Also it can be interpreted as embedding PySide into Qt applications.

I got a lot of questions about this ideas, but one of frequent questions was about doing same with PySide. Well, PySide is LGPL so this makes the framework applicable for much more projects. So, let’s have a try of doing same but with PySide now.


First, I tried binary packages, but looks like they do not have generatorrunner executable included and other stuff for making bindings for Qt-like libraries – let’s wish for maintainers to include them. So, we need to build it manually. Needed CMake, installed Qt Frameworks, Python.

So I followed instructions listed on PySide web site and got it after hour-two. Let’s better show step-by-step for sure (I have done it on Mac OS 10.6, Qt 4.7 binaries from Nokia, Python 2.6):

``` sh
# git clone git://gitorious.org/pyside/apiextractor.git
# cd apiextractor
# mkdir build && cd build
# cmake .. && make && make install && cd ../..
#
# git clone git://gitorious.org/pyside/generatorrunner.git
# cd generatorrunner
# mkdir build && cd build
# cmake .. && make && make install && cd ../..
#
# git clone git://gitorious.org/pyside/shiboken.git
# cd shiboken
# mkdir build && cd build
# cmake .. && make && make install && cd ../..
#
# git clone git://gitorious.org/pyside/pyside.git
# cd pyside
# mkdir build && cd build
# cmake .. && make && make install && cd ../..
```

Now we have additionaly generatorrunner and typesystems needed for making wrappings to c++ mudules.

Let’s return to our hybrid application – create next folder structure:

``` sh
HybridApp/
 |-data/
 |    |-global.h
 |    |-typesystem.xml
 |-hybrid/
 |    |-MainWindow.h
 |    |-MainWindow.cpp
 |    |-hybrid.pro
 |-hybridpy/
 |    |-hybridpy.pro
 |-build.sh
 |-Main.py
 
```

Let’s explain:

1. Folder hybrid contains c++ part of application which is built into shared lib.
2. Folder hybridpy contains wrapping for c++ part – it builds Python module which will be imported into python part of application.
3. Folder data contains definition of typesystem used in c++ part. This is Xml file which describes types of used objects and their especialities when converting into python objects. More details about typesystems – on pyside page with following links.

Now we go into hybrid folder and create c++ part of hybrid. First let’s do it as c++ only application with own main() methon.

hybrid/hybrid.pro
``` sh
TEMPLATE = app
CONFIG += qt
QT += core gui

UI_DIR = build
RCC_DIR = build
MOC_DIR = build
OBJECTS_DIR = build

HEADERS += MainWindow.h
SOURCES += MainWindow.cpp Main.cpp
```

hybrid/Main.cpp:
``` cpp
#include <QtGui>
#include "MainWindow.h"
int main(int argc, char ** argv) {
    QApplication app(argc, argv);
    MainWindow window;
    window.resize(1000,700);
    window.show();
    return app.exec();
}
```

hybrid/MainWindow.h:
``` cpp
#ifndef MainWindow_H
#define MainWindow_H

#include <QMainWindow>
class QPushButton;
class QGraphicsView;
class QGraphicsScene;
class QPlainTextEdit;

class MainWindow : public QMainWindow { Q_OBJECT
public:
    MainWindow(QWidget * parent = 0L);
    virtual ~MainWindow();

signals:
    void runPythonCode(QString);

private slots:
    void runPythonCode();

public:
    QGraphicsView * viewer;
    QGraphicsScene * scene;
    QPlainTextEdit * editor;
    QPushButton * pb_commit;
};
#endif // MainWindow_H
```

hybrid/MainWindow.cpp:
``` cpp
#include <QtGui>
#include "MainWindow.h"

MainWindow::MainWindow(QWidget * parent):QMainWindow(parent) {
    QSplitter * splitter = new QSplitter;
    setCentralWidget(splitter);

    QWidget * editorContent = new QWidget;
    splitter->addWidget(editorContent);

    QVBoxLayout * layout = new QVBoxLayout;
    editorContent->setLayout(layout);

    editor = new QPlainTextEdit;
    layout->addWidget(editor);

    pb_commit = new QPushButton(tr("Commit"));
    connect(pb_commit, SIGNAL(clicked()), 
            this, SLOT(runPythonCode()));
    layout->addWidget(pb_commit);

    scene = new QGraphicsScene(this);
    viewer = new QGraphicsView;
    viewer->setScene(scene);
    splitter->addWidget(viewer);

    splitter->setSizes(QList<int>() << 400 << 600);
}

MainWindow::~MainWindow() {;}

void MainWindow::runPythonCode() {
    emit runPythonCode(editor->toPlainText());
}
```

As result we have a window with editor (left) and canvas (right):


Now it is time to to turn it into PySide-based application. We are going to:

1. Change c++ part to dynamic library
2. Create wrappings for MainWindow class
3. Make Main.py instead of C main() routine

For first point we just change TEMPLATE to lib, exclude Main.cpp, and build the shared lib. Also set TARGET to have shared libraries in root folder of HybridApp

hybrid/hybrid.pro:
``` pro
TEMPLATE = lib
TARGET = ../Hybrid
CONFIG += qt
QT += core gui

UI_DIR = build
RCC_DIR = build
MOC_DIR = build
OBJECTS_DIR = build

HEADERS += MainWindow.h
SOURCES += MainWindow.cpp
```

As result you should get libHybrid.dylib in root of our project (HybrydApp)

Now it is time to generate wrappings for c++ part to use in python. The generation is made by build.sh script in root of project. (Actually it builds everything – both c++ and wrapping parts)

build.sh:
``` sh
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
    --typesystem-paths=../data:$QTTYPESYSTEM \
    --output-directory=. \
    ../data/typesystem.xml

qmake
make
cd ..

rm -rf PyHybrid.so
ln -s libPyHybrid.dylib PyHybrid.so
```

You see that this is just one call of generatorrunner plus you provide paths for Qt includes, qt typesystem and your typesystem. Then in folder hybridpy we with qmake build the python module.

Listing of our typesystem.xml and global.h:

data/typesystem.xml:
``` xml
<?xml version="1.0"?>
<typesystem package="PyHybrid">
    <load-typesystem name="typesystem_core.xml" generate="no"/>
    <load-typesystem name="typesystem_gui.xml" generate="no"/>
    <object-type name="MainWindow"/>
</typesystem>
```

data/global.h (fyi: more details about global.h – here)
``` cpp
#undef QT_NO_STL
#undef QT_NO_STL_WCHAR

#ifndef NULL
#define NULL    0
#endif

#include <MainWindow.h>
```

And pro file for building python module:

hybridpy/hybridpy.pro:
``` pro
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
```

You can mention that most of used paths of python headers and qt headers can be extracted from utils like pkg-config etc – that’s true, but I showed exact paths intentionally just for demoing what is really included. Also, of course you can do it all with cmake, but I made a choice for qmake pro files to have better (plain) presentation of used files and logic.

Looks complete – if you just run build.sh you will get PyHybrid.so – python module.
Everything is ready, time to connect both parts in Main.py script:

Main.py:
``` python
import sys
from PySide.QtCore import *
from PySide.QtGui import *
from PyHybrid import *

class RunScript(QObject):
    def __init__(self, mainWindow):
        QObject.__init__(self)
        self.mainWindow = mainWindow

    def runScript(self, script):
        mainWindow = self.mainWindow
        exec(str(script))

a = QApplication(sys.argv)
w = MainWindow()
r = RunScript(w)
w.setWindowTitle('PyHybrid')
w.resize(1000,800)
w.show()
a.connect(w, SIGNAL('runPythonCode(QString)'), r.runScript)
a.connect(a, SIGNAL('lastWindowClosed()'), a, SLOT('quit()') )
a.exec_()
```

If you run it you will get same window as in c++ application except that python code entered in left panel with editor can be executed just here and the python code has control of our c++ part.
