public class BTreeNode<Key: Comparable, Value> {

    unowned var owner: BTree<Key, Value>

    fileprivate var keys = [Key]()
    fileprivate var values = [Value]()
    var children: [BTreeNode]?

    var isLeaf: Bool {
        return children == nil
    }

    var numberOfKeys: Int {
        return keys.count
    }

    init(owner: BTree<Key, Value>) {
        self.owner = owner
    }

    convenience init(owner: BTree<Key, Value>, keys: [Key], values: [Value], children: [BTreeNode]? = nil) {
        self.init(owner: owner)
        self.keys += keys
        self.values += values
        self.children = children
    }

    func value(for key: Key) -> Value? {
        guard let index = keys.firstIndex(where: { $0 <= key }) else {
            return nil
        }
        if key == keys[index] { return values[index] }
        if key < keys[index] { return children?[index].value(for: key) }
        return children?[index + 1].value(for: key)
    }

    func traverseKeysInOrder(_ process: (Key) -> Void) {
        for i in 0..<numberOfKeys {
            children?[i].traverseKeysInOrder(process)
            process(keys[i])
        }
        children?.last?.traverseKeysInOrder(process)
    }

    func insert(_ value: Value, for key: Key) {
        var index = keys.startIndex

        while index < keys.endIndex && keys[index] < key {
            index = index + 1
        }

        if index < keys.endIndex && keys[index] == key {
            values[index] = value
            return
        }
        
        if isLeaf {
            keys.insert(key, at: index)
            values.insert(value, at: index)
            owner.numberOfKeys += 1
            return
        }
        guard let child = children?[index] else { return }
        child.insert(value, for: key)
        if child.numberOfKeys > owner.order * 2 {
            split(child: child, at: index)
        }
    }

    private func split(child: BTreeNode, at index: Int) {
        let middleIndex = child.numberOfKeys / 2
        keys.insert(child.keys[middleIndex], at: index)
        values.insert(child.values[middleIndex], at: index)
        child.keys.remove(at: middleIndex)
        child.values.remove(at: middleIndex)

        let rightSibling = BTreeNode(
            owner: owner,
            keys: Array(child.keys[child.keys.indices.suffix(from: middleIndex)]),
            values: Array(child.values[child.values.indices.suffix(from: middleIndex)])
        )

        child.keys.removeSubrange(child.keys.indices.suffix(from: middleIndex))
        child.values.removeSubrange(child.values.indices.suffix(from: middleIndex))

        children!.insert(rightSibling, at: index + 1)

        if var childChildren = child.children {
            rightSibling.children = Array(
                childChildren[child.children!.indices.suffix(from: middleIndex + 1)]
            )
            childChildren.removeSubrange(childChildren.indices.suffix(from: middleIndex + 1))
        }
    }

}

public class BTree<Key: Comparable, Value> {

    public let order: Int

    var rootNode: BTreeNode<Key, Value>!

    fileprivate(set) public var numberOfKeys: Int = 0

    public init?(order: Int) {
        guard order > 0 else {
            return nil
        }
        self.order = order
        rootNode = BTreeNode<Key, Value>(owner: self)
    }

}

