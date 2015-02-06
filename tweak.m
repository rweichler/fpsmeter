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

const CGFloat bgc[] = {
    0,
    0,
    0
};

const CGFloat tc[] = {
    1,
    1,
    1
};

static void drawToContext(CGContextRef context, int fps)
{
    //setup colors
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef bgcolor = CGColorCreate(rgbColorSpace, bgc);
    CGColorRef textcolor = CGColorCreate(rgbColorSpace, tc);
    CGColorSpaceRelease(rgbColorSpace);

    //draw bg
    CGContextSetFillColorWithColor(context, bgcolor);
    CGContextFillRect(context, CGRectMake(40,15,fps > 99 ? 165 : fps > 9 ? 150 : 130,40));

    //draw text
    CGContextSetStrokeColorWithColor(context, textcolor);
    CGContextSetFillColorWithColor(context, textcolor);

    CGContextSetLineWidth(context, 1.0);
    CGContextSelectFont(context, "Helvetica", 40, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);

    const char *text = [NSString stringWithFormat:@"%d FPS", fps].UTF8String;
    CGContextShowTextAtPoint (context, 50, 20, text, strlen(text));
}

void drawToSurface(int fps, IOSurfaceRef buffer)
{
    CGContextRef context = NULL;
    uint32_t seed;
    if(initContext(buffer, &context, &seed))
    {
        drawToContext(context, fps);
        delContext(buffer, &context, &seed);
    }
}

int IOMobileFramebufferGetMainDisplay(void **);

void yeah_breh(int fps, IOMobileFramebufferRef fb, IOSurfaceRef buffer)
{
    if(fps == -1) return;

    //draw surface from orig hook
    //drawToSurface(fps, buffer); //is an IOSurface

    //get surface from IOMobileFramebuffer
    IOSurfaceRef other_buffer; //is also an IOSurface
    IOMobileFramebufferGetLayerDefaultSurface(fb, 0, (CoreSurfaceBufferRef *)&other_buffer);
    //drawToSurface(fps, other_buffer);

    //get surface from the main buffer
    IOSurfaceRef main_buffer; //not an IOSurface... just some random pointer. :/
    IOMobileFramebufferRef main_fb;
    IOMobileFramebufferGetMainDisplay(&main_fb);
    IOMobileFramebufferGetLayerDefaultSurface(main_fb, 0, (CoreSurfaceBufferRef *)&main_buffer);
    drawToSurface(fps, main_buffer); //doesnt do anything..
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
    yeah_breh(fps, fb, buffer);

    kern_return_t result = _hook_IOMobileFramebufferSwapSetLayer(fb, layer, buffer, bounds, frame, flags);

    yeah_breh(fps, fb, buffer);


    return result;
}

#define CaptainHook(FUNC) MSHookFunction(&FUNC, MSHake(hook_ ## FUNC))

MSInitialize
{
    CaptainHook(IOMobileFramebufferSwapSetLayer);
}
