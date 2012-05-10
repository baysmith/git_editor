#include "CommitModel.h"

#include <QStringList>

CommitModel::CommitModel(QObject *parent) :
    QAbstractListModel(parent)
{
    QHash<int, QByteArray> roles;
    roles[Operation] = "operation";
    roles[Sha] = "sha";
    roles[Description] = "description";

    setRoleNames(roles);
}

int CommitModel::rowCount(const QModelIndex &) const
{
    return _items.size();
}

QVariant CommitModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= _items.size())
        return QVariant();

    const auto &item = _items.at(index.row());
    switch (role) {
    case Operation:
        return QVariant::fromValue(item->operation);
    case Sha:
        return QVariant::fromValue(item->sha);
    case Qt::DisplayRole:
    case Description:
        return QVariant::fromValue(item->description);
    default:
        return QVariant();
    }
}

void CommitModel::appendRow(QSharedPointer<DataObject> data)
{
    beginInsertRows(QModelIndex(), _items.size(), _items.size());
    _items.append(data);
    endInsertRows();
}

void CommitModel::move(int from, int to)
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

void CommitModel::nextOperation(int row)
{
    if (row < 0 || row >= _items.size())
        return;

    QStringList ops;
    ops << "pick" << "reword" << "edit" << "squash" << "fixup" << "DELETE";
    auto& item = _items[row];
    QString op = item->operation;
    auto index = ops.indexOf(op);
    ++index;
    if (index == ops.size())
        index = 0;
    item->operation = ops.at(index);
    auto rowIndex = this->index(row);
    emit dataChanged(rowIndex, rowIndex);
}

QVariantMap CommitModel::get(int row)
{
    QVariantMap map;
    if (row >= 0 && row < _items.size()) {
        const auto &item = _items[row];
        map["operation"] = item->operation;
        map["sha"] = item->sha;
        map["description"] = item->description;
    }
    return map;
}
