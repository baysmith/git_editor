#ifndef ROLEITEMMODEL_H
#define ROLEITEMMODEL_H

#include <QAbstractListModel>

struct DataObject
{
    QString operation;
    QString sha;
    QString description;
};

class RoleItemModel : public QAbstractListModel {
    Q_OBJECT
public:

    enum Roles {
        Operation = Qt::UserRole + 1,
        Sha,
        Description
    };

    RoleItemModel(QObject *parent = 0);
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    void appendRow(DataObject *data);

public slots:
    void move(int index, int from);
    void nextOperation(int row);

private:
    QList<DataObject*> _items;
};

#endif // ROLEITEMMODEL_H
