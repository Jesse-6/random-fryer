format ELF64 executable 3 at 4 shl 36

include 'fastcall_v1.inc'
include 'stdmacros.inc'
include 'stdio.inc'

struct  TERMIOS
        .iflag              rd 1    ; input mode flags
        .oflag              rd 1    ; output mode flags
        .cflag              rd 1    ; control mode flags
        .lflag              rd 1    ; local mode flags
        .line               rd 1    ; line discipline
        .cc                 rb 32   ; control characters
        .ispeed             rd 1    ; input speed
        .ospeed             rd 1    ; output speed
end struct



FLAG_MUST_EXIT = 0000_0001b
FLAG_UPDATED   = 0000_0010b
FLAG_UNLOCKED  = 0000_0100b
FLAG_HAS_ZERO  = 0000_1000b
FLAG_RSV_THRD1 = 0001_0000b
FLAG_RSV_THRD2 = 0010_0000b
FLAG_ZERO_ACK  = 1 shl 15
FLAG_FAIL_ACK  = 1 shl 14
FLAG_STRAIGHT  = 1 shl 13



_bss    align 16
        proc_brand:         xo ?
        proc_full:          xb *48

_rdata  align 1
        proc_AMD            xo 'AuthenticAMD'
        proc_Intel          xo 'GenuineIntel'

        header              xb '┌───────────────────────────────────────────────────────────────┐',10
                            xb '│ ',27,'[44m'
                            xb ' CPU Hardware Random Generator Fryer Application             '
                            xb 27,'[0m',' │',10
                            xb '╞════╤══════════════════════════════════════════════════════════╡',10
                            xb '│CPU:│                                                          │',10
                            xb '├────┴───┬─────┬───────┬────────────────────────────────────────┤',10
                            xb '│Threads:│     │Status:│                                        │',10
                            xb '╞════════╧═════╧═══════╧════════════════════════════════════════╡',10
            .blank          xb '│                                                               │',10
                            xb '└───────────────────────────────────────────────────────────────┘',10
                            xb 0

        run_table           xb '╞═══╤════╧════╤╧═══════╧╤═════════╤═════════╤═════════╤═════════╡',10
                            xb '│ # │ Rand 16 │ Rand 32 │ Rand 64 │ Seed 16 │ Seed 32 │ Seed 64 │',10
                            xb '├───┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤',10
                            xb '│+1:│         │         │         │         │         │         │',10
                            xb '├───┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤',10
                            xb '│ 0:│         │         │         │         │         │         │',10
                            xb '├───┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤',10
                            xb '│-1:│         │         │         │         │         │         │',10
                            xb '╞═══╧═════════╧═════════╧═════════╧═════════╧═════════╧═════════╡',10
                            xb '│                                                               │',10
                            xb '└───────────────────────────────────────────────────────────────┘',10
                            xb 0

        help_msg            xb 'Use this application to check if your processor can generate',10
                            xb 'the number 0 as a result from its random number generator,',10
                            xb 'accessible via ''rdrand'' and ''rdseed'' instructions. I,',10
                            xb 'Jesse 6, have figured out that my Zen2 AMD Ryzen 7 processor',10
                            xb 'cannot, so, I ended up developing this application so that I',10
                            xb 'and others could quickly verify this.',10
                            xb 'Intel processors, so far, have not exhibited this problem.',10
                            xb 'This program also counts 1 and -1 occurences as well.',10,10
                            xb 'Usage:',10,10
                            xb 9,27,'[1m','%s',27,'[0m',10
                            xb 9,27,'[1m','%s -quick',27,'[0m',10,10
                            xb 'By using ''-quick'' option, it skips the start messages and',10
                            xb 'goes straight to test mode.',10,10
                            xb 'Result are as follows:',10,10
                            xb '  - 16, 32, and 64 are the requested number size in bits;',10
                            xb '  - ''rand'' stands for rdrand generated;',10
                            xb '  - ''seed'' stands for rdseed generated.',10,10
                            xb 'Probabilities for any number are as follows:',10,10
                            xb '  - 16-bit number: 1 in %lu;',10
                            xb '  - 32-bit number: 1 in %lu;',10
                            xb '  - 64-bit number: 1 in %lu%09lu.',10,10
                            xb 'So, don''t expect to see 32-bit number counters count often,',10
                            xb 'and even less to see any counting on 64-bit number counters!',10
                            xb 0

_data   align 4
        Count:
            .p1.rand.16     xd 0    ; +1 counters
            .p1.rand.32     xd 0
            .p1.rand.64     xd 0
            .p1.seed.16     xd 0
            .p1.seed.32     xd 0
            .p1.seed.64     xd 0
            ._0.rand.16     xd 0    ; 0 counters
            ._0.rand.32     xd 0
            ._0.rand.64     xd 0
            ._0.seed.16     xd 0
            ._0.seed.32     xd 0
            ._0.seed.64     xd 0
            .m1.rand.16     xd 0    ; -1 counters
            .m1.rand.32     xd 0
            .m1.rand.64     xd 0
            .m1.seed.16     xd 0
            .m1.seed.32     xd 0
            .m1.seed.64     xd 0
            .tries          xq 0    ; Number of random number requests

        flags               xw 0 or FLAG_UPDATED



_code   Start entry:        mov         r10, [stdout]
                            mov         r11, [stderr]
                            push        [r10]
                            push        [r11]
                            pop         [stdout]
                            pop         [stderr]

                            cmp         [rsp], dword 2
                            jb          @f
                            ja          Help
                            mov         rdi, [rsp+16]
                            mov         rax, "-quick"
                            mov         rsi, 0_00FF_FFFF_FFFF_FFFFh
                            mov         rcx, [rdi]
                            and         rcx, rsi
                            cmp         rcx, rax
                            jne         Help
                            or          [flags], FLAG_STRAIGHT

                    @@      mov         r9, rdx

                    @rdata  ierr_fmt    xb "Your processor does not support %s instruction",10,0
                            mov         eax, 1
                            cpuid
                            bt          ecx, 30
                            jc          @f
                            fprintf(*stderr, &ierr_fmt, "'RDRAND'");
                            exit(1);

                    @@      mov         eax, 7
                            xor         ecx, ecx
                            cpuid
                            bt          ebx, 18
                            jc          @f
                            fprintf(*stderr, &ierr_fmt, "'RDSEED'");
                            exit(2);

                    @@      xor         eax, eax
                            cpuid
                            mov         [proc_brand], ebx
                            mov         [proc_brand+4], edx
                            mov         [proc_brand+8], ecx
                            mov         [proc_brand+12], dword 0

                            mov         eax, 8000_0002h
                            cpuid
                            mov         [proc_full], eax
                            mov         [proc_full+4], ebx
                            mov         [proc_full+8], ecx
                            mov         [proc_full+12], edx
                            mov         eax, 8000_0003h
                            cpuid
                            mov         [proc_full+16], eax
                            mov         [proc_full+20], ebx
                            mov         [proc_full+24], ecx
                            mov         [proc_full+28], edx
                            mov         eax, 8000_0004h
                            cpuid
                            mov         [proc_full+32], eax
                            mov         [proc_full+36], ebx
                            mov         [proc_full+40], ecx
                            mov         [proc_full+44], edx

                            __libc_start_main(&Main, [rsp+8], &rsp+16, NULL, NULL, r9, rsp);



        Help:               mov         rdi, [rsp+8]
                            mov         rsi, [rsp+8]
                            xor         al, al
                            mov         ecx, 4095
                            repne       scasb
                            not         ecx
                            sub         rdi, 2
                            mov         al, '/'
                            std
                            repne       scasb
                            jne         @f
                            add         rdi, 2
                            jmp         @f2
                    @@      mov         rdi, rsi
                    @@      cld

                            mov         ax, -1
                            mov         r10d, -1
                            mov         r11d, 1'000'000'000
                            mov         edx, 1
                            movzx       rsi, ax
                            inc         r10
                            inc         rsi
                            xor         eax, eax
                            div         r11

                            fprintf(*stderr, &help_msg, rdi, rdi, rsi, r10, rax, rdx);
                            exit(3);



        Main:               push        rbx

                    @bss    term        TERMIOS
                            tcdrain(STDOUT_FILENO);
                            tcgetattr(STDIN_FILENO, &term);
                            xor         [term.lflag], ECHO
                            tcsetattr(STDIN_FILENO, TCSADRAIN, &term);

                            fprintf(*stdout, &header);

                    @rdata  AMD_warn    db 27,"[33mmight have 'zero generate' problem",0
                    @rdata  Intel_msg   db 27,"[36mshould not have problem",0
                            get_nprocs();
                            lea         r10, [AMD_warn]
                            lea         r8, [Intel_msg]
                            movdqa      xmm6, [proc_AMD]
                            movdqa      xmm1, [proc_brand]
                            pcmpeqb     xmm6, xmm1
                            pmovmskb    r9d, xmm6
                            cmp         r9w, -1
                            cmove       r8, r10
                            lea         rdi, [proc_full]
                            mov         r9b, ' '
                            xchg        eax, r9d
                            mov         ecx, 47
                            repe        scasb
                            fprintf(*stdout, \
                                <27,"[6A",27,"[7C",27,"[37m","%s", \
                                27,"[2E",27,"[11C","%u", \
                                27,"[26G","%s", \
                                27,"[3E",27,"[0m",10,0>, \
                                &rdi-1, r9d, r8);

                            signal(SIGINT, &FlagBreak);

                            test        [flags], FLAG_STRAIGHT
                            jnz         @f2

                            fprintf(*stdout, <27,"[2A",27,"[2C",27,"[1;36m", \
                                "Check if this processor can generate 0 as a random number!", \
                                27,"[0m",27,"[2E",0>);
                            usleep(10'000'000);
                            test        [flags], FLAG_MUST_EXIT
                            jnz         Main.abort

                            mov         ebx, 100

                    @@      mov         edx, 10
                            cvtsi2sd    xmm0, ebx
                            cvtsi2sd    xmm5, edx
                            divsd       xmm0, xmm5
                            fprintf(*stdout, <27,"[2A",27,"[2C", \
                                27,"[1;33m","Starting in %.01lf seconds, press ",27,"[32mCTRL-C", \
                                27,"[33m to quit at anytime...  ",27,"[0m", \
                                27,"[2E",0>, xmm0);
                            fflush(*stdout);
                            usleep(100'000);
                            test        [flags], FLAG_MUST_EXIT
                            jnz         Main.abort
                            dec         ebx
                            jns         @b

                    @@      fprintf(*stdout, <27,"[3A%s",0>,&run_table);
                            fprintf(*stdout, <27,"[10F",27,"[2C",27,"[1;38;5;134m#",27,"[3C", \
                                27,"[38;5;190mRand 16",27,"[3CRand 32",27,"[3CRand 64",27,"[3C", \
                                27,"[38;5;51mSeed 16",27,"[3CSeed 32",27,"[3CSeed 64",27,"[2E",27,"[C", \
                                27,"[38;5;39m+1:",27,"[2E",27,"[C",27,"[38;5;182m 0:",27,"[2E",27,"[C", \
                                27,"[38;5;202m-1:",27,"[0m",27,"[4E",0>);

                            prefetcht2  [Count]
                            prefetcht2  [Count+32]
                            prefetcht2  [Count+64]

                            sub         rsp, 16
                            pthread_create(rsp, NULL, &RS_thread, 1);
                            pthread_create(&rsp+8, NULL, &RS_thread, 2);

                            lock or     [flags], FLAG_UNLOCKED

                    @@      pause
                            mfence
                            mov         ax, [flags]
                            and         ax, 0_00FFh
                            shr         ax, 4
                            cmp         ax, 3
                            jne         @b

                            fprintf(*stdout, <27,"[2F",27,"[2C",27,"[32mRunning...   ",27,"[2E",0>);
                            fflush(*stdout);

                    @1      usleep(50'000);
                            test        [flags], FLAG_UPDATED
                            jz          @3f
                            mov         eax, 7
                            mov         edx, 174
                            mov         ecx, 114
                            test        [flags], FLAG_FAIL_ACK
                            cmovnz      eax, edx
                            test        [flags], FLAG_ZERO_ACK
                            cmovnz      eax, ecx
                            fprintf(*stdout, <27,"[8F",27,"[6C",27,"[37m% 8u", \
                                27,"[2C% 8u",27,"[2C% 8u",27,"[2C% 8u",27,"[2C% 8u",27,"[2C% 8u", \
                                27,"[2E",27,"[38;5;%um",27,"[6C% 8u",27,"[2C% 8u",27,"[2C% 8u",27,"[2C% 8u", \
                                27,"[2C% 8u",27,"[2C% 8u",27,"[2E",27,"[37m",27,"[6C% 8u",27,"[2C% 8u", \
                                27,"[2C% 8u",27,"[2C% 8u",27,"[2C% 8u",27,"[2C% 8u",27,"[2E", \
                                27,"[44G% 20lu",27,"[2E",0>, \
                                *Count.p1.rand.16, *Count.p1.rand.32, *Count.p1.rand.64, *Count.p1.seed.16, \
                                *Count.p1.seed.32, *Count.p1.seed.64, eax, *Count._0.rand.16, \
                                *Count._0.rand.32, *Count._0.rand.64, *Count._0.seed.16, *Count._0.seed.32, \
                                *Count._0.seed.64, *Count.m1.rand.16, *Count.m1.rand.32, *Count.m1.rand.64, \
                                *Count.m1.seed.16, *Count.m1.seed.32, *Count.m1.seed.64, *Count.tries);

                    @rdata  status_fmt  xb 27,"[12F",27,"[25C",27,"[%umCPU has %s",27,"[0m",27,"[12E",0
                            test        [flags], FLAG_HAS_ZERO
                            jz          @f
                            test        [flags], FLAG_ZERO_ACK
                            jnz         @2f
                            fprintf(*stdout, &status_fmt, 32, "passed 'zero generate' test   ");
                            lock or     [flags], FLAG_ZERO_ACK
                            jmp         @2f

                    @@      cmp         [Count.tries], 60'000'000
                            jbe         @2f
                            test        [flags], FLAG_FAIL_ACK
                            jnz         @2f
                            fprintf(*stdout, &status_fmt, 31, "failed to generate zero number");
                            lock or     [flags], FLAG_FAIL_ACK

                    @2      lock and    [flags], not FLAG_UPDATED

                    @3      test        [flags], FLAG_MUST_EXIT
                            jz          @1b

                            pthread_join([rsp], NULL);
                            pthread_join([rsp+8], NULL);


                            add         rsp, 16

                            fprintf(*stdout, <27,"[2F",27,"[2C",27,"[37mFinished.   ",27,"[0m",27,"[2E",0>);
                            fflush(*stdout);

                            jmp         Main.end

        Main.abort:         fprintf(*stdout, <27,"[2F%s",27,"[2F", \
                                27,"[3G",27,"[1;33mAborted.",27,"[0m",27,"[2E",0>, \
                                &header.blank);

        Main.end:           xor         [term.lflag], ECHO
                            tcsetattr(STDIN_FILENO, TCSAFLUSH, &term);

                            pop         rbx
                            xor         eax, eax
                            ret



        FlagBreak:          lock or     [flags], FLAG_MUST_EXIT
                            ret



        RS_thread:          push        rbp
                            mov         ebp, edi

                    @@      pause
                            test        [flags], FLAG_UNLOCKED
                            jz          @b

                            add         di, 3
                            lock bts   [flags], di

                    @1      pause
                            rdrand      dx
                            jnc         @1b
                            test        dx, dx
                            jnz         @f
                            lock inc    [Count._0.rand.16]
                            lock or     [flags], FLAG_UPDATED or FLAG_HAS_ZERO
                            jmp         @f3
                    @@      cmp         dx, -1
                            jne         @f
                            lock inc    [Count.m1.rand.16]
                            lock or     [flags], FLAG_UPDATED
                            jmp         @f2
                    @@      cmp         dx, 1
                            jne         @f
                            lock inc    [Count.p1.rand.16]
                            lock or     [flags], FLAG_UPDATED

                    @@      lock inc    [Count.tries]
                    @@      pause
                            rdseed      cx
                            jnc         @b
                            test        cx, cx
                            jnz         @f
                            lock inc    [Count._0.seed.16]
                            lock or     [flags], FLAG_UPDATED or FLAG_HAS_ZERO
                            jmp         @f3
                    @@      cmp         cx, -1
                            jne         @f
                            lock inc    [Count.m1.seed.16]
                            lock or     [flags], FLAG_UPDATED
                            jmp         @f2
                    @@      cmp         cx, 1
                            jne         @f
                            lock inc    [Count.p1.seed.16]
                            lock or     [flags], FLAG_UPDATED

                    @@      lock inc    [Count.tries]
                    @@      pause
                            rdrand      eax
                            jnc         @b
                            test        eax, eax
                            jnz         @f
                            lock inc    [Count._0.rand.32]
                            lock or     [flags], FLAG_UPDATED or FLAG_HAS_ZERO
                            jmp         @f3
                    @@      cmp         eax, -1
                            jne         @f
                            lock inc    [Count.m1.rand.32]
                            lock or     [flags], FLAG_UPDATED
                            jmp         @f2
                    @@      cmp         eax, 1
                            jne         @f
                            lock inc    [Count.p1.rand.32]
                            lock or     [flags], FLAG_UPDATED

                    @@      lock inc    [Count.tries]
                    @@      pause
                            rdseed      r9d
                            jnc         @b
                            test        r9d, r9d
                            jnz         @f
                            lock inc    [Count._0.seed.32]
                            lock or     [flags], FLAG_UPDATED or FLAG_HAS_ZERO
                            jmp         @f3
                    @@      cmp         r9d, -1
                            jne         @f
                            lock inc    [Count.m1.seed.32]
                            lock or     [flags], FLAG_UPDATED
                            jmp         @f2
                    @@      cmp         r9d, 1
                            jne         @f
                            lock inc    [Count.p1.seed.32]
                            lock or     [flags], FLAG_UPDATED

                    @@      lock inc    [Count.tries]
                    @@      pause
                            rdrand      rdi
                            jnc         @b
                            test        rdi, rdi
                            jnz         @f
                            lock inc    [Count._0.rand.64]
                            lock or     [flags], FLAG_UPDATED or FLAG_HAS_ZERO
                            jmp         @f3
                    @@      cmp         rdi, -1
                            jne         @f
                            lock inc    [Count.m1.rand.64]
                            lock or     [flags], FLAG_UPDATED
                            jmp         @f2
                    @@      cmp         rdi, 1
                            jne         @f
                            lock inc    [Count.p1.rand.64]
                            lock or     [flags], FLAG_UPDATED

                    @@      lock inc    [Count.tries]
                    @@      pause
                            rdseed      rsi
                            jnc         @b
                            test        rsi, rsi
                            jnz         @f
                            lock inc    [Count._0.seed.64]
                            lock or     [flags], FLAG_UPDATED or FLAG_HAS_ZERO
                            jmp         @f3
                    @@      cmp         rsi, -1
                            jne         @f
                            lock inc    [Count.m1.seed.64]
                            lock or     [flags], FLAG_UPDATED
                            jmp         @f2
                    @@      cmp         rsi, 1
                            jne         @f
                            lock inc    [Count.p1.seed.64]
                            lock or     [flags], FLAG_UPDATED

                    @@      lock inc    [Count.tries]
                            mfence

                            mov         esi, 300'000
                            mov         rax, [Count.tries]
                            cqo
                            div         rsi
                            test        rdx, rdx
                            jnz         @f
                            lock or     [flags], FLAG_UPDATED

                    @@      test        [flags], FLAG_MUST_EXIT
                            jz          @1b

                            pop         rbp
                            xor         rax, rax
                            ret
