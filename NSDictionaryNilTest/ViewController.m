//
//  ViewController.m
//  NSDictionaryNilTest
//
//  Created by 张张凯 on 2018/1/31.
//  Copyright © 2018年 TRS. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //思考一:这里是否可以加个Extention呢？防止崩溃机制，等下试试看。
    
    NSString *san = nil;

    //只要nil插入了不可变数组，就会导致崩溃。所以不可能通过不可变数组来实现测试用例一
    //    NSDictionary *dic =@{@"wang":san,@"zhang":@"san",@"li":@"si"};
    //    NSLog(@"不可变字典为：%@",dic);
    //    NSLog(@"测试验证的张三李四王五有错误吗dic:%@",dic);
    
    /*
     测试用例一：如果我没有处理不可变数组，但是处理了可变数组。这样的话会崩溃吗》？
     不可变字典的赋值有两种方式：
     1、类方法：[NSMutableDictionary dictionaryWithDictionary:dic]，但是dic不可变字典就已经不能为nil了，否则直接会在dic这里就崩溃了，不会进到可变数组赋值这里，所以跟人感觉，这个可变数组的nil防崩溃处理有点多余。
     2、对象方法：
     NSMutableDictionary *mudic = [NSMutableDictionary dictionaryWithCapacity:10];
     [mudic setObject:values forKey:keys];
     这里面用key/value使用数组对应的方式，及时数组中有nil，可变字典不会崩溃 ，打印出来无非是key/value有对应不了值。在取值的时候需要注意一下。
     
     */
    
    //发现1：不可变数组的中nil后面的参数全部不会打印，也就相当于是nil之后的数据全部都是失效的。例如：数组中第一项为nil，那么这个数组中任何打印出来是空，任何数据都没有存储在里面。
    
    
    //1、第一种添加数据方式
    //    NSMutableDictionary *mudic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSMutableDictionary *mudic = [NSMutableDictionary dictionaryWithCapacity:10];
    [mudic setObject:san forKey:@"me"];
    [mudic setObject:@"sum" forKey:@"religion"];
    [mudic setObject:@"sum1" forKey:@"religion1"];
    [mudic setObject:@"sum2" forKey:@"religion2"];
    [mudic setObject:san forKey:@"metoo"];
    //2、第二种初始化方式
    //    NSMutableDictionary *mudic = [NSMutableDictionary dictionaryWithCapacity:10];
    
    
    NSLog(@"可变字典为：%@-----",mudic);
    NSLog(@"可变字典的类名：%@",NSStringFromClass(mudic.class));
    
    //    NSDictionary* d = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    //    NSLog(@"存储的：%@",d);
    
    /*
     可变字典的类名： __NSDictionaryM
     不可变字典的类名：__NSDictionaryI
     可变数组的类名：__NSArrayM
     不可变数组的类名：__NSArrayI
     延伸到出来的问题：Bar左边的视图是否是__leftViews，而非是_leftView有待验证。
     */
}



@end
