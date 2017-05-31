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
