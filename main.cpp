#include <QApplication>
#include "qmlapplicationviewer.h"
#include "roleitemmodel.h"
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

    QmlApplicationViewer *viewer = new QmlApplicationViewer;
    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationAuto);

    if (app->arguments()[1].endsWith("COMMIT_EDITMSG")) {
        mode = Edit;
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return EXIT_FAILURE;

        viewer->rootContext()->setContextProperty("value", file.readAll());
        viewer->setSource(QUrl("qrc:/qml/git_editor/edit.qml"));
    }

    QScopedPointer<RoleItemModel> commitModel;
    if (app->arguments()[1].endsWith("git-rebase-todo")) {
        mode = Rebase;
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return EXIT_FAILURE;

        QTextStream in(&file);
        QHash<int, QByteArray> roles;
        roles[Qt::UserRole + 1] = "operation";
        roles[Qt::UserRole + 2] = "sha";
        roles[Qt::UserRole + 3] = "description";
        commitModel.reset(new RoleItemModel(roles));
        QStringList comments;
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.startsWith('#')) {
                comments += line;
            } else if (!line.isEmpty()) {
                QString operation = line.section(' ', 0, 0);
                QString sha = line.section(' ', 1, 1);
                QString description = line.section(' ', 2);
                QStandardItem *row = new QStandardItem;
                row->setData(operation, Qt::UserRole + 1);
                row->setData(sha, Qt::UserRole + 2);
                row->setData(description, Qt::UserRole + 3);
                commitModel->appendRow(row);
            }
        }
        file.close();

        viewer->rootContext()->setContextProperty("commits", commitModel.data());
        viewer->rootContext()->setContextProperty("comments", comments.join("\n"));
        viewer->setSource(QUrl("qrc:/qml/git_editor/main.qml"));
    }

    if (mode == Unknown) {
        return EXIT_FAILURE;
    }

    viewer->showExpanded();

    auto result = app->exec();

    if (mode == Rebase) {
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            return EXIT_FAILURE;

        QTextStream out(&file);
        for (int i = 0; i < commitModel->rowCount(); ++i) {
            auto item = commitModel->item(i);
            QString operation = item->data(Qt::UserRole + 1).toString();
            QString sha = item->data(Qt::UserRole + 2).toString();
            QString description = item->data(Qt::UserRole + 3).toString();
            qDebug() << operation << sha << description;
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
