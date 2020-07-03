//
//  NSDictionary+NilSafe.m
//  NSDictionary-NilSafe
//
//  Created by Allen Hsu on 6/22/16.
//  Copyright © 2016 Glow Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "NSDictionary+NilSafe.h"

#pragma mark  设置通用的交换方法
@implementation NSObject (Swizzling)

+ (BOOL)gl_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel {
    //1、获取原生的方法和我们要交换的方法
    Method origMethod = class_getInstanceMethod(self, origSel);
    Method altMethod = class_getInstanceMethod(self, altSel);
    //2、如果两个方法有一个不存在返回NO
    if (!origMethod || !altMethod) {
        return NO;
    }
    //3、添加方法  若已经存在会添加失败
    BOOL ori = class_addMethod(self,
                               origSel,
                               class_getMethodImplementation(self, origSel),
                               method_getTypeEncoding(origMethod));
    NSLog(@"原方法添加：%@",ori?@"yes":@"no");
    
    BOOL alt = class_addMethod(self,
                               altSel,
                               class_getMethodImplementation(self, altSel),
                               method_getTypeEncoding(altMethod));
    
    NSLog(@"新方法添加：%@",alt?@"yes":@"no");
    //4、交换方法的实现
    method_exchangeImplementations(class_getInstanceMethod(self, origSel),
                                   class_getInstanceMethod(self, altSel));
    return YES;
}
//交换的类方法
+ (BOOL)gl_swizzleClassMethod:(SEL)origSel withMethod:(SEL)altSel {
    return [object_getClass((id)self) gl_swizzleMethod:origSel withMethod:altSel];
}

@end


#pragma mark 设置不可变字典的崩溃处理
@implementation NSDictionary (NilSafe)

//我们还是在load方法中实现保证一开始就被加载，dispatch_once保证在多线程下的安全执行。
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //获取原生方法以及设置需要交换的方法  两种初始化方式都涵盖到，防止因为涵盖不周到导致的崩溃。
        [self gl_swizzleMethod:@selector(initWithObjects:forKeys:count:) withMethod:@selector(gl_initWithObjects:forKeys:count:)];
        
        [self gl_swizzleClassMethod:@selector(dictionaryWithObjects:forKeys:count:) withMethod:@selector(gl_dictionaryWithObjects:forKeys:count:)];
    });
}
//字典 类方法的调用，取出所有的key和value来进行比对，安顿是否有为空
+ (instancetype)gl_dictionaryWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
    id safeObjects[cnt];
    id safeKeys[cnt];
    NSUInteger j = 0;
    for (NSUInteger i = 0; i < cnt; i++) {
        id key = keys[i];
        id obj = objects[i];
        //如果key或value有为空的情况，就跳过去
        if (!key || !obj) {
            /*
             break是结束整个循环，而continue是结束本次循环（跳过下一步），
             为了循环的继续，我们就必须选择continue.
             */
            continue;
        }
        //每一个value对应一个key，这个是相互对应的，详见demo。
        safeKeys[j] = key;
        safeObjects[j] = obj;
        j++;
    }
    //处理完毕之后，我们返回新的kay、value以及count，此时我们已经将nil的key&value清除掉了。
    return [self gl_dictionaryWithObjects:safeObjects forKeys:safeKeys count:j];
}

//在这里对数据进行重组，针对数据为空的情况，处理方式同上
- (instancetype)gl_initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
    id safeObjects[cnt];
    id safeKeys[cnt];
    NSUInteger j = 0;
    for (NSUInteger i = 0; i < cnt; i++) {
        id key = keys[i];
        id obj = objects[i];
        if (!key || !obj) {
            continue;
        }
        if (!obj) {
            obj = [NSNull null];
        }
        safeKeys[j] = key;
        safeObjects[j] = obj;
        j++;
    }
    return [self gl_initWithObjects:safeObjects forKeys:safeKeys count:j];
}

@end





#pragma mark 设置可变字典的崩溃处理
@implementation NSMutableDictionary (NilSafe)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //获取可变字典的类名。调用方法进行交换
        Class class = NSClassFromString(@"__NSDictionaryM");
        [class gl_swizzleMethod:@selector(setObject:forKey:) withMethod:@selector(gl_setObject:forKey:)];
        //为什么要使用下面的这个方法呢？
        [class gl_swizzleMethod:@selector(setObject:forKeyedSubscript:) withMethod:@selector(gl_setObject:forKeyedSubscript:)];
    });
}
//为什么在这里不讲顺序呢，这里直接使用teturn不会导致前期遍历到而导致返回，后面的数据
//int i;
- (void)gl_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    //疑问：字典里面就几个数据，但是在这里执行了几百次，我是百思不得姐，希望有朝一日能解开这个千古谜团。
    //    NSLog(@"可变数组到底调用执行了几次呢:%d",i++);
    
    if (!aKey || !anObject) {
        //结束整个函数，这里调用的数据是每次都已调用一次，这里如果改成coutinue呢? やめで ，必须要用到遍历循环中才可以使用。
        //如果这里我不做return处理呢，测试结果是崩溃，由此可以推断，可变数组中的数据是每次一对key/value进行监测的，然后遇到nil的数据就return，这样就不会返回nil的数据，相当于被过滤掉了。
        NSLog(@"遇到为nil的情况，执行一次");
        return;
    }
    [self gl_setObject:anObject forKey:aKey];
}

- (void)gl_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    //    NSLog(@"~~~~~~~可变数组到底调用执行了几次呢:%d",i++);
    
    if (!key || !obj) {
        return;
        
    }
    [self gl_setObject:obj forKeyedSubscript:key];
}

@end


