#!/usr/bin/env python3
"""P26: extend the softpipe half lowering from txf to the sampling tex ops.

Why: WindowServer's compositing pipeline (spec PBGRABsovXm_TimgA2Xhf_Isrc)
samples its input with a float16 sampler.  air_metal_lowering.inc only ever
converted nir_texop_txf (integer coords + explicit lod), so a nir_texop_tex
with a float16 dest fell through to check_half_instructions()'s default branch
and the whole pipeline was refused ("does not support instruction type 3").

The conversion is the same one txf already does: fetch as float32, then an
explicit f2f16 keeps the declared half rounding.
"""
import re
import shutil
import sys

SRC = "/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/compiler/air/air_metal_lowering.inc"

NEW_TEX = r'''/* TGSI has no 16-bit registers, so every texture fetch that declares a half
 * result is widened to float32 and rounded back with f2f16. The integer-coordinate
 * fetch came first; the sampling ops need the same treatment because the window
 * server's compositing pipeline samples with a half sampler (the `hf` in
 * PBGRABsovXm_TimgA2Xhf_Isrc). Only the coordinate carries two components; every
 * other source (sampler handle, lod, bias, offset) is a scalar in 32 bits. */
static bool
lower_half_tex(nir_builder *b, nir_instr *instr, void *data)
{
   (void)data;
   if (instr->type != nir_instr_type_tex)
      return false;
   nir_tex_instr *tex = nir_instr_as_tex(instr);
   if (tex->dest_type != nir_type_float16 ||
       tex->def.bit_size != 16 || tex->sampler_dim != GLSL_SAMPLER_DIM_2D ||
       tex->is_array || tex->is_shadow || tex->is_sparse ||
       tex->coord_components != 2 || tex->num_srcs < 2)
      return false;
   switch (tex->op) {
   case nir_texop_tex:
   case nir_texop_txb:
   case nir_texop_txl:
   case nir_texop_txf:
   case nir_texop_txf_ms:
      break;
   default:
      return false;
   }
   bool have_coord = false;
   for (unsigned i = 0; i < tex->num_srcs; i++) {
      nir_tex_src *src = &tex->src[i];
      if (!src->src.ssa || src->src.ssa->bit_size != 32)
         return false;
      if (src->src_type == nir_tex_src_coord) {
         if (src->src.ssa->num_components != 2)
            return false;
         have_coord = true;
      } else if (src->src.ssa->num_components != 1) {
         return false;
      }
   }
   if (!have_coord)
      return false;

   /* TGSI fetches float32. An explicit conversion preserves the declared half
    * result, including rounding for source formats with more than 16 bits. */
   tex->def.bit_size = 32;
   tex->dest_type = nir_type_float32;
   b->cursor = nir_after_instr(instr);
   nir_def *half = nir_f2f16(b, &tex->def);
   nir_def_rewrite_uses_after(&tex->def, half);
   return true;
}
'''

OLD_FN_START = "static bool\nlower_half_txf(nir_builder *b, nir_instr *instr, void *data)\n{"
OLD_FN_END = "   nir_def_rewrite_uses_after(&tex->def, half);\n   return true;\n}\n"

TEX_CASE = '''            case nir_instr_type_tex: {
               /* lower_half_tex() rewrites these before this check runs; one
                * that is still half samples with a half coordinate or an op it
                * does not cover, and naming it here saves a boot. */
               nir_tex_instr *tex = nir_instr_as_tex(instr);
               say(why, why_size,
                   "softpipe half lowering does not support tex op %u (%s, %u srcs)",
                   tex->op, tex->def.bit_size == 16 ? "half dest" : "half source",
                   tex->num_srcs);
               return false;
            }
'''


def main():
    body = open(SRC, encoding="utf-8").read()

    if "lower_half_tex(" in body:
        print("already patched")
        return 0

    start = body.find(OLD_FN_START)
    if start < 0:
        print("FAIL: lower_half_txf start anchor not found")
        return 1
    end = body.find(OLD_FN_END, start)
    if end < 0:
        print("FAIL: lower_half_txf end anchor not found")
        return 1
    end += len(OLD_FN_END)

    old_fn = body[start:end]
    print("replacing %d bytes of lower_half_txf" % len(old_fn))
    body = body[:start] + NEW_TEX + body[end:]

    n = body.count("nir_shader_instructions_pass, lower_half_txf")
    if n != 1:
        print("FAIL: expected 1 call site of lower_half_txf, found %d" % n)
        return 1
    body = body.replace("nir_shader_instructions_pass, lower_half_txf",
                        "nir_shader_instructions_pass, lower_half_tex")

    anchor = "            default:\n               say(why, why_size, \"softpipe half lowering does not support instruction type %u\", instr->type);"
    if body.count(anchor) != 1:
        print("FAIL: check_half_instructions default anchor not unique (%d)"
              % body.count(anchor))
        return 1
    body = body.replace(anchor, TEX_CASE + anchor)

    open(SRC, "w", encoding="utf-8").write(body)
    print("patched %s" % SRC)
    print("lower_half_tex defined:", body.count("lower_half_tex(nir_builder"))
    print("call site:", body.count("lower_half_tex,\n"))
    print("tex case:", body.count("does not support tex op"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
