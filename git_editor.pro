
# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

CONFIG += console

SOURCES += main.cpp \
    roleitemmodel.cpp

# Please do not modify the following two lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()

HEADERS += \
    roleitemmodel.h

RESOURCES += \
    qml.qrc
