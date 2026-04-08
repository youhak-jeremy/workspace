text
    .globl add
    .type add, @function

add:
  addi    x2,x2,-32     // 현재 함수의 stack frame 32바이트 할당
  sw      x1,28(x2)     // caller의 return address(ra) 저장
  sw      x8,24(x2)     // caller의 frame pointer(fp=s0) 저장
  addi    x8,x2,32      // 현재 함수의 fp 설정 (fp = old sp)

  sw      x10,-20(x8)   // 첫 번째 인자 x를 stack frame에 저장
  sw      x11,-24(x8)   // 두 번째 인자 y를 stack frame에 저장

  lw      x14,-20(x8)   // x를 불러옴
  lw      x15,-24(x8)   // y를 불러옴
  add     x15,x14,x15   // x + y 계산
  addi    x10,x15,0     // 반환값을 x10(a0)에 저장

  lw      x1,28(x2)     // 저장해 두었던 ra 복원
  lw      x8,24(x2)     // 저장해 두었던 fp 복원
  addi    x2,x2,32      // stack frame 해제
  jalr    x0,0(x1)      // caller로 복귀
