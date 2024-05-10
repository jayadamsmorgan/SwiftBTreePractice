public typealias CompareFunction<T> = (T, T) -> Bool

public struct NotImplementedError: Error {
    let message: String
}

public class BTreeNode<T: Comparable> {

    public let capacity: Int
    public var minimumCapacity: Int { return capacity / 2 }

    public var isRoot: Bool { return parent == nil }

    public var parent: BTreeNode? = nil

    private var keys: [T]
    private var children: [BTreeNode]

    public func getKeys() -> [T] {
        return keys
    }

    public func getChildren() -> [BTreeNode] {
        return children
    }

    public var leaf: Bool { return children.isEmpty }

    private var customCompare: CompareFunction<T>? = nil

    public init?(capacity: Int, customCompare: CompareFunction<T>? = nil) {
        if capacity < 1 {
            return nil
        }
        self.keys = []
        self.children = []
        self.capacity = capacity
        self.customCompare = customCompare
    }

    private init(capacity: Int, keys: [T], children: [BTreeNode], parent: BTreeNode? = nil) {
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

    public func exists(_ key: T) -> Bool {
        find(key) != nil
    }

    public func find(_ key: T) -> T? {
        for i in 0..<keys.count {
            if key < keys[i] {
                if !leaf {
                    return children[i].find(key)
                }
                return nil
            }
            if key == keys[i] {
                return keys[i]
            }
        }
        return nil
    }

    public func delete(_ key: T) -> Error? {
        return NotImplementedError(message: "Delete function not implemented yet.")
    }

    public func insert(_ key: T) {
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
        if keys.count > capacity {
            split()
        }
        keys.append(key)
        sort()
    }

    private func split() {
        if isRoot {
            if leaf {
                let leftKeys = Array(keys.prefix(upTo: minimumCapacity))
                let rightKeys = Array(keys.suffix(from: minimumCapacity + 1))
                keys = [keys[Int(minimumCapacity)]]
                let leftChild = BTreeNode<T>(capacity: capacity, keys: leftKeys, children: [], parent: self)
                let rightChild = BTreeNode<T>(capacity: capacity, keys: rightKeys, children: [], parent: self)
                children = [leftChild, rightChild]
                return
            }

        }
    }
}

func printTree<T>(_ node: BTreeNode<T>, level: Int = 0) {
    print("Level \(level): \(node.getKeys())")
    for child in node.getChildren() {
        printTree(child, level: level + 1)
    }
}

let node = BTreeNode<Int>(capacity: 4)!

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
// node.insert(21)
// node.insert(22)
printTree(node)
print("----")


