//
//  gradient.metal
//  face-tracking-2
//
//  Created by Sebastian Buys on 11/28/21.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

[[visible]]
void gradient(realitykit::surface_parameters params)
{
//    constexpr sampler textureSampler(coord::normalized,
//     address::repeat,
//     filter::linear,
//     mip_filter::linear);
    
    // Custom parameters
    // float opacity = params.uniforms().custom_parameter()[0];
    

    // Roughness and metallic values
    float roughnessValue = 0.0;
    float metallicValue = 0.0;
    
    // Get texture coordinates.
    float2 uv = params.geometry().uv0();

    // Flip the texture coordinates y-axis. This is only needed for entities
    // loaded from USDZ or .reality files.
    // uv.y = 1.0 - uv.y;
    
    // Sample material textures
    // auto tex = params.textures();
    
    float speed = 2.0;
    float time = params.uniforms().time();
    float offset = time * speed;
    
    float2 uvOffset = uv;
    uvOffset.y = (sin(uv.x + offset) + 1) / 2.0;
    uvOffset.x = uv.x + offset;
    
    half r = half(uvOffset.y);
    half g = half(uvOffset.x);
    half b = half(1.0);
    
    half3 color = half3(r, g, b);

    params.surface().set_base_color(color);
    // params.surface().set_normal(normal);
    params.surface().set_roughness(roughnessValue);
    params.surface().set_metallic(metallicValue);
    
    // Opacity
    // params.surface().set_opacity(float(0.5));
}





