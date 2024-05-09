public typealias CompareFunction = (any Comparable, any Comparable) -> Bool

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

    private var customCompare: CompareFunction? = nil

    public init(capacity: UInt, customCompare: CompareFunction? = nil) {
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
        let leftKeys = Array(keys[0..<Int(minimumCapacity)])
        let rightKeys = Array(keys[Int(minimumCapacity + 1)...])
        let leftNode = BTreeNode(capacity: capacity, keys: leftKeys, children: [], parent: self)
        let rightNode = BTreeNode(capacity: capacity, keys: rightKeys, children: [], parent: self)
        if isRoot {
            if keys.count < capacity {
                return
            }
            keys = [keys[Int(minimumCapacity)]]
            children = [leftNode, rightNode]
            return
        }
        let index = parent!.children.firstIndex(where: { $0 === self })!

    }
    
    private func froceInsert(_ key: Int) {

    }

}

func printTree(_ node: BTreeNode<Int>, level: Int = 0) {
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

printTree(node)



