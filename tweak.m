#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDEventTypes.h>
#include <IOSurface/IOSurface.h>
#include <Foundation/Foundation.h>
#include <IOMobileFramebuffer.h>
#include <UIKit/UIKit.h>
typedef void * IOMobileFramebufferRef;
typedef int kern_return_t;
int CoreSurfaceBufferLock(CoreSurfaceBufferRef surface, unsigned int lockType);
int CoreSurfaceBufferUnlock(CoreSurfaceBufferRef surface);

#include <time.h>
#define Log(format, ...) NSLog(@"FPSMeter: %@", [NSString stringWithFormat: format, ## __VA_ARGS__])
#define PRIVATE_FRAMEWORKS "/System/Library/PrivateFrameworks"
#define CORESURFACE PRIVATE_FRAMEWORKS "/CoreSurface.framework/CoreSurface"

kern_return_t IOMobileFramebufferSwapSetLayer(
    IOMobileFramebufferRef fb,
    int layer,
    IOSurfaceRef buffer,
    CGRect bounds,
    CGRect frame,
    int flags
);


static clock_t _last;

static BOOL initContext(IOSurfaceRef fb_surface, CGContextRef *context, uint32_t *seed)
{
    if(IOSurfaceLock(fb_surface, 3, seed) != 0) {
        return false;
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *bufferAddress = (void *)IOSurfaceGetBaseAddress(fb_surface);

    unsigned int height = IOSurfaceGetHeight(fb_surface);
    unsigned int width = IOSurfaceGetWidth(fb_surface);
    unsigned int bytes_per_row = IOSurfaceGetBytesPerRow(fb_surface);

    *context = CGBitmapContextCreate(bufferAddress, width, height, 8, bytes_per_row, colorSpace, kCGImageAlphaNoneSkipFirst);
    CGColorSpaceRelease(colorSpace);

    return true;
}

static void delContext(IOSurfaceRef fb_surface, CGContextRef *context, uint32_t *seed)
{
    IOSurfaceUnlock(fb_surface, 3, seed);
    CGContextRelease(*context);
}

const CGFloat components[] = {
    1.0,
    0,
    0,
    1.0
};

static void drawFPS(CGContextRef context, int fps)
{
    Log(@"blow meee");
    CGColorRef red = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
    CGContextSetFillColorWithColor(context, red);
    CGContextFillRect(context, CGRectMake(0,0,100,100));
}

MSHook(kern_return_t, hook_IOMobileFramebufferSwapSetLayer,
    IOMobileFramebufferRef fb,
    int layer,
    IOSurfaceRef buffer,
    CGRect bounds,
    CGRect frame,
   int flags
) {
    clock_t time = clock();
    if(buffer != NULL && _last)
    {
        float fpsf = 1.0*CLOCKS_PER_SEC/(time - _last);
        int fps = (int)(fpsf + 0.5);
        CGContextRef context = NULL;
        uint32_t seed;
        if(initContext(buffer, &context, &seed))
        {
            drawFPS(context, fps);
            delContext(buffer, &context, &seed);
        }
        else
            Log(@"FUUUCK");
    }
    _last = time;
    return _hook_IOMobileFramebufferSwapSetLayer(fb, layer, buffer, bounds, frame, flags);
}

MSInitialize
{
    MSHookFunction(&IOMobileFramebufferSwapSetLayer, MSHake(hook_IOMobileFramebufferSwapSetLayer));
}
