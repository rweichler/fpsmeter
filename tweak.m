#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDEventTypes.h>
#include <IOSurface/IOSurface.h>
#include <Foundation/Foundation.h>
#include <IOMobileFramebuffer.h>
#include <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
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

static void drawFPS(CGContextRef context, int fps, float height)
{
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef red = CGColorCreate(rgbColorSpace, components);
    CGColorSpaceRelease(rgbColorSpace);

    CGContextSetFillColorWithColor(context, red);
    CGContextFillRect(context, CGRectMake(0,0,100,100));
}

void yeah_bro(int fps, IOSurfaceRef buffer, CGRect bounds)
{
    CGContextRef context = NULL;
    uint32_t seed;
    if(initContext(buffer, &context, &seed))
    {
        drawFPS(context, fps, bounds.size.height);
        delContext(buffer, &context, &seed);
    }
}

void yeah_breh(int fps, IOMobileFramebufferRef fb, IOSurfaceRef buffer, CGRect bounds)
{
    if(fps == -1) return;

    yeah_bro(fps, buffer, bounds);

    IOSurfaceRef other_buffer;
    IOMobileFramebufferGetLayerDefaultSurface(fb, 0, (CoreSurfaceBufferRef *)&other_buffer);
    yeah_bro(fps, other_buffer, bounds);
}

int get_fps()
{
    clock_t time = clock();
    int fps = -1;
    if(_last)
    {
        float fpsf = 1.0*CLOCKS_PER_SEC/(time - _last);
        fps = (int)(fpsf + 0.5);
    }
    _last = time;
    return fps;
}

MSHook(kern_return_t, hook_IOMobileFramebufferSwapSetLayer,
    IOMobileFramebufferRef fb,
    int layer,
    IOSurfaceRef buffer,
    CGRect bounds,
    CGRect frame,
   int flags
) {
    int fps = buffer == NULL ? -1 : get_fps();

    //idk... do it before and after %orig so it flickers less???????
    yeah_breh(fps, fb, buffer, bounds);

    kern_return_t result = _hook_IOMobileFramebufferSwapSetLayer(fb, layer, buffer, bounds, frame, flags);

    yeah_breh(fps, fb, buffer, bounds);


    return result;
}

MSInitialize
{
    MSHookFunction(&IOMobileFramebufferSwapSetLayer, MSHake(hook_IOMobileFramebufferSwapSetLayer));
}
