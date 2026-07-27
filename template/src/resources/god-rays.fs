// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

uniform float time = 0;

uniform float renderWidth = 800;
uniform float renderHeight = 450;

uniform vec4 ray_color = vec4(1.0, 1.0, 1.0, 0.8); // source_color 
uniform float angle = 0.3; // hint_range(-1.57, 1.57) 
uniform float position = 0.0; // hint_range(-1.0, 1.0) 
uniform float spread = 2.0; // hint_range(0.0, 2.0) 
uniform float cutoff = 0.4; // hint_range(0.0, 1.0) 
uniform float falloff = 0.9; // hint_range(0.0, 1.0) 
uniform float edge_fade = 0.1; // hint_range(0.0, 1.0) 
uniform float speed = 2.0; // hint_range(0.0, 10.0) 
uniform float ray1_density = 8.0; // hint_range(0.1, 20.0) 
uniform float ray2_density = 30.0; // hint_range(0.1, 20.0) 
uniform float ray2_intensity = 0.3; // hint_range(0.0, 1.0) 

float noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hybrid_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(noise(i + vec2(0.0, 0.0)), noise(i + vec2(1.0, 0.0)), u.x),
			   mix(noise(i + vec2(0.0, 1.0)), noise(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
    vec4 texColor = texture(texture0, fragTexCoord);
    vec4 color = texColor*fragColor*colDiffuse;
	vec2 uv = fragTexCoord;
	uv.x += (uv.y - 0.5) * angle + position;

	float beam_mask = clamp((1.0 - abs(uv.x - 0.5) / (spread * (1.0 - uv.y))), 0.0, 1.0);

	vec2 p1 = vec2(uv.x * ray1_density, time * speed);
	vec2 p2 = vec2(uv.x * ray2_density, time * speed * 0.5);

	float noise1 = hybrid_noise(p1);
	float noise2 = hybrid_noise(p2);

	float combined_noise = (noise1 + noise2 * ray2_intensity) / (1.0 + ray2_intensity);

	// Cutoff and falloff calculations
	float ray_intensity = combined_noise;
	ray_intensity = smoothstep(cutoff, cutoff + falloff, ray_intensity);

	// Edge fade
	// ray_intensity *= smoothstep(0.0, edge_fade, uv.y);
	// ray_intensity *= smoothstep(1.0, 1.0 - edge_fade, uv.y);

    vec4 ray_final = ray_color * ray_intensity;

    // OPTION A: Additive Blending (Brighter, intense, can blow out to pure white)
    // vec3 blended_color = color.rgb + ray_final.rgb;

    // OPTION B: Screen Blending (Softer, cinematic, never blows out past pure white)
    // Formula: 1 - (1 - Target) * (1 - Source)
    vec3 blended_color = 1.0 - (1.0 - color.rgb) * (1.0 - ray_final.rgb);

    // 3. Output the result (preserving the original game's alpha channel)
    finalColor = vec4(blended_color, color.a);
}
