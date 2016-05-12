TEMPLATE = app

QT += qml quick
CONFIG += console c++11

SOURCES += main.cpp \
    CommitModel.cpp

HEADERS += \
    CommitModel.h

RESOURCES += \
    qml.qrc

RC_FILE = git_editor.rc

OTHER_FILES += \
    qml/git_editor/main.qml \
    qml/git_editor/Draggable.qml \
    qml/git_editor/CommitDelegate.qml \
    qml/git_editor/edit.qml

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)
