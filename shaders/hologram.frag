#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uAmplitude;
uniform float uActiveGlow;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 centered = uv * 2.0 - 1.0;
    centered.x *= uResolution.x / uResolution.y;

    float scanline = sin(uv.y * 420.0 - uTime * 8.0) * 0.04;
    float dist = length(centered);
    float pulseRadius = 0.48 + uAmplitude * 0.22 + sin(uTime * 3.5) * 0.02;
    float ring = smoothstep(pulseRadius + 0.03, pulseRadius, dist) -
                 smoothstep(pulseRadius, pulseRadius - 0.025, dist);

    float glitch = step(0.985, sin(uTime * 19.0 + uv.y * 35.0)) * 0.015 * uActiveGlow;

    vec3 baseCyan = vec3(0.0, 0.94, 1.0);
    vec3 deepBlue = vec3(0.01, 0.08, 0.22);

    float coreGlow = exp(-dist * 2.6) * (0.45 + uActiveGlow * 0.55 + uAmplitude * 0.4);
    vec3 color = mix(deepBlue, baseCyan, coreGlow + ring * 0.9);
    color += baseCyan * scanline + vec3(glitch, 0.0, glitch * 1.5);

    float alpha = clamp(coreGlow + ring + 0.15, 0.0, 0.92);
    fragColor = vec4(color, alpha);
}
