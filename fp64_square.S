/* Copyright (c) 2018  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2005  Anatoly Sokolov  <aesok@post.ru>
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

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_square (float64_t A);
     The fp64_square() function returns square of A.
 */

ENTRY fp64_square
	push rB0			; save temporarely used registers
	push rB1
	push rB2
	push rB3
	push rB4
	push rB5
	push rB6
	push rB7
	push rBE1
	push rBE0

	X_movw	rB0, rA0	; B = A
	X_movw	rB2, rA2
	X_movw	rB4, rA4
	X_movw	rB6, rA6

	XCALL	_U(__fp64_mulsd3x)	; A * B

	pop rBE0
	pop rBE1
	pop rB7			; restore temporarely used registers
	pop rB6
	pop rB5
	pop rB4
	pop rB3
	pop rB2
	pop rB1
	pop rB0
	
	ret
ENDFUNC
