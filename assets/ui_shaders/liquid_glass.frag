#version 320 es

#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

// u_size and u_texture are populated by ImageFilter.shader.
uniform vec2 u_size;
uniform float u_lensing;
uniform float u_chromaticAberration;
uniform vec2 u_touch;
uniform float u_press;
uniform float u_thickness;
uniform float u_radius;
uniform float u_darkMode;
uniform float u_highContrast;
uniform vec4 u_tint;
uniform sampler2D u_texture;

float luminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float roundedBoxDistance(vec2 point, vec2 halfSize, float radius) {
  vec2 q = abs(point) - halfSize + radius;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

float shapeDistance(vec2 uv) {
  vec2 point = (uv - 0.5) * u_size;
  vec2 halfSize = max(u_size * 0.5 - vec2(1.0), vec2(1.0));
  return roundedBoxDistance(point, halfSize, min(u_radius, min(halfSize.x, halfSize.y)));
}

vec2 shapeNormal(vec2 uv) {
  vec2 pixel = 1.0 / max(u_size, vec2(1.0));
  float dx = shapeDistance(uv + vec2(pixel.x, 0.0)) -
      shapeDistance(uv - vec2(pixel.x, 0.0));
  float dy = shapeDistance(uv + vec2(0.0, pixel.y)) -
      shapeDistance(uv - vec2(0.0, pixel.y));
  return normalize(vec2(dx, dy) + vec2(0.00001));
}

vec3 scatteredSample(vec2 uv, vec2 pixel, float radius) {
  vec3 color = texture(u_texture, uv).rgb * 0.28;
  color += texture(u_texture, clamp(uv + vec2(radius, 0.0) * pixel, 0.001, 0.999)).rgb * 0.12;
  color += texture(u_texture, clamp(uv - vec2(radius, 0.0) * pixel, 0.001, 0.999)).rgb * 0.12;
  color += texture(u_texture, clamp(uv + vec2(0.0, radius) * pixel, 0.001, 0.999)).rgb * 0.12;
  color += texture(u_texture, clamp(uv - vec2(0.0, radius) * pixel, 0.001, 0.999)).rgb * 0.12;
  color += texture(u_texture, clamp(uv + vec2(radius, radius) * pixel, 0.001, 0.999)).rgb * 0.06;
  color += texture(u_texture, clamp(uv + vec2(-radius, radius) * pixel, 0.001, 0.999)).rgb * 0.06;
  color += texture(u_texture, clamp(uv + vec2(radius, -radius) * pixel, 0.001, 0.999)).rgb * 0.06;
  color += texture(u_texture, clamp(uv - vec2(radius, radius) * pixel, 0.001, 0.999)).rgb * 0.06;
  return color;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  vec2 pixel = 1.0 / max(u_size, vec2(1.0));
  float distanceToEdge = shapeDistance(uv);
  vec2 normal = shapeNormal(uv);

  // A broad optical band bends the scene near the material boundary while the
  // center remains readable. Larger surfaces behave like thicker glass.
  float opticalDepth = mix(20.0, 44.0, clamp(u_thickness - 0.5, 0.0, 1.0));
  float edge = smoothstep(-opticalDepth, -2.0, distanceToEdge);
  edge = edge * edge * (3.0 - 2.0 * edge);

  vec2 touchDelta = (uv - u_touch) * u_size;
  float touchGlow = exp(-dot(touchDelta, touchDelta) /
      max(1800.0, 4800.0 * u_thickness)) * u_press;
  vec2 touchNormal = normalize(touchDelta + vec2(0.00001));

  vec2 lensOffset = normal * edge * u_lensing * pixel;
  lensOffset += touchNormal * touchGlow * 5.0 * pixel;
  vec2 sampleUv = clamp(uv + lensOffset, vec2(0.001), vec2(0.999));

  float scatterRadius = mix(0.8, 2.8, clamp(u_thickness - 0.5, 0.0, 1.0));
  vec3 color = scatteredSample(sampleUv, pixel, scatterRadius);

  // Spectral separation is limited to the refractive boundary.
  vec2 dispersion = normal * edge * u_chromaticAberration * pixel;
  color.r = texture(u_texture, clamp(sampleUv + dispersion, 0.001, 0.999)).r;
  color.b = texture(u_texture, clamp(sampleUv - dispersion, 0.001, 0.999)).b;

  // Sample the local environment. Contrast and tint adapt continuously to the
  // scene behind the glass instead of switching between fixed light/dark fills.
  vec3 environment = scatteredSample(sampleUv, pixel, 8.0 + 4.0 * u_thickness);
  float environmentLuma = luminance(environment);
  float localLuma = luminance(color);
  float localContrast = abs(localLuma - environmentLuma);

  float tintStrength = u_tint.a * mix(0.72, 1.18, 1.0 - environmentLuma);
  tintStrength += localContrast * 0.10 + u_highContrast * 0.12;
  color = mix(color, u_tint.rgb, clamp(tintStrength, 0.0, 0.82));

  // Adapt dynamic range so fixed foreground controls remain legible over both
  // bright and dark media while preserving ambient color spill.
  float separation = mix(0.12, -0.10, environmentLuma);
  separation += mix(-0.02, 0.04, u_darkMode);
  color += vec3(separation * (0.55 + 0.25 * u_highContrast));
  color = mix(vec3(luminance(color)), color, 0.88 + localContrast * 0.12);

  // Geometry-aware Fresnel highlight and opposing contact shadow create the
  // visible thickness of the material without a static horizontal gradient.
  vec2 lightDirection = normalize(vec2(-0.65, -0.76));
  float facingLight = max(dot(normal, lightDirection), 0.0);
  float facingShadow = max(dot(normal, -lightDirection), 0.0);
  float fresnel = pow(edge, 1.7);
  float highlight = fresnel * facingLight *
      (0.14 + 0.10 * u_thickness) * (1.10 - environmentLuma * 0.45);
  float contactShadow = fresnel * facingShadow *
      (0.08 + 0.07 * u_thickness) * (0.55 + environmentLuma * 0.45);
  color += vec3(highlight + touchGlow * 0.10);
  color -= vec3(contactShadow);

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
