; Definição das constantes

; Display 1
D1 EQU P1

; Display 2
D2 EQU P2


; Inputs
Inputs EQU P3
B1 EQU P3.2 ; Botão 1
BResposta EQU P3.3 ; PIN de qualquer resposta
BA EQU P3.4 ; Botão A
BB EQU P3.5 ; Botão B
BC EQU P3.6 ; Botão C
BD EQU P3.7 ; Botão D

; Timer
TempoL EQU 0xF0 ;F0D8 é 61656 em decimal que é quando da overflow no timer
TempoH EQU 0xD8
TempoInicial EQU 0x0A ;

; Função principal
ORG 0000h
JMP Inicio

; Tratar interrupção externa 0
CSEG AT 0003h
JMP InterrupcaoBotao1

; Tratar interrupção externa 1
CSEG AT 0013h
JMP InterrupcaoBotaoResposta

; Tratar a interrupção de temporização 0, para contar 10ms
CSEG AT 000Bh
JMP InterrupcaoTemp0

;Para guiar vou definir que as variaveis sao as seguintes:
;R7 sera o contador de 1 segundo que muda entre a resposta e o tempo restante
;R3 sera uma variavel booleana que nos diz se estamos a espera de uma resposta do utilizador ou nao
;R4 sera a variavel dos milisegundo a mostrar
;R5 sera o mesmo que R4 mas para os segundos
;R1 sera o valor dos segundos que faltavam para o utilizador dar a resposta
;R2 sera os milisegundos que faltavam para acabar o timer
;R0 sera o tempo inicial
;R6 sera a resposta dada pelo utilizador
;O A sera variavel assistente nas funcoes

CSEG AT 0050h
Inicio:
    MOV SP, #07h ; Endereço inicial do stack pointer
    CALL Inicializacoes ; Chama a rotina de inicializações
    CALL PrioridadeInterrupcoes ; Chama a rotina que define as prioridades das interrupções
    CALL AtivaInterrupcoes ; Chama a rotina que ativa as interrupções necessárias
    CALL AtivaTemporizador ; Chama a rotina que ativa o temporizador
    SJMP Principal ; Vai para a função principal

Principal:
    SJMP Principal ; Loop principal infinito

Inicializacoes:
    MOV Inputs, #0FFh ; Configurar P3 como input
    MOV D1, #0FDh ; Colocar os displays como "-". FD é 11111101 em binário, valor que coloca o display no valor pretendido
    CLR C ; Limpar o carry
	MOV R4, #0
	MOV R1, #05h
	MOV R2, #00h
	MOV R3, #0
	MOV R5, #0
	MOV R6, #0eh
	MOV R7, #0
	
    RET

AtivaInterrupcoes:
    MOV IE, #10000111b ; Ativa interrupções timer 0 e externas 1 (P3.3) e 0 (P3.2)
    SETB IT0 ; A interrupção externa será detectada na transição descendente do clk 
    RET

PrioridadeInterrupcoes:
    MOV IP, #00000001b ; O timer 0 tem a maior prioridade
    RET

AtivaTemporizador:
    MOV TMOD, #00000001b ; Ativa o temporizador no modo de leitura de 16 bits
    MOV TL0, #TempoL ; Valor do byte menos significativo
    MOV TH0, #TempoH ; Valor do byte mais significativo
    MOV R0, #TempoInicial ; Indica o número de contagens de 10ms que terão de ser realizadas para fazer alguma alteração, neste caso 10, 100 milissegundos, ou 0.1s
    SETB TR0 ; Ativa o temporizador 0, para fazer contagens de 10ms
    RET

; Tratamento da interrupção externa 1, ou seja, quando algum dos botões de resposta foi apertado
InterrupcaoBotaoResposta:
	MOV A, R3
    JNZ ObterResposta ; Se estamos à espera de uma resposta e o utilizador pressiona uma resposta, chamamos a rotina que obtém a resposta
    ; Se não estamos à espera de uma resposta não fazemos nada
    RETI

ObterResposta:
    ; Vamos comparar com todos os pinos de resposta para ver qual botão de resposta foi pressionado
    JNB BA, RespostaA
    JNB BB, RespostaB
    JNB BC, RespostaC
    JNB BD, RespostaD
    RETI

RespostaA:  ;Se a resposta A for seleciona, coloca-se na variavel relacionada a resposta dada o valor A para conveniencia
    MOV R6, #0Ah
    MOV R3, #0		;Deixamos de esperar uma resposta
	MOV A, R5		;Copiamos o tempo restante para as suas variáveis relacionadads
	MOV R1, A
	MOV A, R4
	MOV R2, A
	MOV R7, #13h	;Resetamos o timer de ciclo entre mostrar resposta e tempo restante
    RETI

RespostaB:			;Repetimos o mesmo processo para cada uma das diferentes respostas
    MOV R6, #0Bh
    MOV R3, #0
	MOV A, R5
	MOV R1, A
	MOV A, R4
	MOV R2, A
	MOV R7, #13h
    RETI

RespostaC:
    MOV R6, #0Ch
    MOV R3, #0
	MOV A, R5
	MOV R1, A
	MOV A, R4
	MOV R2, A
	MOV R7, #13h

    RETI

RespostaD:
    MOV R6, #0Dh
    MOV R3, #0
	MOV A, R5
	MOV R1, A
	MOV A, R4
	MOV R2, A
	MOV R7, #13h
    RETI

; Tratamento da interrupção externa 0, ou seja, do botão 1
InterrupcaoBotao1:
	MOV A, R5
    CJNE A, #05, IniciarContador ; Se não estamos à espera de uma resposta então temos de iniciar o contador
    JMP	ComecarContador;Se estamos à espera de uma resposta não faz nada
    RETI

IniciarContador:		;Quando iniciamos o contador colocamos os segundos a 5 e  os milisegundos a 0 e alteramos a variavel de esperar resposta para true
    MOV R0, TempoInicial
	MOV R4, #00h
    MOV R5, #05h
	MOV R3, #00h
	MOV R6, #0eh
	CALL MostrarTimer
	MOV R1, #05h
	MOV R2, #00h
    RETI
ComecarContador:		;Quando iniciamos o contador colocamos os segundos a 5 e  os milisegundos a 0 e alteramos a variavel de esperar resposta para true
	MOV R0, #TempoInicial
    MOV R3, #01h
	
    RETI

; Tratamento da Interrupção de overflow na contagem do timer0
InterrupcaoTemp0:
    MOV TL0, #TempoL ; Inicia a contagem de 10ms
    MOV TH0, #TempoH ; TL0 e TH0 guardam o número para iniciar contagens
    DJNZ R0, FimIT0 ; Decrementa a variável para fazer contagens de 0.1s e se não for 0 continua a contagem 
     MOV R0, #TempoInicial ; Se for 0 significa que já passaram 100ms então fazemos o que é necessário
    MOV A, R3		;Vemos se estamos a espera de uma resposta, pois se nao entao estamos a mostrar a ultima resposta dada
	JZ RespostaDada		
	CALL MostrarTimer ;Se não foi dada uma resposta metemos no display o tempo atual
	MOV A, R4		;Mas se estamos a espera de resposta vemos se os milisegundo sao 0
    JZ SubSeg
    DEC R4
    RETI

SubSeg:				;Se os milisegundos forem 0 entao subtraimos um segundo e colocamos os milisegundos como 9
    MOV A, R5		;Se os segundo tbm forem 0 entao terminamos o contador
    JZ TerminarContador
    DEC R5			;Caso contrario fazemos o esperado
    MOV R4, #09h
    RETI

TerminarContador:
	MOV R6, #0		;A resposta dada é nenhuma, de forma a mostrar -.- No display
    MOV R3, #00h	;Neste caso ja nao estamos a espera de uma resposta pois acabou o tempo
	MOV R1, #0		;os segundo e milisegundos restantes sao colocados a 0
	MOV R2, #0
    RETI
RespostaDada:
	MOV A, R7		;Se não esperamos resposta então temos alguma resposta dada ou 0.
	CLR C
	SUBB A, #0Ah
	JNC MostrarTempo;Se R7 for maior que 10 mostrar o tempo
	JMP MostrarResposta ;Se nao mostrar REsposta

MostrarResposta:
	CJNE R7, #00h, continuarMostrarResposta
	JMP resetarCiclo
	continuarMostrarResposta:
	DEC R7				;Deccrementamos o contador
	MOV A, R6			;Vamos buscar o valor de resposta guardado
	CJNE A, #0ah, naoA	;Se for A mostramos -A no display. Os bits ficam invertidos dos dados no enunciado uma vez que aqui comeca do bit mais significativo para o menos, o contrario do dado na tabela
	MOV D1, #00111111b 
	MOV D2, #10001000b  
	naoA:
	CJNE A, #0bh, naoB	;Se for B mostramos -B
	MOV D1, #00111111b 
	MOV D2, #10000011b 
	naoB:
	CJNE A, #0ch, naoC	;Se for C mostramos -C
	MOV D1, #00111111b
	MOV D2, #11000110b 
	naoC:
	CJNE A, #0dh, naoD	;Se for D mostramos -D
	MOV D1, #00111111b
	MOV D2, #10100001b 
	naoD:
	CJNE A, #0eh, naoe ;Se a resposta é e, isto significa que o timer foi resetado então continuamos a mostrar os 5 segundos restantes até o utilizador alterar R3 e começar a decrementar o timer
	MOV D1, #00010010b
	MOV D2, #11000000b
	naoe:
	CJNE A, #0, nao0_Resposta ;Se nao for nenhum mostramos -.-
	MOV D1, #00111111b
	MOV D2, #10111111b  
	nao0_Resposta:
	RETI
	resetarCiclo:
	MOV R7, #13h
	RETI
FimIT0:
	RETI

MostrarTempo:
	DEC R7				;Deccrementamos o contador
	MOV A, R2			;Vemos os milisegundos guardados quando o utilizador deu a resposta
	CJNE A, #0, nao0	;Se nao for 0 passa a frente
	MOV D2, #11000000b	;Se for colocamos no segundo display o 0
	nao0:
	CJNE A, #1, nao1	;Fazemos o mesmo ate descobrirmos o valor dos milisegundos a colocar no display2
	MOV D2, #11111001b 
	nao1:
	CJNE A, #2, nao2
	MOV D2, #10100100b  
	nao2:
	CJNE A, #3, nao3
	MOV D2, #10110000b 
	nao3:
	CJNE A, #4, nao4
	MOV D2, #10011001b 
	nao4:
	CJNE A, #5, nao5
	MOV D2, #10010010b 
	nao5:
	CJNE A, #6, nao6
	MOV D2, #10000010b 
	nao6:
	CJNE A, #7, nao7
	MOV D2, #11111000b 
	nao7:
	CJNE A, #8, nao8
	MOV D2, #10000000b 
	nao8:
	CJNE A, #9, nao9
	MOV D2, #10010000b 
	nao9:
	MOV A, R1				;Agora fazemos o mesmo para os segundos so que metemos o numero com o ponto a frente. Exemplo: 1.
	CJNE A, #0, nao0_2
	MOV D1, #01000000b  
	nao0_2:
	CJNE A, #1, nao1_2
	MOV D1, #01111001b  
	nao1_2:
	CJNE A, #2, nao2_2
	MOV D1, #00100100b 
	nao2_2:
	CJNE A, #3, nao3_2
	MOV D1, #00110000b  
	nao3_2:
	CJNE A, #4, nao4_2
	MOV D1, #00011001b  
	nao4_2:
	CJNE A, #5, nao5_2
	MOV D1, #00010010b  
	nao5_2:
	CJNE A, #6, nao6_2
	MOV D1, #00000010b  
	nao6_2:
	CJNE A, #7, nao7_2
	MOV D1, #01111000b  
	nao7_2:
	CJNE A, #8, nao8_2
	MOV D1, #00000000b
	nao8_2:
	CJNE A, #9, nao9_2
	MOV D1, #00010000b 
	nao9_2:
	RETI
	
	MostrarTimer:
	MOV A, R4			;Vemos os milisegundos guardados quando o utilizador deu a resposta
	CJNE A, #0, nao0Timer	;Se nao for 0 passa a frente
	MOV D2, #11000000b 	;Se for colocamos no segundo display o 0
	nao0Timer:
	CJNE A, #1, nao1Timer	;Fazemos o mesmo ate descobrirmos o valor dos milisegundos a colocar no display2
	MOV D2, #11111001b  
	nao1Timer:
	CJNE A, #2, nao2Timer
	MOV D2, #10100100b 
	nao2Timer:
	CJNE A, #3, nao3Timer
	MOV D2, #10110000b 
	nao3Timer:
	CJNE A, #4, nao4Timer
	MOV D2, #10011001b 
	nao4Timer:
	CJNE A, #5, nao5Timer
	MOV D2, #10010010b 
	nao5Timer:
	CJNE A, #6, nao6Timer
	MOV D2, #10000010b 
	nao6Timer:
	CJNE A, #7, nao7Timer
	MOV D2, #11111000b 
	nao7Timer:
	CJNE A, #8, nao8Timer
	MOV D2, #10000000b 
	nao8Timer:
	CJNE A, #9, nao9Timer
	MOV D2, #10010000b 
	nao9Timer:
	MOV A, R5				;Agora fazemos o mesmo para os segundos so que metemos o numero com o ponto a frente. Exemplo: 1.
	CJNE A, #0, nao0_2TImer
	MOV D1, #01000000b 
	nao0_2Timer:
	CJNE A, #1, nao1_2Timer
	MOV D1, #01111001b 
	nao1_2Timer:
	CJNE A, #2, nao2_2Timer
	MOV D1, #00100100b 
	nao2_2Timer:
	CJNE A, #3, nao3_2Timer
	MOV D1, #00110000b 
	nao3_2Timer:
	CJNE A, #4, nao4_2Timer
	MOV D1, #00011001b 
	nao4_2Timer:
	CJNE A, #5, nao5_2Timer
	MOV D1, #00010010b 
	nao5_2Timer:
	CJNE A, #6, nao6_2Timer
	MOV D1, #00000010b 
	nao6_2Timer:
	CJNE A, #7, nao7_2Timer
	MOV D1, #01111000b 
	nao7_2Timer:
	CJNE A, #8, nao8_2Timer
	MOV D1, #00000000b
	nao8_2Timer:
	CJNE A, #9, nao9_2Timer
	MOV D1, #00010000b 
	nao9_2Timer:
	RET
	
END ; Final do programa
