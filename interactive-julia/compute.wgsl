// forked from https://compute.toys/view/213

fn hue2rgb(f1: f32, f2: f32, hue0: f32) -> f32 {
  var hue = hue0;
  if hue < 0.0 {
    hue += 1.0;
  } else if hue > 1.0 {
    hue -= 1.0;
  }
  var res: f32;
  if (6.0 * hue) < 1.0 {
    res = f1 + (f2 - f1) * 6.0 * hue;
  } else if (2.0 * hue) < 1.0 {
    res = f2;
  } else if (3.0 * hue) < 2.0 {
    res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
  } else {
    res = f1;
  }
  return res;
}

fn hsl2rgb(hsl: vec3f) -> vec3f {
  var rgb = vec3f(0.0, 0.0, 0.0);
  if hsl.y == 0.0 {
    rgb = vec3f(hsl.z); // Luminance
  } else {
    var f2: f32;
    if hsl.z < 0.5 {
      f2 = hsl.z * (1.0 + hsl.y);
    } else {
      f2 = hsl.z + hsl.y - hsl.y * hsl.z;
    }
    let f1 = 2.0 * hsl.z - f2;
    rgb.r = hue2rgb(f1, f2, hsl.x + (1.0 / 3.0));
    rgb.g = hue2rgb(f1, f2, hsl.x);
    rgb.b = hue2rgb(f1, f2, hsl.x - (1.0 / 3.0));
  }
  return rgb;
}

// h from 0 to 1
fn hsl(h: f32, s: f32, l: f32) -> vec3f {
  return hsl2rgb(vec3f(h, s, l));
}

// complex product
fn product(a: vec2<f32>, b: vec2<f32>) -> vec2<f32> {
  return vec2<f32>(
    a.x * b.x - a.y * b.y,
    a.x * b.y + a.y * b.x,
  );
}

// return the number of iterations before the point escapes
fn julia_escape(p: vec2<f32>, c: float2, max_iter: u32) -> u32 {
  var z = p;
  for (var i = 0u; i < max_iter; i = i + 1u) {
    z = product(z, z) + c;
    if length(z) > 2.0 {
      return i;
    }
  }

  return max_iter;
}


@compute @workgroup_size(16, 16)
fn main_image(@builtin(global_invocation_id) id: uint3) {
    // Viewport resolution (in pixels)
  let screen_size = textureDimensions(screen);
  let ratio = f32(screen_size.y) / f32(screen_size.x);

    // Prevent overdraw for workgroups on the edge of the viewport
  if id.x >= screen_size.x || id.y >= screen_size.y { return; }

    // Mandelbrot region
  let p0 = float2(-3, -3 * ratio);
  let p1 = float2(3, 3 * ratio);
  let d = (p1 - p0) / float2(screen_size.xy);

  let x = f32(mouse.pos.x) + 96.;
  let y = f32(mouse.pos.y) + 36.;

  let control = vec2(
    x - 0.5 * f32(screen_size.x),
    y - 0.5 * f32(screen_size.y)
  ) * 0.004;

  let uv = p0 + float2(id.xy) * d;

  let escape_steps = julia_escape(uv, control, 1000);
  let v = f32(escape_steps) * 0.001;
  let col = hsl(
    fract(0.6 + v * 70.), 0.5 + v * 0.5, fract(0.5 + v * 4.0)
  );
    // var col = float3(v, v, v);

    // Output to screen (linear colour space)
  textureStore(screen, id.xy, float4(col, 1.));
}