public enum BTreeError<Key: Comparable, Value>: Error {
    case keyNotFound(_ closeNode: BTreeNode<Key, Value>)
    case cannotMergeChildrenNil(_ closeNode: BTreeNode<Key, Value>)
    case cannotMoveChildrenNil(_ closeNode: BTreeNode<Key, Value>)
    case cannotMoveKeyIndexOutOfBounds(_ closeNode: BTreeNode<Key, Value>, index: Int)
    case cannotMoveValueIndexOutOfBounds(_ closeNode: BTreeNode<Key, Value>, index: Int)
}
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
        var index = keys.startIndex
        while index + 1 < keys.endIndex && keys[index] < key {
            index = index + 1
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
                childChildren[childChildren.indices.suffix(from: middleIndex + 1)]
            )
            childChildren.removeSubrange(childChildren.indices.suffix(from: middleIndex + 1))
        }
    }

    private var inorderPredecessor: BTreeNode {
        if isLeaf {
            return self
        }
        return children!.last!.inorderPredecessor
    }

    func remove(_ key: Key) -> BTreeError<Key, Value>? {
        var index = keys.startIndex

        while index + 1 < keys.endIndex && keys[index] < key {
            index = index + 1
        }

        if keys[index] == key {
            if isLeaf {
                keys.remove(at: index)
                values.remove(at: index)
                owner.numberOfKeys -= 1
                return nil
            }
            let predecessor = children![index].inorderPredecessor
            keys[index] = predecessor.keys.last!
            values[index] = predecessor.values.last!
            let child = children![index]
            if let error = child.remove(keys[index]) { return error }
            if child.numberOfKeys < owner.order {
                if let error = balance(child, at: index) {
                    return error
                }
            }
            return nil
        }
        if keys[index] > key {
            // left
            if let leftChild = children?[index] {
                if let error = leftChild.remove(key) { return error }
                if leftChild.numberOfKeys < owner.order {
                    if let error = balance(leftChild, at: index) {
                        return error
                    }
                }
                return nil
            }
            return .keyNotFound(self)
        }
        // right
        if let rightChild = children?[index + 1] {
            if let error = rightChild.remove(key) { return error }
            if rightChild.numberOfKeys < owner.order {
                if let error = balance(rightChild, at: index) {
                    return error
                }
            }
            return nil
        }
        return .keyNotFound(self)
    }

    fileprivate func balance(_ child: BTreeNode, at index: Int) -> BTreeError<Key, Value>? {
        if index - 1 >= 0, children![index - 1].numberOfKeys > owner.order {
            if let error = move(keyIndex: index - 1, to: child, from: children![index - 1], at: .left) {
                return error
            }
            return nil
        }
        if index + 1 < children!.count, children![index + 1].numberOfKeys > owner.order {
            if let error = move(keyIndex: index + 1, to: child, from: children![index + 1], at: .right) {
                return error
            }
            return nil
        }
        if index - 1 >= 0 {
            if let error = merge(child, at: index, to: .left) {
                return error
            }
            return nil
        }
        if let error = merge(child, at: index, to: .right) {
            return error
        }
        return nil
    }

    fileprivate func move(keyIndex index: Int, to targetNode: BTreeNode, from node: BTreeNode, at position: BTreeNodePosition) -> BTreeError<Key, Value>? {
        switch position {
        case .left:
            targetNode.keys.insert(keys[index], at: targetNode.keys.startIndex)
            targetNode.values.insert(values[index], at: targetNode.values.startIndex)
            guard let lastKey = node.keys.last else {
                return .cannotMoveKeyIndexOutOfBounds(node, index: node.keys.endIndex)
            }
            guard let lastValue = node.values.last else {
                return .cannotMoveValueIndexOutOfBounds(node, index: node.values.endIndex)
            }
            keys[index] = lastKey
            values[index] = lastValue
            node.keys.removeLast()
            node.values.removeLast()
            if !targetNode.isLeaf {
                guard var targetNodeChildren = targetNode.children else {
                    return .cannotMoveChildrenNil(targetNode)
                }
                guard let nodeChildren = node.children, let nodeChildrenLast = nodeChildren.last else {
                    return .cannotMoveChildrenNil(node)
                }
                targetNodeChildren.insert(nodeChildrenLast, at: targetNodeChildren.startIndex)
                node.children!.removeLast()
            }
        case .right:
            targetNode.keys.insert(keys[index], at: targetNode.keys.endIndex)
            targetNode.values.insert(values[index], at: targetNode.values.endIndex)
            keys[index] = node.keys.first!
            values[index] = node.values.first!
            node.keys.removeFirst()
            node.values.removeFirst()
            if !targetNode.isLeaf {
                targetNode.children!.insert(node.children!.first!, at: targetNode.children!.endIndex)
                node.children!.removeFirst()
            }
        }
        return nil
    }

    fileprivate func merge(_ child: BTreeNode, at index: Int, to position: BTreeNodePosition) -> BTreeError<Key, Value>? {
        guard var children else {
            return .cannotMergeChildrenNil(self)
        }
        switch position {
        case .left:
            let leftIndex = index - 1
            let leftSibling = children[leftIndex]
            leftSibling.keys = leftSibling.keys + [keys[leftIndex]] + child.keys
            leftSibling.values = leftSibling.values + [values[leftIndex]] + child.values
            keys.remove(at: leftIndex)
            values.remove(at: leftIndex)
            if !child.isLeaf {
                guard var leftSiblingChildren = leftSibling.children else {
                    return .cannotMergeChildrenNil(leftSibling)
                }
                guard let childChildren = child.children else {
                    return .cannotMergeChildrenNil(child)
                }
                leftSiblingChildren = leftSiblingChildren + childChildren
            }
        case .right:
            let rightIndex = index + 1
            let rightSibling = children[rightIndex]
            rightSibling.keys = rightSibling.keys + [keys[rightIndex]] + child.keys
            rightSibling.values = rightSibling.values + [values[rightIndex]] + child.values
            keys.remove(at: rightIndex)
            values.remove(at: rightIndex)
            if !child.isLeaf {
                guard var rightSiblingChildren = rightSibling.children else {
                    return .cannotMergeChildrenNil(rightSibling)
                }
                guard let childChildren = child.children else {
                    return .cannotMergeChildrenNil(child)
                }
                rightSiblingChildren = childChildren + rightSiblingChildren
            }
        }
        children.remove(at: index)
        return nil
    }

    var inorderArrayFromKeys: [Key] {
        var array = [Key]()

        for i in 0..<numberOfKeys {
            if let returnedArray = children?[i].inorderArrayFromKeys {
                array += returnedArray
            }
            array += [keys[i]]
        }

        if let returnedArray = children?.last?.inorderArrayFromKeys {
            array += returnedArray
        }

        return array
    }

    var description: String {
        var str = "\(keys)"

        if !isLeaf {
            for child in children! {
                str += child.description
            }
        }

        return str
    }

}

private enum BTreeNodePosition {
    case left
    case right
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

    public func insert(_ value: Value, for key: Key) {
        rootNode.insert(value, for: key)
        if rootNode.numberOfKeys > order * 2 {
            splitRoot()
        }
    }

    private func splitRoot() {
        let middleIndex = rootNode.numberOfKeys / 2
        let newRoot = BTreeNode(
            owner: self,
            keys: [rootNode.keys[middleIndex]],
            values: [rootNode.values[middleIndex]],
            children: [rootNode]
        )
        let newRightChild = BTreeNode(
            owner: self,
            keys: Array(rootNode.keys[rootNode.keys.indices.suffix(from: middleIndex + 1)]),
            values: Array(rootNode.values[rootNode.values.indices.suffix(from: middleIndex + 1)])
        )
        rootNode.keys.removeSubrange(rootNode.keys.indices.suffix(from: middleIndex - 1))
        rootNode.values.removeSubrange(rootNode.values.indices.suffix(from: middleIndex - 1))

        if var oldRootChildren = rootNode.children {
            newRightChild.children = Array(oldRootChildren[oldRootChildren.indices.suffix(from: middleIndex + 1)])
            oldRootChildren.removeSubrange(oldRootChildren.indices.suffix(from: middleIndex + 1))
        }

        newRoot.children?.append(newRightChild)
        rootNode = newRoot
    }

    public func remove(_ key: Key) -> BTreeError<Key, Value>? {
        guard rootNode.numberOfKeys > 0 else {
            return nil
        }
        if let error = rootNode.remove(key) {
            return error
        }
        if rootNode.numberOfKeys == 0 && !rootNode.isLeaf {
            self.rootNode = rootNode.children?.first
        }
        return nil
    }

    public func value(for key: Key) -> Value? {
        guard rootNode.numberOfKeys > 0 else {
            return nil
        }

        return rootNode.value(for: key)
    }

}

func printTree(node: BTreeNode<Int, Int>, depth: Int = 0) {
    print(" depth: \(depth): \(node.keys)")
    guard let children = node.children else {
        return
    }
    for child in children {
        printTree(node: child, depth: depth + 1)
    }
}

let btree = BTree<Int, Int>(order: 2)!

btree.insert(5, for: 15)
btree.insert(212, for: 3)
btree.insert(4, for: 14)
btree.insert(214, for: 6)
btree.insert(2, for: 12)
btree.insert(512, for: 1)
btree.insert(7, for: 17)
btree.insert(2, for: 2)
btree.insert(2, for: 4)
btree.insert(2, for: 8)
btree.insert(2, for: 5)
btree.insert(2, for: 7)
btree.insert(2, for: 6)
btree.insert(2, for: 18)
btree.insert(2, for: 19)
btree.insert(2, for: 20)
btree.insert(2, for: 22)
btree.insert(2, for: 21)

printTree(node: btree.rootNode)

