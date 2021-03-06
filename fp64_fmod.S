/* Copyright (c) 2018  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2006  Dmitry Xmelkov
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
   * Neither the name of the copyright holders nor the names of
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE. */

/* $Id$ */

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_fmod (float64_t x, float64_t y);
     The fp64_fmod() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
 */

FUNCTION fp64_fmod
	; do special case handling
	; A or B is NaN and/or Inf or A is 0
	; case|	A	  |	B	 |	fmod(A,B)
	;-----+-------+------+------
	; 1	  |	NaN	  |	any	 |	NaN
	; 2	  |	any	  |	NaN	 |	NaN
	; 3	  |	Inf	  |	0	 |	NaN
	; 4   | Inf   | Inf  |  NaN
	; 5	  |	Inf	  |	!= 0 |	NaN
	; 6	  |	0	  |	Inf	 |	 0
	; 7	  |	!= 0  |	Inf	 |	 A
	; 8   | 0     | 0    |  NaN
	; 9   | 0     | != 0 |   0

0:	brne	.L_nan		; as NaN has priority, result will be NaN, cases 1&2
	; from  now on, neither A nor B are NaN
	; so one or both are +Inf/-Inf
	; check if A is Inf
	XCALL	_U(__fp64_pscA)
	breq	.L_nan		; A is +/-Inf, cases 3,4,5
	; A is not Inf, so B must be Inf, cases 6,7 --> return A
	XJMP _U(__fp64_pretA)

	; cases 1-5: result is NaN 
.L_nan:
	XJMP	_U(__fp64_nan)

/* float64_t fp64_fmod (float64_t x, float64_t y);
     The fp64_fmod() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
 */
ENTRY fp64_fmod
  ; split and check exceptions
    cbr rB7, 0x80		; sign of B does not matter
 	XCALL	_U(__fp64_split3)
	brcs	0b			; handle special cases NaN / Inf
	breq	1f			; handle fmod( 0, B ) --> 0
	XCALL	_U(__fp64_pscB)
	breq	.L_nan		; finite (!=0) / 0.0 --> NaN
	
	push rC4			; save working registers
	push rC5
	push rC6
	push rC7
	rcall __fp64_fmod_pse
	; movw rB4, rC4		; return n
	; movw rB6, rC6
	pop rC7				; restore used registers, n is not needed
	pop rC6
	pop rC5
	pop rC4
	;call __fp64_saveAB
	brcs 11f			; result is already packed ?
	XJMP _U(__fp64_rpretA); no, pack it
11: ret					; yet, return with packed result

20:	clc
	ret

1: ; A is 0, B is not Inf or NaN, cases 8, 9	
	XCALL	_U(__fp64_pscB)
	breq	.L_nan		; fmod(0,0), case 8 -->  NaN
	; clr r0			; init division result
	clr rC4		; init division result
	clr rC5
	movw rC6, rC4

.L_sz1:
	; inc r0			; fabs(A) = fabs(1) --> n = 1, fmod = 0
	add rC4, r0	; fabs(A) = fabs(1) --> n = 1, fmod = 0
	adc rC5, r1
	adc rC6, r1
	adc rC7, r1

	; A is 0, B is not 0, case 9 --> 0
.L_sz:
	clr rAE0
	clr rAE1
	XCALL	_U(__fp64_szero)
	sec
	ret
	
/* float64_t_intern fp64_fmod_pse (float64_t_intern x, float64_t_intern y);
     The fp64_fmod_pse() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
	 It does not handle any special cases, the caller has to assure that both
	 x and y are finite and != 0
	 rC7.rC6.rC5.rC4 are modified and contain the lower 4 bytes of n
 */
ENTRY	__fp64_fmod_pse	; post split entry

	clr r0
	inc r0		; r0 will contain 1 to aid +1 / -1 operations
	clr rC4		; init division result
	clr rC5
	movw rC6, rC4
	
	cp	rA0, rB0	; check whether A < B
	cpc	rA1, rB1
	cpc	rA2, rB2
	cpc	rA3, rB3
	cpc	rA4, rB4
	cpc	rA5, rB5
	cpc	rA6, rB6
	cpc rAE0, rBE0
	cpc rAE1, rBE1
	;call __fp64_saveAB
	brlo 20b		; if fabs(A) < fabs(B), A is already the result 
	breq .L_sz1		; if fabs(A) = fabs(B) --> return sign(A^B)*0
  
	; from now on fabs(A) > fabs(B)
	; as we do allow subnormal numbers, mantissa of A might not start with 
	; a leading 1 bit, so normalize A
	tst rA6
	brmi 3f
	
2:	sbiw rAE0,1		; decrease exponent
	lsl	rA0			; A <<= 1
	rol	rA1
	rol	rA2
	rol	rA3
	rol	rA4
	rol	rA5
	rol	rA6
	brpl 2b		; repeat until we have a leading 1 bit

3:	; as we do allow subnormal numbers, mantissa of B might not start with 
	; a leading 1 bit, so normalize B
	tst rB6
	brmi 5f
	
4:	sbiw rBE0,1		; decrease exponent
	lsl	rB0			; B <<= 1
	rol	rB1
	rol	rB2
	rol	rB3
	rol	rB4
	rol	rB5
	rol	rB6
	brpl 4b		; repeat until we have a leading 1 bit

5:	;call __fp64_saveAB
	sub rAE0, rBE0	; exponent(A) - exponent(B)
	sbc rAE1, rBE1
	tst rAE1
	brne .L_sz		; A > 2^256*B --> fmod(A,B) can not exactly be determined , return 0
	cpi rAE0, 54
	brsh .L_sz		; A > 2^54*B --> fmod(A,B)  can not exactly be determined , return 0
	clr rA7			; highest A byte
	clr rB7			; and B byte
	
.Loop:
	; inc r0
	add rC4, r0		; counter++
	adc rC5, r1
	adc rC6, r1
	adc rC7, r1
	sub	rA0, rB0	; try to subtract B, A -= B
	sbc	rA1, rB1
	sbc	rA2, rB2
	sbc	rA3, rB3
	sbc	rA4, rB4
	sbc	rA5, rB5
	sbc	rA6, rB6
	sbc	rA7, rB7
	; breq .L_sz		; result is 0
	breq 66f		; result is 0
	brpl 6f			; if A > B, success
	; dec r0
	sub rC4, r0	; counter--
	sbc rC5, r1
	sbc rC6, r1
	sbc rC7, r1
	add	rA0, rB0	; else undo the sub, A += B
	adc	rA1, rB1
	adc	rA2, rB2
	adc	rA3, rB3
	adc	rA4, rB4
	adc	rA5, rB5
	adc	rA6, rB6
	adc	rA7, rB7
6:	sbiw rAE0,1		; exponent(A)--
	brmi 7f			; if exponent < 0, everything is calculated
	; lsl r0
	lsl rC4		; shift counter
	rol rC5
	rol rC6
	rol rC7
	lsl	rA0			; A <<= 1
	rol	rA1
	rol	rA2
	rol	rA3
	rol rA4
	rol rA5
	rol rA6
	rol rA7
	rjmp .Loop
66:	sbiw rAE0, 1
	brmi 67f
	; lsl r0
	lsl rC4		; shift counter
	rol rC5
	rol rC6
	rol rC7
	rjmp 66b
67: rjmp .L_sz

7:	sbiw rBE0,1		; exponent B--
	brmi 10f
	breq 9f
8:	tst rA6			; is topmost bit of result set?
	brmi 9f			; yes, we can return
	lsl	rA0			; A <<= 1
	rol	rA1
	rol	rA2
	rol	rA3
	rol rA4
	rol rA5
	rol rA6
	rol rA7
	sbiw rBE0, 1
	brne 8b			; repeat until topmost bit or exponent = 0, i.e. subnormal number
9:	adiw rBE0, 1	; adjust exponent
.L_pk:
	movw rAE0, rBE0
	clc
	ret
	
10: 
	lsr	rA6			; A >>= 1
	ror	rA5
	ror	rA4
	ror	rA3
	ror	rA2
	ror	rA1
	ror	rA0
	adiw rBE0, 1	; exponent++
	brne 10b		; repeat until exponent = 0
	rjmp 9b
	
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
