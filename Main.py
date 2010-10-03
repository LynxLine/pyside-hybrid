
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

