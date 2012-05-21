#include <QApplication>
#include "qmlapplicationviewer.h"
#include "CommitModel.h"
#include <QtCore>
#include <QtGui>
#include <QtDeclarative>

enum Mode {
    Unknown,
    Rebase,
    Edit
};

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    qDebug() << app->arguments();
    if (app->arguments().size() < 2)
        return EXIT_FAILURE;

    Mode mode = Unknown;

    QScopedPointer<QmlApplicationViewer> viewer(new QmlApplicationViewer);
    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationAuto);

    if (app->arguments()[1].endsWith("COMMIT_EDITMSG")) {
        mode = Edit;
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return EXIT_FAILURE;

        viewer->rootContext()->setContextProperty("value", file.readAll());
        viewer->setSource(QUrl("qrc:/qml/git_editor/edit.qml"));
    }

    QScopedPointer<CommitModel> commitModel;
    if (app->arguments()[1].endsWith("git-rebase-todo")) {
        mode = Rebase;
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return EXIT_FAILURE;

        QStringList listModel;
        listModel << "import QtQuick 1.1";
        listModel << "ListModel {";
        QTextStream in(&file);
        commitModel.reset(new CommitModel);
        QStringList comments;
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.startsWith('#')) {
                comments += line;
            } else if (!line.isEmpty()) {
                QSharedPointer<DataObject> data(new DataObject);
                data->operation = line.section(' ', 0, 0);
                data->sha = line.section(' ', 1, 1);
                data->description = line.section(' ', 2);
                commitModel->appendRow(data);
            }
        }
        file.close();
        listModel << "}";

        viewer->rootContext()->setContextProperty("commits", commitModel.data());
        viewer->rootContext()->setContextProperty("comments", comments.join("\n"));
        viewer->setSource(QUrl("qrc:/qml/git_editor/main.qml"));
    }

    if (mode == Unknown) {
        return EXIT_FAILURE;
    }

    auto desktop = QApplication::desktop();
    auto x = (desktop->width() - viewer->width()) / 2;
    auto y = (desktop->height() - viewer->height()) / 2;
    viewer->move(x, y);
    viewer->setWindowIcon(QIcon(":/icon.png"));
    viewer->showExpanded();

    auto result = app->exec();

    if (mode == Rebase) {
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            return EXIT_FAILURE;

        QTextStream out(&file);
        for (int row = 0; row < commitModel->rowCount(); ++row) {
            QModelIndex index = commitModel->index(row);
            QString operation = commitModel->data(index, CommitModel::Operation).toString();
            QString sha = commitModel->data(index, CommitModel::Sha).toString();
            QString description = commitModel->data(index, CommitModel::Description).toString();
            qDebug() << operation << sha << description;
            if (operation == "DELETE")
                continue;
            out << operation << ' ' << sha << ' ' << description << '\n';
        }
    } else if (mode == Edit) {
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            return EXIT_FAILURE;

        QTextStream out(&file);
        out << QDeclarativeProperty::read(viewer->rootObject(), "text").toString();
    }

    return result;
}
