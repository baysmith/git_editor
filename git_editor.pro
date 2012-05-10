unix {
QMAKE_CXXFLAGS += -std=c++0x
}

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

CONFIG += console

SOURCES += main.cpp \
    CommitModel.cpp

# Please do not modify the following two lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()

HEADERS += \
    CommitModel.h

RESOURCES += \
    qml.qrc

OTHER_FILES += \
    qml/git_editor/main.qml \
    qml/git_editor/Draggable.qml \
    qml/git_editor/CommitDelegate.qml \
    qml/git_editor/edit.qml
