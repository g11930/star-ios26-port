#!/usr/bin/env python3
"""P29: demote_half_alu without touching another instruction's sources by hand.

P27 widened half ALU sources by assigning alu->src[i].src = nir_src_for_ssa(wide).  That
only writes the pointer: nir_src_for_ssa() links nothing into the new def's use list, while
the old def keeps the entry that points at this instruction's source slot.  nir_opt_copy_prop
walks those lists, found a use whose owner disagreed with the list it was in, and died on a
null def -- libannibaleair.dylib+0x1A94CC, ldrb w9,[x22,#0x18], ESR 0x92000005, addr 0x18,
in every backboardd of the P27/P28 runs.

The fix builds a fresh 32-bit instruction at the cursor and removes the old one, so every
use link is made and broken by nir_build_alu_src_arr()/nir_instr_remove() themselves.
"""
import re
import sys

SRC = ("/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/"
       "src/compiler/air/air_metal_lowering.inc")

NEW = r'''static bool
demote_half_alu(nir_builder *b, nir_instr *instr, void *data)
{
   (void)data;
   if (instr->type != nir_instr_type_alu)
      return false;
   nir_alu_instr *alu = nir_instr_as_alu(instr);
   if (!half_alu_demotable(alu->op))
      return false;

   unsigned inputs = nir_op_infos[alu->op].num_inputs;
   nir_def *srcs[8] = { NULL };
   bool widened_source = false;

   b->cursor = nir_before_instr(instr);
   b->fp_math_ctrl = alu->fp_math_ctrl;

   for (unsigned i = 0; i < inputs; i++) {
      nir_def *src = alu->src[i].src.ssa;
      if (!src) {
         srcs[i] = NULL;
         continue;
      }
      if (src->bit_size != 16) {
         srcs[i] = src;
         continue;
      }
      /* the swizzled view, so a .yxwz source keeps its order */
      nir_def *swizzled = nir_ssa_for_alu_src(b, alu, i);
      srcs[i] = nir_f2f32(b, swizzled);
      widened_source = true;
   }
   if (!widened_source)
      return false;

   /* Build the 32-bit instruction and take the old one out.  Assigning
    * alu->src[i].src by hand would leave the def's use list linking an
    * instruction that no longer points back at it, which is what
    * nir_opt_copy_prop() follows to a null def. */
   nir_def *wide = nir_build_alu_src_arr(b, alu->op, srcs);
   nir_alu_instr *walu = nir_instr_as_alu(nir_def_instr(wide));
   walu->no_signed_wrap = alu->no_signed_wrap;
   walu->no_unsigned_wrap = alu->no_unsigned_wrap;
   walu->fp_math_ctrl = alu->fp_math_ctrl;

   if (alu->def.bit_size == 16) {
      b->cursor = nir_after_instr(nir_def_instr(wide));
      nir_def *half = nir_f2f16(b, wide);
      nir_def_rewrite_uses(&alu->def, half);
   } else {
      nir_def_rewrite_uses(&alu->def, wide);
   }
   nir_instr_remove(instr);
   return true;
}
'''

with open(SRC, "r", encoding="utf-8") as f:
    text = f.read()

if "nir_build_alu_src_arr(b, alu->op, srcs)" in text:
    print("already patched")
    sys.exit(0)

m = re.search(r"static bool\ndemote_half_alu\(nir_builder \*b, nir_instr \*instr, void \*data\)\n\{.*?\n\}\n",
              text, re.S)
if not m:
    sys.exit("demote_half_alu not found")

text = text[:m.start()] + NEW + text[m.end():]
with open(SRC, "w", encoding="utf-8") as f:
    f.write(text)
print("patched demote_half_alu: rebuild instruction instead of swapping sources")
