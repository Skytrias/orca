/*************************************************************************
*
*  Orca
*  Copyright 2023 Martin Fouilleul and the Orca project contributors
*  See LICENSE.txt for licensing information
*
**************************************************************************/

#include "platform/platform_memory.h"
#include "surface.h"
#include "wgpu_surface.h"

typedef struct oc_wgpu_surface
{
    oc_surface_base base;

    WGPUDevice wgpuDevice;
    WGPUSurface wgpuSurface;
    WGPUSwapChain wgpuSwapChain;
    oc_vec2 swapChainSize;

} oc_wgpu_surface;

void oc_wgpu_surface_destroy(oc_surface_base* base)
{
    oc_wgpu_surface* surface = (oc_wgpu_surface*)base;

    wgpuSurfaceRelease(surface->wgpuSurface);
    wgpuSwapChainRelease(surface->wgpuSwapChain);
    oc_surface_base_cleanup(base);
    free(surface);
}

oc_surface oc_wgpu_surface_create_for_window(WGPUInstance instance, oc_window window)
{
    oc_wgpu_surface* surface = 0;
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        surface = (oc_wgpu_surface*)oc_malloc_type(oc_wgpu_surface);
        memset(surface, 0, sizeof(oc_wgpu_surface));

        oc_surface_base_init_for_window((oc_surface_base*)surface, windowData);

        surface->base.api = OC_SURFACE_WEBGPU;
        surface->base.destroy = oc_wgpu_surface_destroy;

        WGPUSurfaceDescriptor desc = {
            .nextInChain = &((WGPUSurfaceDescriptorFromWindowsHWND){
                                 .chain.sType = WGPUSType_SurfaceDescriptorFromWindowsHWND,
                                 .hinstance = GetModuleHandle(NULL),
                                 .hwnd = surface->base.view.hWnd,
                             })
                                .chain,
        };
        surface->wgpuSurface = wgpuInstanceCreateSurface(instance, &desc);
    }
    oc_surface handle = oc_surface_nil();
    if(surface)
    {
        handle = oc_surface_handle_alloc((oc_surface_base*)surface);
    }
    return (handle);
}

WGPUSwapChain oc_wgpu_surface_get_swapchain(oc_surface handle, WGPUDevice device)
{
    WGPUSwapChain wgpuSwapChain = 0;
    oc_surface_base* base = oc_surface_from_handle(handle);
    if(base && base->api == OC_SURFACE_WEBGPU)
    {
        oc_wgpu_surface* surface = (oc_wgpu_surface*)base;
        oc_vec2 size = base->getSize(base);
        oc_vec2 scale = base->contentsScaling(base);
        size.x *= scale.x;
        size.y *= scale.y;

        if(surface->wgpuDevice != device
           || surface->wgpuSwapChain == NULL
           || surface->swapChainSize.x != size.x
           || surface->swapChainSize.y != size.y)
        {
            oc_log_info("resize swapChain\n");

            if(surface->wgpuSwapChain)
            {
                wgpuSwapChainRelease(surface->wgpuSwapChain);
                surface->wgpuSwapChain = 0;
            }

            if(surface->wgpuDevice != 0 && surface->wgpuDevice != device)
            {
                wgpuDeviceRelease(surface->wgpuDevice);
                surface->wgpuDevice = 0;
            }

            //TODO: resize mtl layer?

            if(device && size.x != 0 && size.y != 0)
            {
                surface->wgpuDevice = device;
                wgpuDeviceReference(device);

                WGPUSwapChainDescriptor desc = {
                    .width = size.x,
                    .height = size.y,
                    .usage = WGPUTextureUsage_RenderAttachment,
                    .format = WGPUTextureFormat_BGRA8Unorm,
                    .presentMode = WGPUPresentMode_Fifo,
                };
                surface->wgpuSwapChain = wgpuDeviceCreateSwapChain(surface->wgpuDevice, surface->wgpuSurface, &desc);
                if(!surface->wgpuSwapChain)
                {
                    oc_log_error("Failed to create WebGPU swap chain");
                }
            }
            surface->swapChainSize = size;
        }
        wgpuSwapChain = surface->wgpuSwapChain;
    }
    return (wgpuSwapChain);
}