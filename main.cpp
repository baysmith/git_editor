#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#endif

#include "CommitModel.h"
#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtGui/QFont>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlProperty>

enum Mode {
    Unknown,
    Rebase,
    Edit
};

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(new QGuiApplication(argc, argv));

    qDebug() << app->arguments();
    if (app->arguments().size() < 2)
        return EXIT_FAILURE;

    auto defaultFont = app->font();
    defaultFont.setPointSize(10);
    app->setFont(defaultFont);

    Mode mode = Unknown;

    QScopedPointer<QQmlApplicationEngine> engine(new QQmlApplicationEngine);
    engine->rootContext()->setContextProperty("abort_editor", QVariant::fromValue(false));
    QScopedPointer<CommitModel> commitModel(new CommitModel);
    engine->rootContext()->setContextProperty("commits", commitModel.data());

    if (app->arguments()[1].endsWith("COMMIT_EDITMSG")
            || app->arguments()[1].endsWith("addp-hunk-edit.diff")) {
        mode = Edit;
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return EXIT_FAILURE;

        engine->rootContext()->setContextProperty("value", file.readAll());
        engine->load(QUrl(QStringLiteral("qrc:/qml/git_editor/edit.qml")));
    }

    if (app->arguments()[1].endsWith("git-rebase-todo")) {
        mode = Rebase;
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return EXIT_FAILURE;

        QTextStream in(&file);
        QStringList comments;
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.startsWith('|')) {
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

        engine->rootContext()->setContextProperty("comments", comments.join("\n"));
        engine->load(QUrl(QStringLiteral("qrc:/qml/git_editor/main.qml")));
    }

    if (mode == Unknown) {
        return EXIT_FAILURE;
    }

    auto result = app->exec();

    if (commitModel->abort()) {
        qDebug() << "Aborting";
        return EXIT_FAILURE;
    }

    if (mode == Rebase) {
        QFile file(app->arguments()[1]);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            qDebug() << "Unable to open for write" << app->arguments()[1];
            return EXIT_FAILURE;
        }

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
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            qDebug() << "Unable to open for write" << app->arguments()[1];
            return EXIT_FAILURE;
        }

        QTextStream out(&file);
        auto rootObject = engine->rootObjects()[0];
        auto textEdit = rootObject->findChild<QObject*>("textEdit");
        out << QQmlProperty::read(textEdit, "text").toString();
    }

    return result;
}
