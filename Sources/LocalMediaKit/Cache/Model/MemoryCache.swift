//
//  MemoryCache.swift
//  内存缓存类
//
//  Created by 庄七七 on 2026/2/2.
//

import Foundation


internal final class MemoryCache<T>: @unchecked Sendable {
    /// 内存占用上限配置
    private let countLimit: Int
    private let costLimit: Int
    
    /// 哈希表
    private var cache: [String: Node] = [:]
    
    /// 双向链表头尾，代表最近使用和最久未使用
    private var head: Node?
    private var tail: Node?
    
    /// 当前开销
    private(set) var currentCost: Int = 0
    
    /// 当前缓存数量
    var currentCount: Int { cache.count }
    
    /// 读写锁，可并发读，顺序写
    private var lock = pthread_rwlock_t()
    
    
    
    
    // MARK: - 初始化
    init(countLimit: Int, costLimit: Int) {
        self.countLimit = countLimit
        self.costLimit = costLimit
        pthread_rwlock_init(&lock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    
    
    
    // MARK: - 公开方法
    
    /// 获取缓存值
    /// - Parameter key: 键
    /// - Returns: 值
    func get(_ key: String) -> T? {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        
        guard let node = cache[key] else { return nil }
        
        pthread_rwlock_unlock(&lock)    /// 临时接触读取锁
        pthread_rwlock_wrlock(&lock)    /// 获取写入锁
        moveToHead(node)                /// 标记节点为链表头（最近使用）
        pthread_rwlock_unlock(&lock)    /// 解除写入锁
        pthread_rwlock_rdlock(&lock)    /// 恢复读取锁，为了和defer的接触对应
        
        return node.value
    }
    
    
    /// 存入缓存[key: Value]
    /// - Parameters:
    ///   - key: 键
    ///   - value: 值
    ///   - cost: 开销
    func set(_ key: String, value: T, cost: Int) {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        
        if let existingNode = cache[key] {
        /// 如果是已缓存的节点，更新数据
            currentCost -= existingNode.cost
            currentCost += cost
            existingNode.value = value
            existingNode.cost = cost
            moveToHead(existingNode)
        } else {
        /// 新的节点，创建并缓存
            let node = Node(key: key, value: value, cost: cost)
            cache[key] = node
            currentCost += cost
            addToHead(node)
        }
        
        /// 自动检查、淘汰尾部节点
        trimIfNeeded()
    }
    
    
    /// 删除指定缓存
    /// - Parameter key: 键
    func remove(_ key: String) {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        
        guard let node = cache[key] else { return }
        
        removeNode(node)
        cache.removeValue(forKey: key)
        currentCost -= node.cost
    }
    
    
    /// 清空缓存
    func cleanup() {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        
        cache.removeAll()
        head = nil
        tail = nil
        currentCost = 0
    }
    
    
    /// 检查缓存是否存在
    func contains(_ key: String) -> Bool {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        
        return cache[key] != nil
    }
    
    
    
    
    // MARK: - 移动节点到头部
    /// 将节点移动到头部
    private func moveToHead(_ node: Node) {
        /// 检查节点是否已经是头部节点
        guard node !== head else { return }
        
        /// 先从链表结构中移除
        removeNode(node)
        
        /// 添加到链表头部
        addToHead(node)
    }
    
    
    
    
    // MARK: - 自动淘汰尾部节点
    /// 根据限制淘汰节点，从尾部向头部淘汰
    private func trimIfNeeded() {
        /// 先淘汰到数量符合要求
        while currentCount > countLimit {
            deleteTail()
        }
        
        /// 淘汰到开销也符合要求
        while currentCost > costLimit {
            deleteTail()
        }
    }
    
    
    
    
    // MARK: - 私有辅助方法
    /// 从链表结构中移除当前节点，不删除节点本身。可以做链表的位置调整
    private func removeNode(_ node: Node) {
        node.prev?.next = node.next     /// 前节点的后节点 -> 原节点的后节点
        node.next?.prev = node.prev     /// 后节点的前节点 -> 原节点的前节点
        
        /// 若移除的是链表头部，则更新头部为后节点。head没有prev了
        if node === head {
            head = node.next
        }
        
        /// 若移除的是链表尾部，则更新尾部为前节点
        if node === tail {
            tail = node.prev
        }
        
        node.prev = nil     /// 清空前节点，避免野指针
        node.next = nil     /// 清空后节点，避免野指针
    }
    
    
    /// 移除尾部节点
    private func removeTail() -> Node? {
        guard let tailNode = tail else { return nil }
        removeNode(tailNode)
        return tailNode
    }
    
    
    /// 删除尾部节点
    private func deleteTail() {
        guard let removedNode = removeTail() else { return }
        cache.removeValue(forKey: removedNode.key)      /// 删除缓存
        currentCost -= removedNode.cost
    }
    
    
    /// 将节点添加到链表头部
    private func addToHead(_ node: Node) {
        node.prev = nil     /// 设置node前节点为空
        node.next = head    /// 设置node的后节点为当前头部节点
        head?.prev = node   /// 设置当前头部节点的前节点为node
        head = node         /// 最后设置头部节点为node
        
        /// 如果只有一个节点，则同时设置node为尾部节点
        if tail == nil {
            tail = node
        }
    }
    
    
    
    
    // MARK: - 节点模型
    private final class Node {
        let key: String
        var value: T
        var cost: Int
        var prev: Node?
        var next: Node?
        
        init(key: String, value: T, cost: Int) {
            self.key = key
            self.value = value
            self.cost = cost
        }
    }
}
