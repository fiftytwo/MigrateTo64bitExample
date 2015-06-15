/*
 * cocos2d+ext for iPhone
 *
 * Copyright (c) 2011 - Ngo Duc Hiep
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "cocos2d.h"


@interface CCBlade : CCNode
{
    NSUInteger _count;
    ccVertex2F *_vertices;
    ccVertex2F *_coordinates;
    BOOL _reset;
    BOOL _finish;
    BOOL _willPop;
    
    ccTime timeSinceLastPop;
    ccTime popTimeInterval;
}

@property (nonatomic, readonly, assign) NSInteger pointLimit;
@property(nonatomic, readwrite, strong) CCTexture2D *texture;
@property(nonatomic, readwrite, assign) CGFloat width;
@property (nonatomic, readwrite, assign) BOOL autoDim;
@property(nonatomic, readwrite, strong) CCArray *path;

+ (id)bladeWithMaximumPoint:(NSInteger)limit;
- (id)initWithMaximumPoint:(NSInteger)limit;
- (void)push:(CGPoint)v;
- (void)pop:(NSInteger)n;
- (void)clear;
- (void)reset;
- (void)dim:(BOOL)dim;
- (void)finish;

@end
