shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D native_lightmap : filter_linear, repeat_disable;
uniform bool has_base = true;
uniform bool has_lightmap = false;
uniform float alpha_clip = 0.0;
uniform float source_gain = 2.0;
void fragment() {
 vec4 base = has_base ? texture(base_texture, UV) : vec4(1.0, 0.15, 0.4, 1.0);
 if (base.a < alpha_clip) { discard; }
 vec3 light_value = has_lightmap ? texture(native_lightmap, UV2).rgb : COLOR.rgb;
 ALBEDO = base.rgb * clamp(light_value * source_gain, vec3(0.0), vec3(1.0));
}
