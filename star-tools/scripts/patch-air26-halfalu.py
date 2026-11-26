#!/usr/bin/env python3
"""P27: let the softpipe half lowering run float arithmetic, not only casts.

P26 removed the texture refusal and the same pipeline moved one step on:
"softpipe half lowering does not support ALU fmax".  The whitelist in
check_half_instructions() only allows the ops whose half bit pattern survives a
32-bit register untouched (mov/vec/bcsel) and the casts.  Arithmetic on half
values is refused because carrying the raw bits through an fp32 op computes
garbage.

The fix is the obvious one: run those ops in fp32 and round the result back to
half with an explicit f2f16 -- the same move lower_half_tex() makes for a
texture result, and numerically what a half ALU does anyway (every operand is a
half, so the rounding error the shader would have had is preserved to within one
ulp of the fp32 result).
"""
import sys

SRC = "/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/compiler/air/air_metal_lowering.inc"

PASS = r'''
/* The half ALU ops the softpipe path cannot carry as raw bits: every float op
 * that is not a cast. A cast keeps its own meaning (the widening loop below
 * turns f2f16 into the raw bits and f2f32 into an unpack), but arithmetic has
 * to be done on real numbers, so the operands are widened, the op runs in fp32
 * and the half result is restored with f2f16. Comparisons are here too: their
 * result is a boolean, and only their sources are half. */
static bool
half_alu_demotable(nir_op op)
{
   if (half_copy_op(op) || half_cast_op(op))
      return false;
   if (op == nir_op_f2f32)
      return false;
   return nir_op_infos[op].output_type == nir_type_float ||
          nir_op_infos[op].output_type == nir_type_bool;
}

static bool
demote_half_alu(nir_builder *b, nir_instr *instr, void *data)
{
   (void)data;
   if (instr->type != nir_instr_type_alu)
      return false;
   nir_alu_instr *alu = nir_instr_as_alu(instr);
   if (!half_alu_demotable(alu->op))
      return false;

   b->cursor = nir_before_instr(instr);
   b->fp_math_ctrl = alu->fp_math_ctrl;

   bool widened_source = false;
   unsigned inputs = nir_op_infos[alu->op].num_inputs;
   for (unsigned i = 0; i < inputs; i++) {
      nir_def *src = alu->src[i].src.ssa;
      if (!src || src->bit_size != 16)
         continue;
      /* the swizzled view, so a .yxwz source keeps its order */
      nir_def *swizzled = nir_ssa_for_alu_src(b, alu, i);
      nir_def *wide = nir_f2f32(b, swizzled);
      alu->src[i].src = nir_src_for_ssa(wide);
      for (unsigned c = 0; c < NIR_MAX_VEC_COMPONENTS; c++)
         alu->src[i].swizzle[c] = c;
      widened_source = true;
   }
   if (!widened_source)
      return false;

   if (alu->def.bit_size == 16) {
      alu->def.bit_size = 32;
      b->cursor = nir_after_instr(instr);
      nir_def *half = nir_f2f16(b, &alu->def);
      nir_def_rewrite_uses_after(&alu->def, half);
   }
   return true;
}
'''

ANCHOR_CALL = """   NIR_PASS(_, nir, nir_shader_instructions_pass, lower_half_tex,
            nir_metadata_control_flow, NULL);
"""

NEW_CALL = ANCHOR_CALL + """   /* Arithmetic comes after the texture result is already a half cast: the f2f16
    * this pass inserts is a cast the next pass accepts. */
   NIR_PASS(_, nir, nir_shader_instructions_pass, demote_half_alu,
            nir_metadata_control_flow, NULL);
"""

ANCHOR_FN = """static bool
check_half_instructions(nir_shader *nir, const struct air_shader_info *info,"""

body = open(SRC, encoding="utf-8").read()

if "demote_half_alu" in body:
    print("already patched")
    sys.exit(0)

if body.count(ANCHOR_CALL) != 1:
    print("FAIL: call anchor count %d" % body.count(ANCHOR_CALL))
    sys.exit(1)
body = body.replace(ANCHOR_CALL, NEW_CALL)

if body.count(ANCHOR_FN) != 1:
    print("FAIL: function anchor count %d" % body.count(ANCHOR_FN))
    sys.exit(1)
body = body.replace(ANCHOR_FN, PASS.strip("\n") + "\n\n" + ANCHOR_FN)

open(SRC, "w", encoding="utf-8").write(body)
print("patched", SRC)
print("demote_half_alu x", body.count("demote_half_alu"))
