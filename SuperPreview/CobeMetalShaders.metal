#include <metal_stdlib>

using namespace metal;

constant float cobePi = 3.14159265358979323846;
constant float cobeTau = 6.28318530717958647692;
constant float cobeSqrt5 = 2.23606797749978969640;
constant float cobePhi = 1.61803398874989484820;
constant float cobeGlobeRadius = 0.8;

struct CobeGlobeUniforms {
    float2 resolution;
    float2 offset;
    float2 rotation;
    float dots;
    float scale;
    float4 baseColor;
    float4 landColor;
    float4 glowColor;
    float4 renderParams;
    float4 mapSettings;
};

struct CobeMarkerUniforms {
    float2 resolution;
    float2 offset;
    float2 rotation;
    float scale;
    float markerElevation;
    float4 markerColor;
    float4 animation;
};

struct CobeArcUniforms {
    float2 resolution;
    float2 offset;
    float2 rotation;
    float scale;
    float markerElevation;
    float4 arcColor;
    float4 animation;
};

struct CobeMarkerInstance {
    float4 positionAndSize;
    float2 screenOffset;
    float4 colorAndHasColor;
    float4 animation;
};

struct CobeArcInstance {
    float4 from;
    float4 to;
    float4 heightAndWidth;
    float4 colorAndHasColor;
};

struct CobeGlobeVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct CobeMarkerVertexOut {
    float4 position [[position]];
    float2 uv;
    float3 color;
    float hasColor;
    float opacity;
};

struct CobeArcVertexOut {
    float4 position [[position]];
    float3 color;
    float hasColor;
    float depth;
    float radialDistance;
    float opacity;
};

constant float2 cobeQuad[6] = {
    float2(-1.0, -1.0),
    float2(1.0, -1.0),
    float2(-1.0, 1.0),
    float2(-1.0, 1.0),
    float2(1.0, -1.0),
    float2(1.0, 1.0)
};

float3 cobeRotate(float3 point, float phi, float theta) {
    float cx = cos(theta);
    float cy = cos(phi);
    float sx = sin(theta);
    float sy = sin(phi);

    return float3(
        cy * point.x + sy * point.z,
        sy * sx * point.x + cx * point.y - cy * sx * point.z,
        -sy * cx * point.x + sx * point.y + cy * cx * point.z
    );
}

// The marker pass rotates a geographic/world point into view space with
// cobeRotate. The globe pass starts with a view-space ray, so it must apply
// the inverse transform before looking up the geographic map. This is the
// Metal equivalent of COBE's GLSL `p * rot`.
float3 cobeViewToGlobe(float3 point, float phi, float theta) {
    float cx = cos(theta);
    float cy = cos(phi);
    float sx = sin(theta);
    float sy = sin(phi);

    return float3(
        cy * point.x + sy * sx * point.y - sy * cx * point.z,
        cx * point.y + sx * point.z,
        sy * point.x - cy * sx * point.y + cy * cx * point.z
    );
}

struct CobeLatticeResult {
    float3 point;
    float distance;
};

CobeLatticeResult cobeNearestFibonacciLattice(float3 point, float dots) {
    point = point.xzy;

    float byDots = 1.0 / dots;
    float k = max(
        2.0,
        floor(log2(cobeSqrt5 * dots * cobePi * (1.0 - point.z * point.z)) * 0.72021)
    );

    float2 f = floor(pow(cobePhi, k) / cobeSqrt5 * float2(1.0, cobePhi) + 0.5);
    float2 br1 = fract((f + 1.0) * (cobePhi - 1.0)) * cobeTau - 3.883222;
    float2 br2 = -2.0 * f;
    float2 sphericalPoint = float2(atan2(point.y, point.x), point.z - 1.0);
    float denominator = br1.x * br2.y - br2.x * br1.y;
    float2 cell = floor(float2(
        br2.y * sphericalPoint.x - br1.y * (sphericalPoint.y * dots + 1.0),
        -br2.x * sphericalPoint.x + br1.x * (sphericalPoint.y * dots + 1.0)
    ) / denominator);

    float minimumDistance = cobePi;
    float3 nearestPoint = float3(0.0);

    for (int sampleIndex = 0; sampleIndex < 4; ++sampleIndex) {
        float sample = float(sampleIndex);
        float2 cellOffset = float2(fmod(sample, 2.0), floor(sample * 0.5));
        float index = dot(f, cell + cellOffset);
        if (index > dots) {
            continue;
        }

        float a = index;
        float b = 0.0;
        if (a >= 16384.0) { a -= 16384.0; b += 0.868872; }
        if (a >= 8192.0) { a -= 8192.0; b += 0.934436; }
        if (a >= 4096.0) { a -= 4096.0; b += 0.467218; }
        if (a >= 2048.0) { a -= 2048.0; b += 0.733609; }
        if (a >= 1024.0) { a -= 1024.0; b += 0.866804; }
        if (a >= 512.0) { a -= 512.0; b += 0.433402; }
        if (a >= 256.0) { a -= 256.0; b += 0.216701; }
        if (a >= 128.0) { a -= 128.0; b += 0.108351; }
        if (a >= 64.0) { a -= 64.0; b += 0.554175; }
        if (a >= 32.0) { a -= 32.0; b += 0.777088; }
        if (a >= 16.0) { a -= 16.0; b += 0.888544; }
        if (a >= 8.0) { a -= 8.0; b += 0.944272; }
        if (a >= 4.0) { a -= 4.0; b += 0.472136; }
        if (a >= 2.0) { a -= 2.0; b += 0.236068; }
        if (a >= 1.0) { a -= 1.0; b += 0.618034; }

        float sampleTheta = fract(b) * cobeTau;
        float cosPhi = 1.0 - 2.0 * index * byDots;
        float sinPhi = sqrt(max(0.0, 1.0 - cosPhi * cosPhi));
        float3 candidate = float3(
            cos(sampleTheta) * sinPhi,
            sin(sampleTheta) * sinPhi,
            cosPhi
        );
        float distance = length(point - candidate);

        if (distance < minimumDistance) {
            minimumDistance = distance;
            nearestPoint = candidate;
        }
    }

    CobeLatticeResult result;
    result.point = nearestPoint.xzy;
    result.distance = minimumDistance;
    return result;
}

vertex CobeGlobeVertexOut cobeGlobeVertex(uint vertexID [[vertex_id]]) {
    CobeGlobeVertexOut output;
    float2 position = cobeQuad[vertexID];
    output.position = float4(position, 0.0, 1.0);
    output.uv = position * 0.5 + 0.5;
    return output;
}

fragment float4 cobeGlobeFragment(
    CobeGlobeVertexOut input [[stage_in]],
    constant CobeGlobeUniforms& uniforms [[buffer(0)]],
    texture2d<float> mapTexture [[texture(0)]],
    sampler mapSampler [[sampler(0)]]
) {
    float2 inverseResolution = 1.0 / uniforms.resolution;
    float2 uv = input.uv * 2.0 - 1.0;
    uv = uv / uniforms.scale
        - uniforms.offset * float2(1.0, -1.0) * inverseResolution;
    uv.x *= uniforms.resolution.x * inverseResolution.y;

    float squaredDistance = dot(uv, uv);
    float glowFactor = 0.0;
    float4 color = float4(0.0);

    if (squaredDistance <= cobeGlobeRadius * cobeGlobeRadius) {
        float3 spherePoint = normalize(float3(
            uv,
            sqrt(max(0.0, cobeGlobeRadius * cobeGlobeRadius - squaredDistance))
        ));
        float dotNL = spherePoint.z;

        CobeLatticeResult lattice = cobeNearestFibonacciLattice(
            cobeViewToGlobe(
                spherePoint,
                uniforms.rotation.x,
                uniforms.rotation.y
            ),
            uniforms.dots
        );
        float globePhi = asin(lattice.point.y);
        float globeTheta = acos(-lattice.point.x / max(cos(globePhi), 0.0001));
        if (lattice.point.z < 0.0) {
            globeTheta = -globeTheta;
        }

        float2 mapUV = float2(
            (globeTheta * 0.5) / cobePi,
            -(globePhi / cobePi + 0.5)
        );
        float mapTextureColor = mapTexture.sample(mapSampler, mapUV).r;
        float mapColor = max(mapTextureColor, uniforms.mapSettings.x);
        float3 nearestViewPoint = cobeRotate(
            lattice.point,
            uniforms.rotation.x,
            uniforms.rotation.y
        );
        float aspect = uniforms.resolution.x / max(uniforms.resolution.y, 1.0);
        float2 latticeDelta = (spherePoint.xy - nearestViewPoint.xy)
            * float2(1.0 / aspect, 1.0);
        float dotDistance = length(latticeDelta);
        // Keep a filled circular core and reserve only the outer edge for
        // anti-aliasing. The radius is unchanged from the previous square
        // dot, so this only changes the shape of the land points.
        float dotCoverage = 1.0 - smoothstep(
            0.006,
            0.008,
            dotDistance
        );
        float dotSample = mapColor
            * dotCoverage
            * pow(max(dotNL, 0.0), uniforms.renderParams.y)
            * uniforms.renderParams.x;

        float3 colorFactor = mix(
            (1.0 - dotSample) * pow(max(dotNL, 0.0), 0.4),
            dotSample,
            uniforms.renderParams.z
        ) + 0.1;
        // The map texture is a land mask. Keep its ambient floor behavior for
        // the original COBE shading, but use the dynamic text2 value
        // for the actual land dots instead of tinting them with baseColor.
        float landDotMask = step(0.5, mapTextureColor) * dotCoverage;
        float3 globeColor = mix(
                uniforms.baseColor.xyz * colorFactor,
                uniforms.landColor.xyz,
                landDotMask
            )
            + pow(1.0 - dotNL, 4.0) * uniforms.glowColor.xyz;
        color = float4(globeColor, 1.0) * (1.0 + uniforms.renderParams.w) * 0.5;

        glowFactor = (1.0 - squaredDistance) * (1.0 - squaredDistance)
            * smoothstep(
                0.0,
                1.0,
                0.2 / (squaredDistance - cobeGlobeRadius * cobeGlobeRadius)
            );
    } else {
        float outsideDistance = sqrt(
            0.2 / (squaredDistance - cobeGlobeRadius * cobeGlobeRadius)
        );
        glowFactor = smoothstep(
            0.5,
            1.0,
            outsideDistance / (outsideDistance + 1.0)
        );
    }

    return color + float4(uniforms.glowColor.xyz * glowFactor, glowFactor);
}

vertex CobeMarkerVertexOut cobeMarkerVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant CobeMarkerUniforms& uniforms [[buffer(0)]],
    device const CobeMarkerInstance* instances [[buffer(1)]]
) {
    CobeMarkerInstance marker = instances[instanceID];
    float2 position = cobeQuad[vertexID];
    float3 point = marker.positionAndSize.xyz
        * (cobeGlobeRadius + uniforms.markerElevation);
    float3 rotatedPoint = cobeRotate(
        point,
        uniforms.rotation.x,
        uniforms.rotation.y
    );

    CobeMarkerVertexOut output;
    output.uv = position;
    output.color = marker.colorAndHasColor.xyz;
    output.hasColor = marker.colorAndHasColor.w;
    output.opacity = 1.0;
    if (marker.animation.y > 0.0) {
        float age = max(uniforms.animation.x - marker.animation.x, 0.0);
        // Match the arc reveal duration: destination fades in over its final 20%.
        float progress = clamp(age / (marker.animation.y * 0.55), 0.0, 1.0);
        output.opacity = smoothstep(marker.animation.z, marker.animation.w, progress)
            * (1.0 - smoothstep(marker.animation.y * 0.78, marker.animation.y, age));
    }

    if (rotatedPoint.z < 0.0
        && length(rotatedPoint.xy) < cobeGlobeRadius) {
        output.position = float4(2.0, 2.0, 0.0, 1.0);
        return output;
    }

    float inverseAspect = uniforms.resolution.y / uniforms.resolution.x;
    float2 screenPosition = (rotatedPoint.xy
        + position * marker.positionAndSize.w * 2.0)
        * float2(inverseAspect, 1.0)
        * uniforms.scale
        + uniforms.offset * float2(1.0, -1.0)
        * uniforms.scale
        / uniforms.resolution;
    screenPosition += marker.screenOffset * float2(2.0, -2.0);
    output.position = float4(screenPosition, 0.0, 1.0);
    return output;
}

fragment float4 cobeMarkerFragment(
    CobeMarkerVertexOut input [[stage_in]],
    constant CobeMarkerUniforms& uniforms [[buffer(0)]]
) {
    if (length(input.uv) > 0.25) {
        discard_fragment();
    }
    float3 color = input.hasColor > 0.5
        ? input.color
        : uniforms.markerColor.xyz;
    return float4(color, input.opacity);
}

float3 cobeBezierPoint(float3 p0, float3 p1, float3 p2, float t) {
    float oneMinusT = 1.0 - t;
    return oneMinusT * oneMinusT * p0
        + 2.0 * oneMinusT * t * p1
        + t * t * p2;
}

float3 cobeBezierTangent(float3 p0, float3 p1, float3 p2, float t) {
    float oneMinusT = 1.0 - t;
    return 2.0 * oneMinusT * (p1 - p0) + 2.0 * t * (p2 - p1);
}

vertex CobeArcVertexOut cobeArcVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant CobeArcUniforms& uniforms [[buffer(0)]],
    device const CobeArcInstance* instances [[buffer(1)]]
) {
    CobeArcInstance arc = instances[instanceID];
    float endpointRadius = cobeGlobeRadius + uniforms.markerElevation;
    float3 from = arc.from.xyz * endpointRadius;
    float3 to = arc.to.xyz * endpointRadius;
    float3 midpointSum = arc.from.xyz + arc.to.xyz;
    float midpointLength = length(midpointSum);
    float3 midpointDirection = midpointLength > 0.001
        ? midpointSum / midpointLength
        : float3(0.0, 1.0, 0.0);
    float3 midpoint = midpointDirection
        * (cobeGlobeRadius + arc.heightAndWidth.x);

    uint segmentIndex = vertexID / 2;
    // duration == 0 preserves the static arcs used by equity tabs and the demo.
    float age = max(uniforms.animation.x - arc.from.w, 0.0);
    bool animated = arc.to.w > 0.0;
    float progress = animated ? clamp(age / (arc.to.w * 0.55), 0.0, 1.0) : 1.0;
    float opacity = animated
        ? smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(arc.to.w * 0.78, arc.to.w, age))
        : 1.0;
    float t = float(segmentIndex) / 32.0 * progress;
    float side = (vertexID % 2 == 0) ? -1.0 : 1.0;
    float3 arcPoint = cobeBezierPoint(from, midpoint, to, t);
    float3 rotatedPoint = cobeRotate(
        arcPoint,
        uniforms.rotation.x,
        uniforms.rotation.y
    );

    float3 tangent = cobeBezierTangent(from, midpoint, to, t);
    float3 rotatedTangent = cobeRotate(
        tangent,
        uniforms.rotation.x,
        uniforms.rotation.y
    );
    float2 screenTangent = rotatedTangent.xy;
    float tangentLength = length(screenTangent);
    float2 screenPerpendicular = tangentLength > 0.001
        ? float2(-screenTangent.y, screenTangent.x) / tangentLength
        : float2(1.0, 0.0);

    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 baseScreenPosition = rotatedPoint.xy
        * float2(1.0 / aspect, 1.0)
        * uniforms.scale
        + uniforms.offset * float2(1.0, -1.0)
        * uniforms.scale
        / uniforms.resolution;
    float2 screenPosition = baseScreenPosition
        + screenPerpendicular * arc.heightAndWidth.y * side * uniforms.scale;

    CobeArcVertexOut output;
    output.position = float4(screenPosition, 0.0, 1.0);
    output.color = arc.colorAndHasColor.xyz;
    output.hasColor = arc.colorAndHasColor.w;
    output.depth = rotatedPoint.z;
    output.radialDistance = length(rotatedPoint.xy);
    output.opacity = opacity;
    return output;
}

fragment float4 cobeArcFragment(
    CobeArcVertexOut input [[stage_in]],
    constant CobeArcUniforms& uniforms [[buffer(0)]]
) {
    if (input.depth < 0.0 && input.radialDistance < cobeGlobeRadius) {
        discard_fragment();
    }
    float3 color = input.hasColor > 0.5
        ? input.color
        : uniforms.arcColor.xyz;
    return float4(color, input.opacity);
}
