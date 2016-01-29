#ifndef CommitModel_h
#define CommitModel_h

#include <QAbstractListModel>
#include <QList>
#include <QSharedPointer>

struct DataObject
{
    QString operation;
    QString sha;
    QString description;
};

class CommitModel : public QAbstractListModel {
    Q_OBJECT
public:

    enum Roles {
        Operation = Qt::UserRole + 1,
        Sha,
        Description
    };

    CommitModel(QObject *parent = 0);
    QHash<int, QByteArray> roleNames() const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    void appendRow(QSharedPointer<DataObject> data);

public slots:
    void move(int index, int from);
    void nextOperation(int row);
    QVariantMap get(int row);

private:
    QList<QSharedPointer<DataObject> > _items;
};

#endif // CommitModel_h
