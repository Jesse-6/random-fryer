format ELF64 executable 3 at 4 shl 36

include 'fastcall_v1.inc'
include 'stdmacros.inc'
include 'stdio.inc'

struct  CC_CHAR
        .intr               db ?
        .quit               db ?
        .erase              db ?
        .kill               db ?
        .eof                db ?
        .time               db ?
        .min                db ?
        .swtc               db ?
        .start              db ?
        .stop               db ?
        .susp               db ?
        .eol                db ?
        .reprint            db ?
        .discard            db ?
        .w.erase            db ?
        .l.next             db ?
        .eol.2              db ?
                            rb 16   ; should be 32 bytes size
end struct

struct  TERMIOS
        .iflag              rd 1    ; input mode flags
        .oflag              rd 1    ; output mode flags
        .cflag              rd 1    ; control mode flags
        .lflag              rd 1    ; local mode flags
        .line               rd 1    ; line discipline
        .cc                 CC_CHAR ; control characters
        .ispeed             rd 1    ; input speed
        .ospeed             rd 1    ; output speed
end struct

struct TIMESPEC
        .sec                rq 1
        .nsec               rq 1
end struct

FLAG_MUST_EXIT      = 0000_0001b
FLAG_UPDATED        = 0000_0010b
FLAG_UNLOCKED       = 0000_0100b
FLAG_HAS_ZERO       = 0000_1000b
FLAG_RSV_THRD1      = 0001_0000b
FLAG_RSV_THRD2      = 0010_0000b
FLAG_RSV_THRD3      = 0100_0000b
FLAG_RSV_THRD4      = 1000_0000b

FLAG_BIT_BM_TOGGLE  = 8
FLAG_BIT_BM_UNLOCK  = 9

FLAG_UNUSED         = 1 shl 10      ; free bit (so far)
FLAG_NO_SEED        = 1 shl 11
FLAG_LIGHTWEIGHT    = 1 shl 12
FLAG_STRAIGHT       = 1 shl 13
FLAG_FAIL_ACK       = 1 shl 14
FLAG_ZERO_ACK       = 1 shl 15



_bss    align 16
        proc_brand:         xo ?
        proc_full:          xb *48
        proc_count          xd ?

_rdata  align 1
        proc_AMD            xo 'AuthenticAMD'
        proc_Intel          xo 'GenuineIntel'

        header              xb '┌─────────────────────────────────────────────────────────────────────────────┐',10
                            xb '│ ',27,'[48;5;%u;38;5;%um'
                            xb ' CPU Hardware Random Generator Fryer Application                           '
                            xb 27,'[0m',' │',10
                            xb '╞══════╤══════════════════════════════════════════════════════╤═══════════════╡',10
                            xb '│ CPU: │                                                      │ '
                            xb '%sRDRAND %sRDSEED ',27,'[0m│',10
                            xb '├──────┴───┬─────┬─────────┬──────────────────────────────────┴───────────────┤',10
                            xb '│ Threads: │     │ Status: │                                                  │',10
                            xb '╞══════════╧═════╧═════════╧══════════════════════════════════════════════════╡',10
                            xb '│                                                                             │',10
                            xb '└─────────────────────────────────────────────────────────────────────────────┘',10
                            xb 27,'[?25l',27,'7'
                            xb 0

        run_table           xb '╞═════╤════╧═════╧╤════════╧══╤═══════════╤═══════════╤═══════════╤═══════════╡',10
                            xb '│  #  │  Rand 16  │  Rand 32  │  Rand 64  │  Seed 16  │  Seed 32  │  Seed 64  │',10
                            xb '├─────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤',10
                            xb '│ +1: │           │           │           │           │           │           │',10
                            xb '├─────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤',10
                            xb '│  0: │           │           │           │           │           │           │',10
                            xb '├─────┼───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤',10
                            xb '│ -1: │           │           │           │           │           │           │',10
                            xb '╞═════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╧═══════════╡',10
                            xb '│                                                                             │',10
                            xb '└─────────────────────────────────────────────────────────────────────────────┘',10
                            xb 0

        blank_row           xb '│                                                                             │',0

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
                            xb 9,27,'[1m','%s [ -quick | -light | -q | -l ]',27,'[0m',10,10
                            xb 'By using ''-quick'' or ''-q'' option, it skips the start messages',10
                            xb 'and goes straight to test mode.',10,10
                            xb 'By using ''-light'' or ''-l'' option, threads run with less',10
                            xb 'CPU usage.',10,10
                            xb 'Results are as follows:',10,10
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
            .benchmark      xd 0    ; RNG performance counter
            .tries          xq 0    ; Number of random number requests

        Run:
            .seconds        xd 0
            .minutes        xd 0
            .hours          xd 0
            .days           xd 0

        flags               xw 0 or FLAG_UPDATED



_code   Start entry:        mov         r10, [stdout]
                            mov         r11, [stderr]
                            push        [r10]
                            push        [r11]
                            pop         [stdout]
                            pop         [stderr]

                            cmp         [rsp], dword 2
                            jb          @f2
                            ja          @f
                            mov         rdi, [rsp+16]
                            call        ParseArg
                            jc          Help
                            jmp         @f2

                    @@      cmp         [rsp], dword 3
                            ja          Help
                            mov         rdi, [rsp+24]
                            call        ParseArg
                            jc          Help
                            mov         rdi, [rsp+16]
                            call        ParseArg
                            jc          Help

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
                            xor         esi, esi
                            cpuid
                            bt          ebx, 18
                            setnc       sil
                            rol         esi, bsf FLAG_NO_SEED
                            or          [flags], si

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

        ParseArg:           cmp         [rdi], byte '-'
                            jne         @1f

                            mov         rax, '-quick'
                            mov         r11, '-light'
                            mov         rsi, 0_00FF_FFFF_FFFF_FFFFh
                            mov         rcx, [rdi]
                            and         rcx, rsi

                            cmp         rcx, rax
                            jne         @f
                            test        [flags], FLAG_STRAIGHT
                            jnz         @1f
                            or          [flags], FLAG_STRAIGHT
                            jmp         @2f

                    @@      cmp         rcx, r11
                            jne         @f
                            test        [flags], FLAG_LIGHTWEIGHT
                            jnz         @1f
                            or          [flags], FLAG_LIGHTWEIGHT
                            jmp         @2f

                    @@      cmp         ecx, '-ql'
                            jne         @f
                            test        [flags], FLAG_STRAIGHT or FLAG_LIGHTWEIGHT
                            jnz         @1f
                            or          [flags], FLAG_STRAIGHT or FLAG_LIGHTWEIGHT
                            jmp         @2f

                    @@      cmp         ecx, '-lq'
                            jne         @f
                            test        [flags], FLAG_STRAIGHT or FLAG_LIGHTWEIGHT
                            jnz         @1f
                            or          [flags], FLAG_STRAIGHT or FLAG_LIGHTWEIGHT
                            jmp         @2f

                    @@      cmp         [rdi+1], word 'q'
                            jne         @f
                            test        [flags], FLAG_STRAIGHT
                            jnz         @1f
                            or          [flags], FLAG_STRAIGHT
                            jmp         @2f

                    @@      cmp         [rdi+1], word 'l'
                            jne         @1f
                            test        [flags], FLAG_LIGHTWEIGHT
                            jnz         @1f
                            or          [flags], FLAG_LIGHTWEIGHT

                    @2      clc
                            ret

                    @1      stc
                            ret



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
                            and         [term.lflag], not (ECHO or ICANON)
                            tcsetattr(STDIN_FILENO, TCSADRAIN, &term);

                            fcntl(STDIN_FILENO, F_GETFL, 0);
                            or          eax, O_NONBLOCK
                            fcntl(STDIN_FILENO, F_SETFL, eax);

                    @rdata  rand.on     xb 27,"[1;38;5;190m",0
                    @rdata  seed.on     xb 27,"[1;38;5;51m",0
                    @rdata  seed.off    xb 27,"[0;38;5;8m",0
                            mov         edx, 21
                            mov         ecx, 15
                            mov         r10d, 2
                            mov         r11d, 16
                            test        [flags], FLAG_LIGHTWEIGHT
                            cmovnz      edx, r10d
                            cmovnz      ecx, r11d
                            lea         r9, [seed.on]
                            lea         rax, [seed.off]
                            test        [flags], FLAG_NO_SEED
                            cmovnz      r9, rax
                            fprintf(*stdout, &header, edx, ecx, &rand.on, r9);

                    @rdata  AMD_warn    db 27,"[33mmight have 'zero generate' problem",0
                    @rdata  Intel_msg   db 27,"[36mshould not have problem",0
                            get_nprocs();
                            mov         [proc_count], eax
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
                                <27,"8",27,"[6A",27,"[9C",27,"[37m","%s", \
                                27,"[2E",27,"[12C","% 4u", \
                                27,"[30G","%s", \
                                27,"[3E",27,"[0m",10,0>, \
                                &rdi-1, r9d, r8);

                            signal(SIGINT, &FlagBreak);

                            test        [flags], FLAG_STRAIGHT
                            jnz         @2f

                            fprintf(*stdout, <27,"8",27,"[2A",27,"[2C",27,"[1;36m", \
                                "Check if this processor can generate 0 as a random number!", \
                                27,"[0m",27,"[2E",27,"[0J",0>);

                            mov         ebx, 100
                    @1      usleep(100'000);
                            test        [flags], FLAG_MUST_EXIT
                            jnz         Main.abort

                    @bss    typebuff    xb *8
                            read(STDIN_FILENO, &typebuff, 8);
                            test        eax, eax
                            jle         @f
                            cmp         [typebuff], 'q'
                            je          Main.abort
                            cmp         [typebuff], 'Q'
                            je          Main.abort

                    @@      dec         ebx
                            jns         @1b

                            mov         ebx, 100
                    @1      mov         edx, 10
                            cvtsi2sd    xmm0, ebx
                            cvtsi2sd    xmm5, edx
                            divsd       xmm0, xmm5
                            fprintf(*stdout, <27,"8",27,"[2A",27,"[2C", \
                                27,"[1;33m","Starting in %.01lf seconds, press ",27,"[32mCTRL-C", \
                                27,"[33m or ",27,"[32m'Q'",27,"[33m to quit at anytime...  ",27,"[0m", \
                                27,"[2E",27,"[0J",0>, xmm0);
                            fflush(*stdout);
                            usleep(100'000);
                            test        [flags], FLAG_MUST_EXIT
                            jnz         Main.abort

                            read(STDIN_FILENO, &typebuff, 8);
                            test        eax, eax
                            jle         @f
                            cmp         [typebuff], 'q'
                            je          Main.abort
                            cmp         [typebuff], 'Q'
                            je          Main.abort

                    @@      dec         ebx
                            jns         @1b

                    @2      fprintf(*stdout, <27,"8",27,"[3A%s",27,"7",0>,&run_table);

                            mov         edx, 51
                            mov         ecx, 8
                            test        [flags], FLAG_NO_SEED
                            cmovnz      edx, ecx
                            fprintf(*stdout, <27,"8",27,"[10F",27,"[3C",27,"[1;38;5;134m#",27,"[5C", \
                                27,"[38;5;190mRand 16",27,"[5CRand 32",27,"[5CRand 64",27,"[5C", \
                                27,"[38;5;%umSeed 16",27,"[5CSeed 32",27,"[5CSeed 64",27,"[2E",27,"[2C", \
                                27,"[38;5;39m+1:",27,"[2E",27,"[2C",27,"[38;5;182m 0:",27,"[2E",27,"[2C", \
                                27,"[38;5;202m-1:",27,"[0m",27,"[4E",27,"[0J",0>, edx);

                            prefetcht2  [Count]
                            prefetcht2  [Count+32]
                            prefetcht2  [Count+64]

                            sub         rsp, 80
                            pthread_create(rsp, NULL, &RS_thread, 1);
                            pthread_create(&rsp+8, NULL, &RS_thread, 2);
                            test        [flags], FLAG_LIGHTWEIGHT   ; 2 extra for lightweight mode
                            jz          @f
                            cmp         [proc_count], 6             ; also ensure 2 free cores
                            jb          @f
                            pthread_create(&rsp+64, NULL, &RS_thread, 3);
                            pthread_create(&rsp+72, NULL, &RS_thread, 4);

                    @@      lock or     [flags], FLAG_UNLOCKED

                            mov         dx, 0011b
                            cmp         [proc_count], 6
                            jb          @f
                            mov         di, 1111b
                            test        [flags], FLAG_LIGHTWEIGHT
                            cmovnz      dx, di
                    @@      pause
                            mfence
                            mov         ax, [flags]
                            and         ax, 0_00FFh
                            shr         ax, 4
                            cmp         ax, dx
                            jne         @b

                            clock_gettime(CLOCK_REALTIME_COARSE, &rsp+32);

                    @1      usleep(50'000);

                            read(STDIN_FILENO, &typebuff, 8);
                            test        eax, eax
                            jle         @f2
                            cmp         [typebuff], 'q'
                            jne         @f
                            lock or     [flags], FLAG_MUST_EXIT
                            jmp         @f2
                    @@      cmp         [typebuff], 'Q'
                            jne         @f
                            lock or     [flags], FLAG_MUST_EXIT

                            ; test        [flags], FLAG_UPDATED
                            ; jz          @3f

                    @@      clock_gettime(CLOCK_REALTIME_COARSE, &rsp+16);

                    @rdata  billion     xd 1'000'000'000
                    @rdata  million     xd 1'000'000
                            finit

                            fild        [Count.tries]
                            fidiv       [million]
                            fdecstp

                            fstcw       [rsp+48]
                            xor         [rsp+49], byte 1100b
                            fldcw       [rsp+48]

                            fild        qword [rsp+16]
                            fild        qword [rsp+24]
                            fild        qword [rsp+32]
                            fild        qword [rsp+40]
                            fidiv       [billion]
                            faddp
                            fstp        st3
                            fidiv       [billion]
                            faddp
                            fsubrp
                            fld         st0

                            fistp       [Run.seconds]
                            fisub       [Run.seconds]
                            wait
                            mov         eax, [Run.seconds]
                            mov         ecx, 86400  ; days
                            mov         r8d, 3600   ; hours
                            mov         r9d, 60     ; minutes
                            cqo
                            div         ecx
                            mov         [Run.days], eax
                            mov         eax, edx
                            cqo
                            div         r8d
                            mov         [Run.hours], eax
                            mov         eax, edx
                            cqo
                            div         r9d
                            mov         [Run.minutes], eax
                            mov         [Run.seconds], edx
                            fiadd       [Run.seconds]

                            mov         eax, 7
                            mov         edx, 174
                            mov         ecx, 114
                            test        [flags], FLAG_FAIL_ACK
                            cmovnz      eax, edx
                            test        [flags], FLAG_ZERO_ACK
                            cmovnz      eax, ecx
                            mov         r10d, 7
                            mov         r11d, 8
                            mov         r8d, eax
                            test        [flags], FLAG_NO_SEED
                            cmovnz      r8d, r11d
                            cmovnz      r10d, r11d
                            fprintf(*stdout, <27,"8",27,"[8F",27,"[8C",27,"[0;37m% 10u",27,"[2C% 10u", \
                            27,"[2C% 10u",27,"[38;5;%um",27,"[2C% 10u",27,"[2C% 10u",27,"[2C% 10u", \
                                27,"[2E",27,"[38;5;%um",27,"[8C% 10u",27,"[2C% 10u",27,"[2C% 10u",27,"[38;5;%um", \
                                27,"[2C% 10u",27,"[2C% 10u",27,"[2C% 10u",27,"[2E",27,"[37m",27,"[8C% 10u", \
                                27,"[2C% 10u",27,"[2C% 10u",27,"[38;5;%um",27,"[2C% 10u",27,"[2C% 10u",27, \
                                "[2C% 10u",27,"[2E",27,"[37m",27,"[47G% 17.2LfMi",27,"[3G",27,"[1;34m", \
                                "Frying time: %ud %02u:%02u:%04.1Lf ",27,"[2E",27,"[0m",27,"[0J",0>, \
                                *Count.p1.rand.16, *Count.p1.rand.32, *Count.p1.rand.64, r10d, \
                                *Count.p1.seed.16, *Count.p1.seed.32, *Count.p1.seed.64, eax, \
                                *Count._0.rand.16, *Count._0.rand.32, *Count._0.rand.64, r8d, \
                                *Count._0.seed.16, *Count._0.seed.32, *Count._0.seed.64, \
                                *Count.m1.rand.16, *Count.m1.rand.32, *Count.m1.rand.64, r10d, \
                                *Count.m1.seed.16, *Count.m1.seed.32, *Count.m1.seed.64, st1, \
                                *Run.days, *Run.hours, *Run.minutes, st0);

                            ; Benchmark display (random numbers per second)
                            lock btc    [flags], FLAG_BIT_BM_TOGGLE ;
                            jnc         @f2                         ; bistable action
                            mov         rax, [rsp+24]
                            mov         r10, 100'000'000
                            cqo
                            div         r10
                            cmp         al, 5
                            je          @f
                            cmp         al, 0
                            jne         @f2

                    @@      xor         r10d, r10d
                            mov         r11d, 2
                            xchg        [Count.benchmark], r10d
                            lock bts    [flags], FLAG_BIT_BM_UNLOCK ;
                            jnc         @f                          ; discard first result

                            cvtsi2sd    xmm0, r10d
                            cvtsi2sd    xmm1, r11d
                            cvtsi2sd    xmm2, [million]
                            mulsd       xmm0, xmm1
                            divsd       xmm0, xmm2

                            fprintf(*stdout, \
                                <27,"8",27,"[2F",27,"[67G",27,"[37m","│ % 5.2lfMn/s",27,"[2E",0>, xmm0);

                    @rdata  status_fmt  xb 27,"8",27,"[12F",27,"[29C",27,"[%umCPU has %s",27,"[0m",27,"[12E",0
                    @@      test        [flags], FLAG_HAS_ZERO
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
                            test        [flags], FLAG_LIGHTWEIGHT
                            jz          @f
                            cmp         [proc_count], 6
                            jb          @f
                            pthread_join([rsp+64], NULL);
                            pthread_join([rsp+72], NULL);

                    @@      add         rsp, 80

                            fprintf(*stdout, <27,"8",27,"[0m",27,"[2F%s",27,"[3G",27,"[36m", \
                                "Finished. Iterations done: %lu.", \
                                27,"[0m",27,"[2E",27,"[?25h",27,"[0J",0>, &blank_row, *Count.tries);
                            fflush(*stdout);

                            jmp         Main.end

        Main.abort:         fprintf(*stdout, <27,"8",27,"[?25h",27,"[2F%s", \
                                27,"[3G",27,"[1;33mAborted.",27,"[0m",27,"[2E",27,"[0J",0>, \
                                &blank_row);

        Main.end:           xor         [term.lflag], ECHO or ICANON
                            tcsetattr(STDIN_FILENO, TCSAFLUSH, &term);

                            fcntl(STDIN_FILENO, F_GETFL, 0);
                            and         eax, not O_NONBLOCK
                            fcntl(STDIN_FILENO, F_SETFL, eax);

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
                            test        [flags], FLAG_MUST_EXIT
                            jnz         .end
                            rdrand      dx
                            jnc         @1b
                            lock inc    [Count.benchmark]

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

                            test        [flags], FLAG_NO_SEED
                            jnz         @f5
                    @@      pause
                            test        [flags], FLAG_MUST_EXIT
                            jnz         .end
                            rdseed      cx
                            jnc         @b
                            lock inc    [Count.benchmark]

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
                            test        [flags], FLAG_MUST_EXIT
                            jnz         .end
                            rdrand      eax
                            jnc         @b
                            lock inc    [Count.benchmark]

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

                            test        [flags], FLAG_NO_SEED
                            jnz         @f5
                    @@      pause
                            test        [flags], FLAG_MUST_EXIT
                            jnz         .end
                            rdseed      r9d
                            jnc         @b
                            lock inc    [Count.benchmark]

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
                            test        [flags], FLAG_MUST_EXIT
                            jnz         .end
                            rdrand      rdi
                            jnc         @b
                            lock inc    [Count.benchmark]

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

                            test        [flags], FLAG_NO_SEED
                            jnz         @f5
                    @@      pause
                            test        [flags], FLAG_MUST_EXIT
                            jnz         .end
                            rdseed      rsi
                            jnc         @b
                            lock inc    [Count.benchmark]

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

                            shld        rax, rdi, 48
                            call        .delay

                            ; mov         esi, 600'000
                            ; mov         rax, [Count.tries]
                            ; cqo
                            ; div         rsi
                            ; cmp         rdx, 1'000
                            ; ja          @f
                            ; lock or     [flags], FLAG_UPDATED

                    @@      test        [flags], FLAG_MUST_EXIT
                            jz          @1b

            .end:           pop         rbp
                            xor         rax, rax
                            ret

            .delay:         test        [flags], FLAG_LIGHTWEIGHT   ; al = µs
                            jnz         @f
                            ret

                    @@      sub         rsp, 8

                            and         al, 3Fh ; 1 to 64 µs sleep
                            inc         al      ; Use data from random number as sleep shuffling factor
                            movzx       edi, al ; (make threads async, lowering CPU usage)

                            usleep(edi);
                            mfence
                            test        [flags], FLAG_MUST_EXIT
                            jz          @f
                            add         rsp, 16
                            jmp         .end

                    @@      sched_yield();
                            add         rsp, 8
                            ret

