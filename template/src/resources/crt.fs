#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

uniform float renderWidth = 800;
uniform float renderHeight = 450;

float radius = 250.0;
float angle = 0.8;

uniform float scanlineThick = 3.0;
uniform float scanlineIntensity = 0.5;
uniform float distortX = 0.05;   // Curvature intensity on the X axis
uniform float distortY = 0.10;  // Curvature intensity on the Y axis

void main()
{
    vec2 uv = fragTexCoord * 2.0 - 1.0;
    uv.x = uv.x + (uv.x * uv.y * uv.y) * distortX;
    uv.y = uv.y + (uv.y * uv.x * uv.x) * distortY;
    vec2 distortedTexCoord = (uv + 1.0) / 2.0;

    if (distortedTexCoord.x < 0.0 || distortedTexCoord.x > 1.0 || 
        distortedTexCoord.y < 0.0 || distortedTexCoord.y > 1.0) {
        finalColor = vec4(0.0, 0.0, 0.0, 1.0); // Black border
    } else {
        vec4 crtColor = texture(texture0, distortedTexCoord);

        float vignette = distortedTexCoord.x * distortedTexCoord.y * (1.0 - distortedTexCoord.x) * (1.0 - distortedTexCoord.y);
        vignette = clamp(pow(16.0 * vignette, 0.25), 0.0, 1.0);

        crtColor.rgb *= vignette;

        vec2 texSize = vec2(renderWidth, renderHeight);
        float scanlineY = (distortedTexCoord*texSize).y / scanlineThick;
        float scanlineWave = sin(scanlineY * 3.14 * 2.0);
        float scanlineFactor = (scanlineWave + 1.0) * 0.5;
        scanlineFactor *= scanlineFactor;
        float finalScanlineDarkness = mix(1.0 - scanlineIntensity, 1.0, scanlineFactor);

        vec4 color = crtColor*colDiffuse*fragColor*finalScanlineDarkness;

        finalColor = vec4(color.rgb, 1.0);
    }
}
