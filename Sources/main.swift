public typealias CompareFunction<T> = (T, T) -> Bool

public class BTreeNode<T: Comparable> {

    public let capacity: UInt
    public var minimumCapacity: UInt { return capacity / 2 }

    public var isRoot: Bool { return parent == nil }

    public var parent: BTreeNode? = nil

    private var keys: [T]
    private var children: [BTreeNode]

    public func getKeys() -> [any Comparable] {
        return keys
    }

    public func getChildren() -> [BTreeNode] {
        return children
    }

    public var leaf: Bool { return children.isEmpty }

    private var customCompare: CompareFunction<T>? = nil

    public init(capacity: UInt, customCompare: CompareFunction<T>? = nil) {
        self.keys = []
        self.children = []
        self.capacity = capacity
        self.customCompare = customCompare
    }

    private init(capacity: UInt, keys: [T], children: [BTreeNode], parent: BTreeNode? = nil) {
        self.keys = keys
        self.children = children
        self.capacity = capacity
        self.parent = parent
    }

    private func sort() {
        if let compare = customCompare {
            keys.sort(by: compare)
        } else {
            keys.sort()
        }
    }


    func insert(_ key: T) {
        if keys.count < capacity && leaf {
            keys.append(key)
            sort()
            return
        }
        if !leaf {
            for i in 0..<keys.count {
                if key < keys[i] {
                    children[i].insert(key)
                    return
                }
            }
            children.last!.insert(key)
            return
        }
        keys.append(key)
        sort()
        if keys.count > capacity {
            split()
        }
    }

    private func split() {
        let leftKeys = Array(keys[0..<Int(minimumCapacity)])
        let rightKeys = Array(keys[Int(minimumCapacity + 1)...])
        var leftChildren: [BTreeNode] = []
        var rightChildren: [BTreeNode] = []
        if !leaf {
            leftChildren = Array(children[0..<Int(minimumCapacity) + 1])
            rightChildren = Array(children[Int(minimumCapacity + 1)...])
        }
        let leftNode = BTreeNode(capacity: capacity, keys: leftKeys, children: leftChildren, parent: self)
        for child in leftNode.children {
            child.parent = leftNode
        }
        let rightNode = BTreeNode(capacity: capacity, keys: rightKeys, children: rightChildren, parent: self)
        for child in rightNode.children {
            child.parent = rightNode
        }
        if isRoot {
            keys = [keys[Int(minimumCapacity)]]
            children = [leftNode, rightNode]
            return
        }
        // print("parent: \(parent!.keys)")
        guard let index = parent!.children.firstIndex(where: { $0 === self }) else {
            print("Error: parent does not have a reference to this node")
            print("Parent keys: \(parent!.keys)")
            print("Parent children: \(parent!.children)")
            print("This node keys: \(keys)")
            print("This node children: \(children)")
            return
        }
        parent!.keys.insert(keys[Int(minimumCapacity)], at: index)
        parent!.children.removeAll(where: { $0 === self })
        parent!.children.insert(leftNode, at: index)
        parent!.children.insert(rightNode, at: index + 1)
        if parent!.keys.count > capacity {
            parent!.split()
        }
        parent = nil
    }
}

func printTree<T>(_ node: BTreeNode<T>, level: Int = 0) {
    print("Level \(level): \(node.getKeys())")
    for child in node.getChildren() {
        printTree(child, level: level + 1)
    }
}

let node = BTreeNode<Int>(capacity: 4)

node.insert(12)
node.insert(11)
node.insert(16)
node.insert(15)
node.insert(13)
node.insert(17)
node.insert(14)
node.insert(8)
node.insert(9)
node.insert(10)
node.insert(18)
node.insert(19)
node.insert(20)
node.insert(21)
// node.insert(22)
printTree(node)
print("----")


