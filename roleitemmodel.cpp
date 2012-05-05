#include "roleitemmodel.h"


/* Example usage:


Enumerate the role ID's somewhere
---------------------------------

struct RedditEntry {

    enum RedditRoles {
        UrlRole = Qt::UserRole + 1,
        DescRole,
        ...
    };
    ...
}

Instantiate the class
---------------------


    QHash<int, QByteArray> roleNames;
    roleNames[RedditEntry::UrlRole] =  "url";
    roleNames[RedditEntry::ScoreRole] = "score";
    m_linksmodel = new RoleItemModel(roleNames);



Populate with data:
-------------------

    QStandardItem* it = new QStandardItem();
    it->setData(e.desc, RedditEntry::DescRole);
    it->setData(e.score, RedditEntry::ScoreRole);

    m_linksmodel->appendRow(it);

Expose to QML:
-------------

QDeclarativeContext *ctx = ...

ctx->setContextProperty("mdlLinks", m_linksmodel);

*/


RoleItemModel::RoleItemModel(const QHash<int, QByteArray> &roleNames)
{
    setRoleNames(roleNames);
}

QVariantMap RoleItemModel::getModelData(const QAbstractItemModel* model, int row)
{
    QHash<int,QByteArray> names = model->roleNames();
    QHashIterator<int, QByteArray> i(names);
    QVariantMap res;
    while (i.hasNext()) {
        i.next();
        QModelIndex idx = model->index(row, 0);
        QVariant data = idx.data(i.key());
        res[i.value()] = data;
    }
    return res;
}

void RoleItemModel::move(int from, int to)
{
    auto item = takeRow(from);
    insertRow(to, item);
}

void RoleItemModel::nextOperation(int row)
{
    QStringList ops;
    ops << "pick" << "reword" << "edit" << "squash" << "fixup";
    auto data = item(row);
    QString op = data->data(Qt::UserRole + 1).toString();
    auto index = ops.indexOf(op);
    ++index;
    if (index == ops.size())
        index = 0;
    data->setData(ops.at(index), Qt::UserRole + 1);
}
