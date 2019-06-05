#import <Foundation/Foundation.h>

/**
 * This class provides multicast delegate functionality. That is:
 * - it provides a means for managing a list of delegates
 * - any method invocations to an instance of this class are automatically forwarded to all delegates
 *
 * For example:
 *
 * // Make this method call on every added delegate (there may be several)
 * [multicastDelegate cog:self didFindThing:thing];
 *
 * This allows multiple delegates to be added to an xmpp stream or any xmpp module,
 * which in turn makes development easier as there can be proper separation of logically different code sections.
 *
 * In addition, this makes module development easier,
 * as multiple delegates can usually be handled in a manner similar to the traditional single delegate paradigm.
 *
 * This class also provides proper support for GCD queues.
 * So each delegate specifies which queue they would like their delegate invocations to be dispatched onto.
 *
 * All delegate dispatching is done asynchronously (which is a critically important architectural design).
 **/

NS_ASSUME_NONNULL_BEGIN

@interface MDMulticastDelegate<__covariant DelegateType> : NSObject

/**
 Add delegate with main queue.

 @param delegate target to invoke
 */
- (void)addDelegate:(DelegateType)delegate;

/**
 Add delegate with queue.

 @param delegate target to invoke
 @param delegateQueue queue to dispatch for invoking
 */
- (void)addDelegate:(DelegateType)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/**
 Remove delegate and all of different queues for this delegate.

 @param delegate target to remove
 */
- (void)removeDelegate:(DelegateType)delegate;

/**
 Remove delegate and queue.

 @param delegate target to remove
 @param delegateQueue queue to dispatch for invoking
 */
- (void)removeDelegate:(DelegateType)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;

/**
 Remove all delegates and queues
 */
- (void)removeAllDelegates;

/**
 Count of delegate items, maybe multiple queues of an delegate.
 */
- (NSUInteger)count;

/**
 Count of delegates.
 */
- (NSUInteger)countOfDelegates;

/**
 Count of delegate items is kind of this class, maybe multiple queues of an delegate.

 @param aClass class of delegate
 */
- (NSUInteger)countOfClass:(Class)aClass;

/**
 Count of delegate items is repsonding this selector, maybe multiple queues of an delegate.

 @param aSelector selector to repsond for delegates
 */
- (NSUInteger)countForSelector:(SEL)aSelector;

/**
 Whether there is any delegate responding selector.

 @param aSelector selector to repsond for delegates
 */
- (BOOL)hasDelegateThatRespondsToSelector:(SEL)aSelector;

/**
 Enumerate all of delegates and queues

 @param block block for selection of delegate item
 */
- (void)enumerateDelegatesAndQueuesUsingBlock:(NS_NOESCAPE void (^)(DelegateType delegate, dispatch_queue_t delegateQueue, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
