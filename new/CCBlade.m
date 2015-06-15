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

#include <tgmath.h>
#import "CCBlade.h"


NS_INLINE float fangle(CGPoint vect)
{
    if (vect.x == 0 && vect.y == 0)
    {
        return 0;
    }

    if (vect.x == 0)
    {
        return vect.y > 0 ? (float)M_PI / 2 : -(float)M_PI / 2;
    }

    if (vect.y == 0.0 && vect.x < 0) {
        return -(float)M_PI;
    }

    float angle = atanf((float)(vect.y / vect.x));

    return vect.x < 0 ? angle + (float)M_PI : angle;
}


NS_INLINE void f1(CGPoint p1, CGPoint p2, CGFloat d, ccVertex2F *o1, ccVertex2F *o2)
{
    CGFloat l = ccpDistance(p1, p2);
    
    float angle = fangle(ccpSub(p2, p1));

    CGPoint p = ccpRotateByAngle(ccp(p1.x + l, p1.y + d), p1, angle);
    o1->x = (GLfloat)p.x;
    o1->y = (GLfloat)p.y;

    p = ccpRotateByAngle(ccp(p1.x + l, p1.y - d), p1, angle);
    o2->x = (GLfloat)p.x;
    o2->y = (GLfloat)p.y;
}


__unused NS_INLINE CGFloat lagrange1(CGPoint p1, CGPoint p2, CGFloat x)
{
    return (x - p1.x) / (p2.x - p1.x) * p2.y + (x - p2.x) / (p1.x - p2.x) * p1.y;
}


@implementation CCBlade


+ (id)bladeWithMaximumPoint:(NSInteger)limit
{
    return [[[self alloc] initWithMaximumPoint:limit] autorelease];
}


#define POP_TIME_INTERVAL    ( (ccTime)1 / (ccTime)60 )


- (id)initWithMaximumPoint:(NSInteger)limit
{
    self = [super init];
    
    _pointLimit = limit;
    _width = 5;

    _vertices = (ccVertex2F *)calloc(2 * (NSUInteger)limit + 5, sizeof(_vertices[0]));
    _coordinates = (ccVertex2F *)calloc(2 * (NSUInteger)limit + 5, sizeof(_coordinates[0]));
    _coordinates[0].x = 0.0f;
    _coordinates[0].y = 0.5f;

    _reset = NO;

    _path = [[CCArray alloc] init];

    popTimeInterval = POP_TIME_INTERVAL;
    
    timeSinceLastPop = 0;
    [self scheduleUpdateWithPriority:0];
    
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];
    
    return self;
}


- (void)dealloc
{
    [_path release];

    free(_coordinates);
    free(_vertices);

    [super dealloc];
}


- (void)populateVertices
{
    CGPoint it = [[_path objectAtIndex:0] CGPointValue];

    _vertices[0].x = (GLfloat)it.x;
    _vertices[0].y = (GLfloat)it.y;

    CGPoint pre = it;
    
    NSInteger i = 0, m, n;
    it = [[_path objectAtIndex:1] CGPointValue];

    CGFloat dd = _width / [_path count];

    while (i < (NSInteger)[_path count] - 2)
    {
        m = 2 * i + 1;
        n = 2 * i + 2;

        f1(pre, it, _width - i * dd , _vertices + m, _vertices + n);

        _coordinates[m] = (ccVertex2F){ 0.5f, 1.0f };
        _coordinates[n] = (ccVertex2F){ 0.5f, 0.0f };

        i++;
        pre = it;

        it = [[_path objectAtIndex:(NSUInteger)i + 1] CGPointValue];
    }

    _coordinates[1] = (ccVertex2F){ 0.25f, 1.0f };
    _coordinates[2] = (ccVertex2F){ 0.25f, 0.0f };

    m = 2 * (NSInteger)[_path count] - 3;

    if (m >= 0)
    {
        _vertices[m] = (ccVertex2F){(GLfloat)it.x, (GLfloat)it.y};
        _coordinates[m] = (ccVertex2F){0.75f, 0.5f};
    }
}


- (void)shift
{
    NSInteger index = 2 * _pointLimit - 1;

    for (NSInteger i = index; i > 3; i -= 2)
    {
        _vertices[i] = _vertices[i - 2];
        _vertices[i - 1] = _vertices[i - 3];
    }
}


- (void)push:(CGPoint)v
{
    static const CGFloat distanceToInterpolate = (CGFloat)10;
    
    _willPop = NO;
    
    if (_reset)
    {
        return;
    }
    
    if ([_path count] == 0)
    {
        [_path insertObject:[NSValue valueWithCGPoint:v] atIndex:0];
        return;
    }
    
    CGPoint first = [[_path objectAtIndex:0] CGPointValue];
    if (ccpDistance(v, first) < distanceToInterpolate)
    {
        [_path insertObject:[NSValue valueWithCGPoint:v] atIndex:0];
        if ((NSInteger)[_path count] > _pointLimit)
        {
            [_path removeLastObject];
        }
    }
    else
    {
        NSInteger num = (NSInteger)(ccpDistance(v, first) / distanceToInterpolate);
        CGPoint iv = ccpMult(ccpSub(v, first), (CGFloat)1 / (num + 1));
        for (NSInteger i = 1; i <= num + 1; i++)
        {
            [_path insertObject:[NSValue valueWithCGPoint:ccpAdd(first, ccpMult(iv, i))] atIndex:0];
        }
        while ((NSInteger)[_path count] > _pointLimit)
        {
            [_path removeLastObject];
        }
    }

    [self populateVertices];
}


- (void)pop:(NSInteger)n
{
    while ([_path count] > 0 && n > 0)
    {
        [_path removeLastObject];
        n--;
    }
    
    if ([_path count] > 2)
    {
        [self populateVertices];
    }
}


- (void)clear
{
    [_path removeAllObjects];

    _reset = NO;

    if (_finish)
        [self removeFromParentAndCleanup:YES];
}


- (void)reset
{
    _reset = TRUE;
}


- (void)dim:(BOOL)dim
{
    _reset = dim;
}


- (void)update:(ccTime)dt
{
    static const ccTime precision = POP_TIME_INTERVAL;
    
    timeSinceLastPop += dt;

    ccTime roundedTimeSinceLastPop = precision * __tg_round(timeSinceLastPop / precision);
    
    NSInteger numberOfPops = (NSInteger)(roundedTimeSinceLastPop / popTimeInterval) ;
    timeSinceLastPop = timeSinceLastPop - numberOfPops * popTimeInterval;
    
    for (NSInteger pop = 0; pop < numberOfPops; pop++)
    {
        if ((_reset && [_path count] > 0) || (self.autoDim && _willPop))
        {
            [self pop:1];

            if ([_path count] < 3)
            {
                [self clear];

                if (_finish)
                {
                    return;
                }
            }
        }
        
    }
}


- (void)draw
{
    if(_path == nil)
        return;
    
    if ([_path count] < 3)
    {
        return;
    }
    
    _willPop = YES;

    CC_NODE_DRAW_SETUP();

    ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position |  kCCVertexAttribFlag_TexCoords);
    
    ccGLBindTexture2D( [_texture name] );
    ccGLBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);

    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, _vertices);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0, _coordinates);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 2 * (GLsizei)[_path count] - 2);

    CC_INCREMENT_GL_DRAWS(1);
}


- (void)finish
{
    _finish = YES;
}


@end
