<?xml version="1.0" encoding="UTF-8"?>
<shader language="GLSL">
  <vertex><![CDATA[
    uniform vec2 rubyTextureSize;

    void main() {
      float x = 0.5 * (1.0 / rubyTextureSize.x);
      float y = 0.5 * (1.0 / rubyTextureSize.y);
      vec2 dg1 = vec2( x, y);
      vec2 dg2 = vec2(-x, y);
      vec2 dx = vec2(x, 0.0);
      vec2 dy = vec2(0.0, y);

      gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
      gl_TexCoord[0] = gl_MultiTexCoord0;
      gl_TexCoord[1].xy = gl_TexCoord[0].xy - dg1;
      gl_TexCoord[1].zw = gl_TexCoord[0].xy - dy;
      gl_TexCoord[2].xy = gl_TexCoord[0].xy - dg2;
      gl_TexCoord[2].zw = gl_TexCoord[0].xy + dx;
      gl_TexCoord[3].xy = gl_TexCoord[0].xy + dg1;
      gl_TexCoord[3].zw = gl_TexCoord[0].xy + dy;
      gl_TexCoord[4].xy = gl_TexCoord[0].xy + dg2;
      gl_TexCoord[4].zw = gl_TexCoord[0].xy - dx;
    }
  ]]></vertex>

  <fragment filter="nearest"><![CDATA[
    uniform sampler2D rubyTexture;

    const float mx = 0.325;
    const float k = -0.250;
    const float max_w = 0.25;
    const float min_w = -0.05;
    const float lum_add = 0.25;

    void main() {
      vec3 c00 = texture2D(rubyTexture, gl_TexCoord[1].xy).xyz;
      vec3 c10 = texture2D(rubyTexture, gl_TexCoord[1].zw).xyz;
      vec3 c20 = texture2D(rubyTexture, gl_TexCoord[2].xy).xyz;
      vec3 c01 = texture2D(rubyTexture, gl_TexCoord[4].zw).xyz;
      vec3 c11 = texture2D(rubyTexture, gl_TexCoord[0].xy).xyz;
      vec3 c21 = texture2D(rubyTexture, gl_TexCoord[2].zw).xyz;
      vec3 c02 = texture2D(rubyTexture, gl_TexCoord[4].xy).xyz;
      vec3 c12 = texture2D(rubyTexture, gl_TexCoord[3].zw).xyz;
      vec3 c22 = texture2D(rubyTexture, gl_TexCoord[3].xy).xyz;
      vec3 dt = vec3(1.0, 1.0, 1.0);

      float md1 = dot(abs(c00 - c22), dt);
      float md2 = dot(abs(c02 - c20), dt);

      float w1 = dot(abs(c22 - c11), dt) * md2;
      float w2 = dot(abs(c02 - c11), dt) * md1;
      float w3 = dot(abs(c00 - c11), dt) * md2;
      float w4 = dot(abs(c20 - c11), dt) * md1;

      float t1 = w1 + w3;
      float t2 = w2 + w4;
      float ww = max(t1, t2) + 0.0001;

      c11 = (w1 * c00 + w2 * c20 + w3 * c22 + w4 * c02 + ww * c11) / (t1 + t2 + ww);

      float lc1 = k / (0.12 * dot(c10 + c12 + c11, dt) + lum_add);
      float lc2 = k / (0.12 * dot(c01 + c21 + c11, dt) + lum_add);

      w1 = clamp(lc1 * dot(abs(c11 - c10), dt) + mx, min_w, max_w);
      w2 = clamp(lc2 * dot(abs(c11 - c21), dt) + mx, min_w, max_w);
      w3 = clamp(lc1 * dot(abs(c11 - c12), dt) + mx, min_w, max_w);
      w4 = clamp(lc2 * dot(abs(c11 - c01), dt) + mx, min_w, max_w);

      gl_FragColor.rgb = w1 * c10 + w2 * c21 + w3 * c12 + w4 * c01 + (1.0 - w1 - w2 - w3 - w4) * c11;
      gl_FragColor.a = 1.0;
    }
  ]]></fragment>

  <fragment scale="1.0" filter="nearest"><![CDATA[
    uniform sampler2D texture;
    uniform vec2 rubyTextureSize;

    #define glarebasesize 0.896
    const float BLOOM_POWER = 0.40;

    void main() {
      vec4 sum = vec4(0.0);
      vec4 bum = vec4(0.0);
      vec2 texcoord = vec2(gl_TexCoord[0]);
      vec2 glaresize = vec2(glarebasesize) / rubyTextureSize;

      for (int i = -2; i < 2; i++) {
        for (int j = -1; j < 1; j++) {
          sum += texture2D(texture, texcoord + vec2(-i, j) * glaresize) * BLOOM_POWER;
          bum += texture2D(texture, texcoord + vec2(j, i) * glaresize) * BLOOM_POWER;
        }
      }

      gl_FragColor = sum * sum * sum * 0.001 + bum * bum * bum * 0.0080 + texture2D(texture, texcoord);
    }
  ]]></fragment>

  <fragment scale="1.0" filter="nearest"><![CDATA[
    uniform sampler2D rubyTexture;
    uniform vec2 rubyTextureSize;

    const float MIX_ALPHA = 0.4;

    void main(void) {
      vec4 rgb = texture2D(rubyTexture, gl_TexCoord[0].xy);
      vec4 rgb2;
      if (int(gl_FragCoord.x) == 0) {
        rgb2 = rgb;
      }
      else {
        rgb2 = texture2D(rubyTexture, gl_TexCoord[0].xy + vec2(-1.0 / rubyTextureSize.x, 0));
      }

      gl_FragColor = mix(rgb, rgb2, MIX_ALPHA);
    }
  ]]></fragment>

  <fragment outscale="1.0"><![CDATA[
    uniform sampler2D rubyTexture;

    const float LIGHTNESS_GAMMA = 1.1;
    const float STRENGTH = 140.0;
    const float STRENGTH2 = 240.0;

    float Hue_2_RGB(float v1, float v2, float vH) {
      float ret;
      if (vH < 0.0) vH += 1.0;
      if (vH > 1.0) vH -= 1.0;
      if ((6.0 * vH) < 1.0)
        ret = v1 + (v2 - v1) * 6.0 * vH;
      else if ((2.0 * vH) < 1.0)
        ret = v2;
      else if ((3.0 * vH) < 2.0)
        ret = v1 + (v2 - v1) * ((2.0 / 3.0) - vH) * 6.0;
      else
        ret = v1;
      return ret;
    }

    void main(void) {
      const float istrength = 255.0 - STRENGTH;
      const float istrength2 = 255.0 - STRENGTH2;
      const float max_brightness = 245.0;

      vec4 rgb = texture2D(rubyTexture, gl_TexCoord[0].xy);
      float R = rgb.r;
      float G = rgb.g;
      float B = rgb.b;

      float Cmax = max(R, max(G, B));
      float Cmin = min(R, min(G, B));
      float H = 0.0;
      float S = 0.0;
      float L = (Cmax + Cmin) / 2.0;

      if (Cmax != Cmin) {
        float D = Cmax - Cmin;
        if (L < 0.5)
          S = D / (Cmax + Cmin);
        else
          S = D / (2.0 - (Cmax + Cmin));

        if (R == Cmax)
          H = (G - B) / D;
        else if (G == Cmax)
          H = 2.0 + (B - R) / D;
        else
          H = 4.0 + (R - G) / D;

        H = H / 6.0;
      }

      float line = float(int(gl_FragCoord.y));
      if (int(mod(line, 3.0)) < 1) {
        float ia = (istrength - (255.0 - max_brightness)) / 255.0 + L / (255.0 / STRENGTH);
        L = L * ia;
      }
      else if (int(mod(line, 3.0)) < 2) {
        float ia = (istrength - (255.0 - max_brightness)) / 255.0 + L / (255.0 / STRENGTH2);
        L = L * ia;
      }
      else {
        L = L * 0.95 + 0.05;
      }

      L = pow(L, 1.0 / LIGHTNESS_GAMMA);

      if (H < 0.0) H = H + 1.0;
      H = clamp(H, 0.0, 1.0);
      S = clamp(S, 0.0, 1.0);
      L = clamp(L, 0.0, 1.0);

      float var_1;
      float var_2;
      if (S == 0.0) {
        R = L;
        G = L;
        B = L;
      }
      else {
        if (L < 0.5)
          var_2 = L * (1.0 + S);
        else
          var_2 = L + S - S * L;

        var_1 = 2.0 * L - var_2;
        R = Hue_2_RGB(var_1, var_2, H + (1.0 / 3.0));
        G = Hue_2_RGB(var_1, var_2, H);
        B = Hue_2_RGB(var_1, var_2, H - (1.0 / 3.0));
      }

      gl_FragColor = vec4(R, G, B, rgb.a);
    }
  ]]></fragment>
</shader>
