import Foundation

public final class ReadWriteLock: NSLocking, @unchecked Sendable {
    public private(set) var lockPOSIX: pthread_rwlock_t

    public init() {
        self.lockPOSIX = pthread_rwlock_t()
        precondition(pthread_rwlock_init(&self.lockPOSIX, nil) == 0)
    }

    deinit {
        assert(pthread_rwlock_destroy(&self.lockPOSIX) == 0)
    }

    public func lock() {
        self.write()
    }

    public func unlock() {
        assert(pthread_rwlock_unlock(&self.lockPOSIX) == 0)
    }

    public func read() {
        precondition(pthread_rwlock_rdlock(&self.lockPOSIX) == 0)
    }

    public func write() {
        precondition(pthread_rwlock_wrlock(&self.lockPOSIX) == 0)
    }

    public func tryRead() -> Bool {
        pthread_rwlock_tryrdlock(&self.lockPOSIX) == 0
    }

    public func tryWrite() -> Bool {
        pthread_rwlock_trywrlock(&self.lockPOSIX) == 0
    }
}
