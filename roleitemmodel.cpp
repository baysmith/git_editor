#include "roleitemmodel.h"

#include <QStringList>

RoleItemModel::RoleItemModel(QObject *parent) :
    QAbstractListModel(parent)
{
    QHash<int, QByteArray> roles;
    roles[Operation] = "operation";
    roles[Sha] = "sha";
    roles[Description] = "description";

    setRoleNames(roles);
}

int RoleItemModel::rowCount(const QModelIndex &) const
{
    return _items.size();
}

QVariant RoleItemModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= _items.size())
        return QVariant();

    DataObject *dataObject = _items.at(index.row());
    switch (role) {
    case Operation:
        return QVariant::fromValue(dataObject->operation);
    case Sha:
        return QVariant::fromValue(dataObject->sha);
    case Qt::DisplayRole:
    case Description:
        return QVariant::fromValue(dataObject->description);
    default:
        return QVariant();
    }
}

void RoleItemModel::appendRow(DataObject* data)
{
    beginInsertRows(QModelIndex(), _items.size(), _items.size());
    _items.append(data);
    endInsertRows();
}

void RoleItemModel::move(int from, int to)
{
    if (from < 0 || to < 0 || from >= _items.size() || to >= _items.size())
        return;

    auto dest = to;
    if (from < to)
        ++dest;
    beginMoveRows(QModelIndex(), from, from, QModelIndex(), dest);
    _items.move(from, to);
    endMoveRows();
}

void RoleItemModel::nextOperation(int row)
{
    if (row < 0 || row >= _items.size())
        return;

    QStringList ops;
    ops << "pick" << "reword" << "edit" << "squash" << "fixup";
    auto& item = _items[row];
    QString op = item->operation;
    auto index = ops.indexOf(op);
    ++index;
    if (index == ops.size())
        index = 0;
    item->description = ops.at(index);
    auto rowIndex = this->index(row);
    emit dataChanged(rowIndex, rowIndex);
}
