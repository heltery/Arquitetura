.386

;---------------------------------------------
;UNIVERSIDADE FEDERAL DA PARAIBA
;CURSO: ENGENHARIA DA COMPUTACAO
;DISCIPLINA: ARQUITETURA DE COMPUTADORES
;DUPLA: HELTER YORDAN    - 11406573
;       Gabiel Alcantara - 20160110279
;---------------------------------------------

.model flat,stdcall 

option casemap:none 

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc
include \masm32\macros\macros.asm
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib


;/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.data



;------------ MENSAGENS ------------------------

;0h = \0 em strings

msgAvaliacoes db " Quantas avaliacoes teve? ",0ah,0h
msgNotaInicio db " Informe a nota ",0h
msgNotaFim db " : ",0h
msgAprovado db 0ah, " Aluno Aprovado! PARABENS! ", 0ah, 0h
msgReprovado db 0ah," Aluno reprovado direto! ", 0ah, 0h
msgFinal1 db 0ah," Aluno vai pra final precisando de ", 0h
msgFinal2 db " ! ", 0ah, 0h

msgloop db 0ah, " Deseja ver a situacao de outro aluno? [s/n] ", 0ah, 0h

;-----------------------------------------------


;--- VARIAVEIS UTILIZADAS NO HANDLE E CONSOLE WHITE/READ ---

;DWORD TEM 32 BITS SEM SINAL // DB TEM 1 BYTE

consoleInHandle dword ?                                                                                     
consoleOutHandle dword ?
writeCount dword ?
readCount dword ?
stringEntrada db 5 dup(?)
entradaConvertida db 5 dup(?)


;-----------------------------------------------------------


;--------- VARIAVEIS DE UTILIZACAO --------------

; REAL8 SAO 8 BYTES

notaAprovado real8 7.0
notaReprovado real8 4.0

aux real8 ?
media dd ?
notaFinal real8 ?
varA dd ?
varB dd ?
varC real8 ?

peso1 real8 0.6
peso2 real8 0.4
peso3 real8 5.0
cal real8 ?

sim db 115
resposta dd 0


;------------------------------------------------






;////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.code
start:



;------------------------------------------------
invoke GetStdHandle, STD_OUTPUT_HANDLE      ;imprimir no console, Get..=identificador, STD...=parametro
mov consoleOutHandle, eax

invoke GetStdHandle, STD_INPUT_HANDLE                            
mov consoleInHandle, eax                 
;-----------------------------------------------


retorno:


;-------------- MENSAGEM DE ENTRADA PEDINDO A QUANTIDADE DE AVALIACOES E GRAVANDO ----------------------
invoke WriteConsole, consoleOutHandle, addr msgAvaliacoes, sizeof msgAvaliacoes, addr writeCount, NULL
invoke ReadConsole, consoleInHandle, addr stringEntrada, sizeof stringEntrada, addr readCount, NULL

call converteEntrada             ;chamando a função que criei para converter buscando o valor na tabela ASC
invoke atodw, addr stringEntrada ;convertendo a string para inteiro
mov varA, eax                    ;movendo o resultado que ficou em eax para varA

;-------------------------------------------------------------------------------------------------------



;------------------------------ MENSAGEM PEDINDO AS NOTAS E FAZENDO A SOMA UTILIZANDO A PILHA DE EXECUÇÃO DA FPU -------------------------------------

xor ecx, ecx        ;REGISTRADOR UTILIZADO PARA LAÇOS // colocando ele em 0
finit               ;INICIANDO NOSSO ARRAY DE FLOAT COM 0
fld aux             ;EMPILHANDO aux NA PILHA DE EXECUÇÃO DA FPU

    laco:

        inc ecx
        mov varB, ecx
        
        invoke dwtoa, varB, addr entradaConvertida                                                                    ;CONVERTENDO varB PARA STRING
        
        invoke WriteConsole, consoleOutHandle, addr msgNotaInicio, sizeof msgNotaInicio, addr writeCount, NULL        ;IMPRIMINDO NA TELA A MENSAGEM
        invoke WriteConsole, consoleOutHandle, addr entradaConvertida, sizeof entradaConvertida, addr writeCount, NULL
        invoke WriteConsole, consoleOutHandle, addr msgNotaFim, sizeof msgNotaFim, addr writeCount, NULL

        invoke ReadConsole, consoleInHandle, addr stringEntrada, sizeof stringEntrada, addr readCount, NULL           ;RECEBENDO O VALOR DA NOTA
        invoke StrToFloat, addr stringEntrada, addr varC        ; CONVERTENDO O VALOR RECEBIDO PARA FLOAT (REAL8)

        fld varC ;EMPILHANDO varC NA PILHA DE EXECUÇÃO DA FPU (RECURSIVO POIS ESTA NO LAÇO)

        fadd st(0), st(1)   ;SOMANDO ST(0) E ST(1) E COLOCANDO EM ST(0)
        
        mov ecx, varB

cmp ecx, varA       ;COMPARANDO ecx COM O VALOR DA QUANTIDADE DE NOTAS
jl laco

fstp aux             ;APOS A EXECUÇÃO RECURSIVA O VALOR DO TOPO DA PILHA IRA CONTER A SOMA DAS NOTAS E VAMOS PEGAR O VALOR E PASSAR PARA AUX E DAR UM POP NO VALOR NA PILHA DE EXECUÇÃO

printf("\nSoma das notas = %f", aux)            ; [[[ TESTANDO ]]]

;------------------------------------------------------------------------------------------------------------------------------------------------------


;---------------------- PEGANDO A SOMA DAS NOTAS E A QUANTIDADE DE NOTAS E FAZENDO A DIVISÃO PARA OBTER A MÉDIA ---------------------------------------

invoke dwtoa, varA, addr entradaConvertida              ;CONVERTENDO A VARIAVEL varA PARA STRING
invoke StrToFloat, addr entradaConvertida, addr varC    ;CONVERTENDO A VARIAVEL entradaConvertida QUE ESTA COMO STRING PARA FLOAT E GRAVANDO EM varC

fld varC            ;EMPILHANDO varC QUE CONTEM O VALOR DA QUANTIDADE DE NOTAS
fld aux             ;EMPILHA O VALOR DA SOMA DAS NOTAS NOVAMENTE, POREM SÓ DEPOIS DE EMPILHAR A QUANTIDADE DE NOTAS

fdiv st(0), st(1)   ;DIVIDINDO O VALOR QUE ESTA EM st(0) POR st(1) E SALVANDO EM st(0)

fst aux             ;PEGANDO O VALOR QUE ESTA NO TOPO DA PILHA, QUE SERÁ O VALOR DA DIVISÃO  E SAVANDO EM AUX

printf("\nSoma das notas dividido pela quantidade de notas = %f\n", aux)          ;[[[ TESTANDO ]]]


;------------------------------------------------------------------------------------------------------------------------------------------------------


;--------------------- COMPARANDO PARA VER SE O ALUNO PASSOU, FOI PRA FINAL OU FICOU REPROVADO --------------------------------------------------------

finit           ;LIMPANDO A PILHA DE EXECUÇÃO DA FPU

fld [notaAprovado]        ;EMPILHANDO ( 7.0 ) QUE É A NOTA QUE VOU USAR PRA COMPARAR SE O ALUNO É APROVADO
fld [aux]                 ;EMPILHANDO A MEDIA

fcom                    ;COMPARANDO ST(0) COM ST(1)
fstsw ax                ;FUNÇÕES REFERENTES A MANIPULAÇÃO DAS FLGS DE STATUS DA FPU
sahf

jae aprovado            ;COMPARA SE É MAIOR OU IGUAL E FAZ O DESVIO PARA "APROVADO"
jb naoAprovado          ;COMPARA SE É MENOR E FAZ O DESVIO PARA "REPROVADO"



jmp outroAluno




            ;------ APROVADO --------------------------------------------------------------------------------
            aprovado:

            invoke WriteConsole, consoleOutHandle, addr msgAprovado, sizeof msgAprovado, addr writeCount, NULL
            jmp outroAluno
            ;-----------------------------------------------------------------------------------------------






            ;------ NÃO APROVADO ---------------------------------------------------------------------------
            naoAprovado:

            finit
            fld notaReprovado
            fld aux

            fcom
            fstsw ax
            sahf

            jb reprovado

                        ;-------- CALCULANDO VALOR DA NOTA PRA FINAL ----------

                        finit       ;ZERANDO A PILHA DA FPU
                        fld peso1
                        fld aux     ;EMPILHANDO O VALOR DA MEDIA
                        fmul st(0), st(1)   ;MULTIPLICANDO ST(0) QUE CONTEM O VALOR DA MEDIA POR PESO1 QUE VALE 0.6
                        fst cal     

                        finit       ;ZERANDO A PILHA DA FPU
                        fld cal     ;EMPILHANDO O VALOR DA MULTIPLICAÇÃO ACIMA
                        fld peso3
                        fsub st(0), st(1)  ;SUBTRAINDO ( 5 - CAL )
                        fst cal

                        finit       ;ZERANDO A PILHA DA FPU
                        fld peso2
                        fld cal     ;EMPILHANDO O VALOR DE CAL
                        fdiv st(0), st(1)  ;DIVIDINDO O VALOR DE CAL PELO PESO2 QUE VALE 0.4
                        fst cal

                        invoke FloatToStr, cal, addr stringEntrada
                        
                        invoke WriteConsole, consoleOutHandle, addr msgFinal1, sizeof msgFinal1, addr writeCount, NULL
                        invoke WriteConsole, consoleOutHandle, addr stringEntrada, sizeof stringEntrada, addr writeCount, NULL
                        invoke WriteConsole, consoleOutHandle, addr msgFinal2, sizeof msgFinal2, addr writeCount, NULL
                        
                        
        
                        ;------------------------------------------------------

            jmp outroAluno
            ;------------------------------------------------------------------------------------------------- 






            ;------ REPROVADO DIRETO -------------------------------------------------------------------------
            reprovado:
            
            invoke WriteConsole, consoleOutHandle, addr msgReprovado, sizeof msgReprovado, addr writeCount, NULL
            jmp outroAluno
            ;-------------------------------------------------------------------------------------------------







;-----------------------------------------------------------------------------------------------------------------------------------------------------




;------------------------------------------
outroAluno:

    invoke WriteConsole, consoleOutHandle, addr msgloop, sizeof msgloop, addr writeCount, NULL
    invoke ReadConsole, consoleInHandle, addr stringEntrada, sizeof stringEntrada, addr readCount, NULL

    mov al,stringEntrada[0];

    cmp al, 115
    je retorno
    jmp retorno
    
;--------------------------------------------

;--------------------------------------------
converteEntrada:
	mov esi, offset stringEntrada
prox2:
     mov al, [esi]
     inc esi
     cmp al, 48 ; Menor que ASCII 48
     jl  feito2
     cmp al, 58 ; Menor que ASCII 58
     jl  prox2
feito2:
     dec esi
     xor al, al
     mov [esi], al
     ret
;-------------------------------------------


;----------
fim:
    end start
;----------