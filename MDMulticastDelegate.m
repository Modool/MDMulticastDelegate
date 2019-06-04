#import "MDMulticastDelegate.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * How does this class work?
 *
 * In theory, this class is very straight-forward.
 * It provides a way for multiple delegates to be called, each on its own delegate queue.
 *
 * In other words, any delegate method call to this class
 * will get forwarded (dispatch_async'd) to each added delegate.
 *
 * Important note concerning thread-safety:
 *
 * This class is designed to be used from within a single dispatch queue.
 * In other words, it is NOT thread-safe, and should only be used from within the external dedicated dispatch_queue.
 **/

@interface MDMulticastDelegate () {
    NSRecursiveLock *_lock;
    NSMapTable<id, NSOrderedSet<dispatch_queue_t> *> *_delegates;
}

- (NSInvocation *)duplicateInvocation:(NSInvocation *)origInvocation;

@end

@implementation MDMulticastDelegate

- (instancetype)init {
    if (self = [super init]) {
        _lock = [[NSRecursiveLock alloc] init];
        _delegates = [NSMapTable<id, NSOrderedSet<dispatch_queue_t> *> weakToStrongObjectsMapTable];
    }
    return self;
}

#pragma mark - private

- (void)_addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    NSOrderedSet<dispatch_queue_t> *queues = [_delegates objectForKey:delegate];
    NSMutableOrderedSet<dispatch_queue_t> *mutableQueues = queues ? [queues mutableCopy] : [NSMutableOrderedSet orderedSet];
    [mutableQueues addObject:delegateQueue];

    [_delegates setObject:mutableQueues.copy forKey:delegate];
}

- (void)_removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    if (delegate) {
        NSOrderedSet<dispatch_queue_t> *queues = [_delegates objectForKey:delegate];
        if (![queues containsObject:delegateQueue]) return;

        NSMutableOrderedSet<dispatch_queue_t> *mutableQueues = queues ? [queues mutableCopy] : [NSMutableOrderedSet<dispatch_queue_t> orderedSet];
        [mutableQueues removeObject:delegateQueue];

        if (mutableQueues.count) [_delegates setObject:mutableQueues.copy forKey:delegate];
        else [_delegates removeObjectForKey:delegate];
    } else {
        [_delegates removeObjectForKey:delegate];
    }
}

- (NSUInteger)_count {
    NSMapTable<id, NSOrderedSet<dispatch_queue_t> *> *delegates = [_delegates copy];
    NSEnumerator<NSOrderedSet<dispatch_queue_t> *> *enumerator = [delegates objectEnumerator];

    NSUInteger count = 0;
    NSOrderedSet<dispatch_queue_t> *queues = nil;
    while ((queues = enumerator.nextObject)) {
        count += queues.count;
    }
    return count;
}

- (NSUInteger)_countOfDelegateBlock:(BOOL (^)(id delegate))block {
    if (!block) return 0;

    NSMapTable<id, NSOrderedSet<dispatch_queue_t> *> *delegates = [_delegates copy];
    NSEnumerator *enumerator = [delegates keyEnumerator];
    NSUInteger count = 0;

    id delegate = nil;
    while ((delegate = enumerator.nextObject) && block(delegate)) {
        NSOrderedSet<dispatch_queue_t> *queues = [delegates objectForKey:delegate];

        count += queues.count;
    }
    return count;
}

- (BOOL)_hasDelegateThatRespondsToSelector:(SEL)aSelector {
    NSMapTable<id, NSOrderedSet<dispatch_queue_t> *> *delegates = [_delegates copy];

    NSEnumerator *enumerator = [delegates keyEnumerator];
    id delegate = nil;
    while ((delegate = enumerator.nextObject)) {
        if ([delegate respondsToSelector:aSelector]) return YES;
    }
    return NO;
}

- (void)_enumerateDelegateAndQueuesUsingBlock:(void (^)(id delegate, dispatch_queue_t delegateQueue, BOOL *stop))block {
    NSMapTable<id, NSOrderedSet<dispatch_queue_t> *> *delegates = [_delegates copy];
    NSEnumerator *enumerator = [delegates keyEnumerator];

    id delegate = nil;
    while ((delegate = enumerator.nextObject)) {
        BOOL stop = NO;

        NSOrderedSet<dispatch_queue_t> *queues = [_delegates objectForKey:delegate];
        for (dispatch_queue_t queue in queues) {
            block(delegate, queue, &stop);

            if (stop) break;
        }
        if (stop) break;
    }
}

- (void)_invokeWithDelegate:(id)delegate queues:(NSOrderedSet *)queues invocation:(NSInvocation *)invocation {
    for (dispatch_queue_t queue in queues) {
        // All delegates MUST be invoked ASYNCHRONOUSLY.
        NSInvocation *dupInvocation = [self duplicateInvocation:invocation];

        dispatch_async(queue, ^{ @autoreleasepool {
            [dupInvocation invokeWithTarget:delegate];
        }});
    }
}

- (void)_throwExceptionAtIndex:(NSUInteger)index type:(const char *)type selector:(SEL)selector {
    NSString *selectorStr = NSStringFromSelector(selector);

    NSString *format = @"Argument %lu to method %@ - Type(%c) not supported";
    NSString *reason = [NSString stringWithFormat:format, (unsigned long)(index - 2), selectorStr, *type];

    [[NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil] raise];
}

- (void)_copyValueAtIndex:(NSUInteger)index type:(const char *)type fromInvocation:(NSInvocation *)fromInvocation toInvocation:(NSInvocation *)toInvocation {
    NSUInteger size = 0;
    NSUInteger align = 0;
    NSGetSizeAndAlignment(type, &size, &align);

    void *buffer = malloc(size);

    [fromInvocation getArgument:buffer atIndex:index];
    [toInvocation setArgument:buffer atIndex:index];

    free(buffer);
}

#pragma mark - public

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    if (delegate == nil) return;
    if (delegateQueue == NULL) return;

    [_lock lock];
    [self _addDelegate:delegate delegateQueue:delegateQueue];
    [_lock unlock];
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    if (delegate == nil) return;

    [_lock lock];
    [self _removeDelegate:delegate delegateQueue:delegateQueue];
    [_lock unlock];
}

- (void)removeDelegate:(id)delegate {
    [self removeDelegate:delegate delegateQueue:NULL];
}

- (void)removeAllDelegates {
    [_lock lock];
    [_delegates removeAllObjects];
    [_lock unlock];
}

- (NSUInteger)count {
    [_lock lock];
    NSUInteger count = [self _count];
    [_lock unlock];
    return count;
}

- (NSUInteger)countOfClass:(Class)aClass {
    [_lock lock];
    NSUInteger count = [self _countOfDelegateBlock:^BOOL(id delegate) {
        return [delegate isKindOfClass:aClass];
    }];
    [_lock unlock];
    return count;
}

- (NSUInteger)countForSelector:(SEL)aSelector {
    [_lock lock];
    NSUInteger count = [self _countOfDelegateBlock:^BOOL(id delegate) {
        return [delegate respondsToSelector:aSelector];
    }];
    [_lock unlock];

    return count;
}

- (BOOL)hasDelegateThatRespondsToSelector:(SEL)aSelector {
    [_lock lock];
    BOOL responds = [self _hasDelegateThatRespondsToSelector:aSelector];
    [_lock unlock];
    return responds;
}

- (NSEnumerator *)delegateEnumerator {
    [_lock lock];
    NSEnumerator *enumerator = _delegates.keyEnumerator;
    [_lock unlock];
    return enumerator;
}

- (NSArray<dispatch_queue_t> *)delegateQueuesForDelegate:(id)delegate {
    [_lock lock];
    NSArray<dispatch_queue_t> *queues = [[_delegates objectForKey:delegate] array];
    [_lock unlock];
    return queues;
}

- (void)enumerateDelegateAndQueuesUsingBlock:(void (^)(id delegate, dispatch_queue_t delegateQueue, BOOL *stop))block {
    [_lock lock];
    [self _enumerateDelegateAndQueuesUsingBlock:block];
    [_lock unlock];
}

#pragma mark - protected

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSEnumerator *enumerator = [_delegates keyEnumerator];
    id delegate = nil;
    while ((delegate = enumerator.nextObject)) {
        NSMethodSignature *result = [delegate methodSignatureForSelector:aSelector];

        if (result) return result;
    }
    // This causes a crash...
    // return [super methodSignatureForSelector:aSelector];

    // This also causes a crash...
    // return nil;
    return [[self class] instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL selector = [invocation selector];

    NSMapTable *delegates = [_delegates copy];
    NSEnumerator *enumerator = [delegates keyEnumerator];

    id delegate = nil;
    while ((delegate = enumerator.nextObject)) {
        if (![delegate respondsToSelector:selector]) continue;

        NSOrderedSet<dispatch_queue_t> *delegateQueues = [delegates objectForKey:delegate];
        [self _invokeWithDelegate:delegate queues:delegateQueues invocation:invocation];
    }
}

- (void)doesNotRecognizeSelector:(SEL)aSelector {
    // Prevent NSInvalidArgumentException
}

- (void)doNothing {}

- (void)dealloc {
    [self removeAllDelegates];
}

- (NSInvocation *)duplicateInvocation:(NSInvocation *)origInvocation {
    NSMethodSignature *methodSignature = [origInvocation methodSignature];

    NSInvocation *dupInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    dupInvocation.selector = [origInvocation selector];

    NSUInteger i, count = [methodSignature numberOfArguments];
    for (i = 2; i < count; i++) {
        const char *type = [methodSignature getArgumentTypeAtIndex:i];
        switch (*type) {
            // void
            case 'v': break;
            // char
            case 'c':
            // unsigned char
            case 'C': {
                char value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // short
            case 's':
            // unsigned short
            case 'S': {
                short value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // int
            case 'i':
            // unsigned int
            case 'I': {
                int value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // long
            case 'l':
            // long
            case 'L': {
                long value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // long long
            case 'q':
            // unsigned long long
            case 'Q': {
                long long value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // float
            case 'f': {
                float value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // double
            case 'd': {
                double value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // long double
            case 'D': {
                long double value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // bool
            case 'B': {
                BOOL value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // selector
            case ':': {
                SEL value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // c string char *
            case '*':
            // OC object
            case '@':
            // pointer
            case '^': {
                void *value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
            // struct
            case '{': [self _copyValueAtIndex:i type:type fromInvocation:origInvocation toInvocation:dupInvocation]; break;
            // c array
            case '[':
            // c union
            case '(':
            // bitfield
            case 'b':
            // no type
            case 0:
            default: [self _throwExceptionAtIndex:i type:type selector:[origInvocation selector]]; break;
        }
    }
    [dupInvocation retainArguments];

    return dupInvocation;
}

@end
