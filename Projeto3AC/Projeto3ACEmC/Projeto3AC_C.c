#include <reg51.h>
// Definição das constantes  /Definimos estas constantes para uma melhor manutencao do programa permitindo-nos mudar o funcionamento do mesmo apenas alterando estes valores
#define ciclo100ms 10	
#define numeroCiclosMostrarResposta 20 //Por exemplo se quisermos fazer ciclos de 4s(2s para cada estado do display) mudamos de 20 para 40 ou se quisermos mudar a contagem do relogio tbm o podemos fazer alterando apenas as nossas constantes

// Timer
#define TempoL 0xF0
#define TempoH 0xD8

//pins usados
sbit B1 = P3^2;      // Botão 1
sbit BResposta = P3^3; // PIN de qualquer resposta
sbit BA = P3^4;      // Botão A
sbit BB = P3^5;      // Botão B
sbit BC = P3^6;      // Botão C
sbit BD = P3^7;      // Botão D


//Funcoes usadas
void ativaInterrupcoes(void);
void prioridadeInterrupcoes(void);
void ativaTemporizador(void);
void terminarcontador(void);
void atualizarDisplays(int, int);
void atualizarDisplayResposta(char);

//Variaveis
int tempoInicial = ciclo100ms;		//Variavel que conta o numero de ciclos de 10 ms  //10 ciclos de 10ms para dar 100 ms
int segundos = 5;					//Segundos do contador  //segundos iniciais
int miliSegundos = 0;			//milisegundos do contador  //milisegundos iniciais
bit congelarTimer = 1;		//variavel booleana que nos diz se o timer esta parado a mostrar 5s //Inicialmente o timer esta "congelado"
bit esperarResposta = 0;	 //variavel booleana que nos diz se esperamos uma resposta do utilizador ou nao  //Inicialmente nao esperamos uma resposta apenas um input do botao 1
int segundosRestantes = 5;	//Segundos restantes quando o utilizador respondeu  //Inicialmente restam 5 segundos para responder
int miliSegundosRestantes = 0;  //milisegundos restantes quando o utilizador respondeu  //Inicialmente restam 0 milisegundos para responder
int cicloMostrarResposta = numeroCiclosMostrarResposta; //contador que serve para realizar o ciclo de 1 em 1s  //inicalmente temos 20 ciclos de 10ms para dar 2s, 1 para cada estado do display
char Resposta = '0';	//Inicialmente nao temos uma resposta

//Funcao primaria
void main(){
	ativaInterrupcoes();		//Ativar as interrupcoes
	prioridadeInterrupcoes();		//Atribuir as prioridades a cada interrupcao
	ativaTemporizador();		//ativar o timer
	while(1);			//ciclo da funcao principal, esperando pelas interrupcoes para reagir
}

void ativaInterrupcoes(){
	IE = 0x87; // Ativa interrupções timer 0 e externas 1 (P3.3) e 0 (P3.2)
   IT0 = 1; // A interrupção externa será detectada na transição descendente do clk 
}
void prioridadeInterrupcoes() {
    IP = 0x01; // A interrupcao externa 0 tem a maior prioridade
}

void ativaTemporizador() {
    TMOD = 0x01; // Ativa o temporizador no modo de leitura de 16 bits
    TL0 = 0xF0; // Valor do byte menos significativo
    TH0 = 0xD8; // Valor do byte mais significativo
    TR0 = 1; // Ativa o temporizador 0, para fazer contagens de 10ms
	return;
}

void Timer(void) interrupt 1 {
	  TL0 = 0xF0; // Valor do byte menos significativo
    TH0 = 0xD8; // Valor do byte mais significativo
	tempoInicial--;
	if(tempoInicial > 0){  //Se o tempo inicial nao e 0 entao so decrementamos o tempo inicial e continuamos
		return;
	}
	else{										//Se nao resetamos o tempo inicial e verificamos se estamos a espera de uma resposta
		tempoInicial = ciclo100ms;
		if(esperarResposta){			//Se sim decrementamos o tempo conforme possivel
		if(miliSegundos == 0){	//Se os milisegundos ja forem 0 decrementamos os segundos
			if(segundos==0){			//Se tanto os milisegundos como os segundos sao 0 terminamos o contador
				terminarcontador();
			}
			else{									//Caso contrario decrementamos os segundos e colocamos os milisegundos a 9
				segundos--;
				miliSegundos = 9;
			}
		}
		else{									//Mas caso os milisegundos nao sejam 0 decrementamos milisegundos
			miliSegundos--;
		}
		atualizarDisplays(segundos, miliSegundos);	//Chamamos a funcao que atualiza o display conforme o tempo dado
	}else if(congelarTimer){			//Se estamos no estado de congelar o timer a 5s entao mantemos o display com 5 segundos e 0 milisegundos
		atualizarDisplays(5, 0);
	}
	else{											//Caso nao se espere uma resposta quer dizer que ja a temos logo vamos fazer o ciclo onde mostramos a resposta e o tempo restante para responder
		cicloMostrarResposta--;
		if(cicloMostrarResposta >= (numeroCiclosMostrarResposta/2)){  //Se o ciclo estiver entre 10 e 20 (1 e 2 segundos) mostramos o tempo restante
			atualizarDisplays(segundosRestantes, miliSegundosRestantes);
		}
		else{  //Caso contrario mostramos a resposta dada atraves da funcao encarregue disso
			if(cicloMostrarResposta == 0){
				cicloMostrarResposta = numeroCiclosMostrarResposta;
			}
			atualizarDisplayResposta(Resposta); //Esta funcao ira colocar no display -. e a resposta dada pelo utilizador
		}
	}
		
}
}

void atualizarDisplays(int segundos, int miliSegundos){  //Para colocar o tempo no display esta funcao recebee os segundos e os milisegundos e faz um switch para cada um deles
	switch(segundos){							//No caso dos segundos verifica que valor tem e coloca-o com o bit do . ativo para ficar 0. por exemplo. 
		case 0:
			P1 = 0x40;						//Estes valores são apenas os equivalentes em hexadecimal dos codigos em binario nas tabelas do enunciado para cada valor
			break;
		case 1:
			P1 = 0x79;
			break;
		case 2:
			P1 = 0x24;
			break;
		case 3:
			P1 = 0x30;
			break;
		case 4:
			P1 = 0x19;
			break;
		case 5:
			P1 = 0x12;
			break;
		case 6:
			P1 = 0x02;
			break;
		case 7:
			P1 = 0x78;
			break;
		case 8:
			P1 = 0x00;
			break;
		case 9:
			P1 = 0x10;
			break;
		default:
			break;
	}
	switch(miliSegundos){			//Os milisegundos sao iguais aos segundos mas com o bit do . desativado para ficar com o resultado de 1.0 por exemplo
		case 0:
			P2 = 0xC0;
			break;
		case 1:
			P2 = 0xF9;
			break;
		case 2:
			P2 = 0xA4;
			break;
		case 3:
			P2 = 0xB0;
			break;
		case 4:
			P2 = 0x99;
			break;
		case 5:
			P2 = 0x92;
			break;
		case 6:
			P2 = 0x82;
			break;
		case 7:
			P2 = 0xF8;
			break;
		case 8:
			P2 = 0x80;
			break;
		case 9:
			P2 = 0x90;
			break;
		default:
			break;
	}
	return;
}
void terminarcontador(){		//Esta funcao e chamada quando o tempo terminou e neste caso vamos...
	esperarResposta = 0;		//Deixar de esperar uma resposta visto que ja acabaou o tempo
	Resposta = '0';					//Atribuir uma resposta nula a resposta
	segundosRestantes = 0;	//Deixar os segundos e milisegundos restantes a 0
	miliSegundosRestantes = 0;
	atualizarDisplays(segundosRestantes, miliSegundosRestantes);	//Atualizar o display com estes valores
	return;
}

void atualizarDisplayResposta(char Resposta){		//PAra atualizar o display com a resposta e muito semelhante a atualizar com os numeros
	P1 = 0x3F;		//Equivalente a -. que e comum a todas as respostas logo fica fora do switch por conveniencia
	switch(Resposta){					//VAmos fazer um switch com a resposta
		case 'A':							//E vamos colocar o valor correspondente a letra respondida no display 2, tal como acontecia na funcao de mostrar o tempo
			P2 = 0x88;
			break;
		case 'B':
			P2 = 0x83;
			break;
		case 'C':
			P2 = 0xC6;
			break;
		case 'D':
			P2 = 0xA1;
			break;
		case '0':
			P2 = 0xBF;
			break;
		default:
			break;
	}
	return;
}

void botao1(void) interrupt 0{			//Quando o botao 1 e pressionado esta interrupcao e ativa
	if(esperarResposta == 0 && congelarTimer == 0){		//Se nao esperamos uma resposta  e o temporizador nao esta congelado entao vamos congelar o timer e resetar o contador do ciclo de 100ms pois vamos resetar o timer
		tempoInicial = ciclo100ms;
		congelarTimer = 1;
		segundos = 5;
		miliSegundos = 0;
	}
	else if(esperarResposta == 0 && congelarTimer ==1){	//Se nao esperamos uma resposta mas o tempo ja esta congelado entao vamos comecar a esperar uma resposta e vamos descongelar o timer de forma a permitir o temporizador decrescer
		tempoInicial = ciclo100ms;		//Reiniciamos sempre o tempoInicial pois estamos a resetar o timer
		esperarResposta = 1;
		congelarTimer = 0;
	}
	else if(esperarResposta == 1){		//Se esperamos uma resposta entao ao clicar no botao 1 o temporizador reseta para os 5 segundos e atualiza o display e ja nao esperamos uma resposta, apenas input do botao 1
		tempoInicial = ciclo100ms;		
		segundos = 5;
		miliSegundos = 0;
		atualizarDisplays(segundos, miliSegundos);
		congelarTimer = 1;
		esperarResposta = 0;
	}
}

void botaoRepostas(void) interrupt 2{ //Se o botao com as portas and para todos os botoes de resposta for ativo quer dizer que alguma resposta foi pressionada
	if(esperarResposta){		//Neste caso se esperamos uma resposta entao deixamos de o fazer uma vez que acabamos de receber uma
		esperarResposta = 0;
		segundosRestantes = segundos;		//o tempo restante e o atual na hora que o botao foi clicado
		miliSegundosRestantes = miliSegundos;
		cicloMostrarResposta = numeroCiclosMostrarResposta;

		if(BA == 0){				//Verificamos qual dos botoes e que esta ativo e atribuimos a resposta na variavel correspondente
			Resposta = 'A';	//Nota: Caso dois botoes sejam clicados simultanemante, no exato mesmo instante, o que e extremamente improvavel e irrealista, a resposta dada sera por preferencia de ordem alfabetica
			return;
		}
		else if(BB == 0){
			Resposta = 'B';
			return;
		}
		else if(BC == 0){
			Resposta = 'C';
			return;
		}
		else if(BD == 0){
			Resposta = 'D';
			return;
		}
		else{
			Resposta = '0';
			return;
		}
	}
	else{
		return;
	}
}