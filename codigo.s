;Archivo:	       Main_Proyecto_1.s
;dispositivo:	       PIC16F887
;Autor:		       Selvin E. Peralta
;Compilador:	       pic-as (v2.31), MPLABX V5.45
;
;Programa:	       Control de semaforos para dar via a 3 avenidas diferentes 
;Hardware:	       
;
;Creado:	       29 mar, 2021
;Ultima modificacion:  
      
PROCESSOR 16F887
#include <xc.inc>

; configuraci�n word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protecci�n de c�digo
 CONFIG CPD=OFF		    //sin protecci�n de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programaci�n en bajo voltaje permitida
 
;configuraci�n word2
  CONFIG WRT=OFF	//Protecci�n de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 

 MODO	EQU 0
 INC	EQU 1
 DECRE	EQU 2
	
reiniciar_Tmr0 macro	//macro
    banksel TMR0	//Banco de TMR0
    movlw   25
    ;movf    T0_Actual, W
    movwf   TMR0        
    bcf	    T0IF	//Limpiar bandera de overflow para reinicio 
    endm
reiniciar_Tmr1 macro	//macro reiniciar Tmr1
    movlw   0x0B	//1 segundo
    movwf   TMR1H	//Asignar valor a TMR1H
    movlw   0xDC
    movwf   TMR1L	//Asignar valor a TMR1L
    bcf	    TMR1IF	//Limpiar bandera de carry/interrupci�n de Tmr1
    endm
reiniciar_tmr2 macro	//Macro reinicio Tmr2
    banksel PR2
    movlw   244		//Mover valor a PR2
    movwf   PR2		
    
    banksel T2CON
    clrf    TMR2	//Limpiar registro TMR2
    bcf	    TMR2IF	//Limpiar bandera para reinicio 
    endm
    
  PSECT udata_bank0 ;common memory
 ;Variables para suicheos y cambio de estados 
    estado:	DS  1
    banderas:	DS  1
    
    semaforo1:	DS 1
    semaforo2:  DS 1
    semaforo3:  DS 1

    Tmr0_temporal:   DS	1
    T0_Actual:	    DS	1
    
    SE2_temporal:   DS	1
    SE2_Actual:	    DS	1
    
    SE3_temporal:   DS	1
    SE3_Actual:	    DS	1
    
    valorsemaforo_1:    DS 1
    display_semaforo1:	DS 1
    valor_titileo:      DS 1
 ;Varibles para el Semaforo de Configuracion 
    V1:		DS  1
    centena:	DS  1
    centena1:	DS  1
    decena:	DS  1
    decena1:	DS  1
    unidad1:	DS  1
    unidad:	DS  1  
    valor_actual:   DS	1
 ;Variables para el Semaforo 1 
    V2:		DS  1	
    centena2:	DS  1
    centena22:	DS  1
    decena2:	DS  1
    decena22:	DS  1
    unidad2:	DS  1
    unidad22:	DS  1  
 ;Varaibles para el Semaforo 2
    V3:		DS  1	
    centena3:	DS  1
    centena33:	DS  1
    decena3:	DS  1
    decena33:	DS  1
    unidad3:	DS  1
    unidad33:	DS  1  
 ;Variables para el Semaforo 3
    V4: 	DS  1	
    centena4:	DS  1
    centena44:	DS  1
    decena4:	DS  1
    decena44:	DS  1
    unidad4:	DS  1
    unidad44:	DS  1  
    
  PSECT udata_shr ;common memory
    W_T:	DS  1;1 byte apartado
    STATUS_T:DS  1;1 byte
    PCLATH_T:    DS	1
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posici�n 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT intVect, class=CODE, abs, delta=2
  ;----------------------interripci�n reset------------------------
  ORG 04h	;posici�n 0004h para interr
  push:
    movf    W_T
    swapf   STATUS, W
    movwf   STATUS_T
    movf    PCLATH, W
    movwf   PCLATH_T
  isr:
    btfsc   RBIF
    call    int_ioCB
    
    btfsc   T0IF
    call    Interr_Tmr0
    
    btfsc   TMR2IF
    call    Interr_Tmr2
  pop:
    movf    PCLATH_T, W
    movwf   PCLATH
    swapf   STATUS_T, W
    movwf   STATUS
    swapf   W_T, F
    swapf   W_T, W
    retfie
;---------SubrutinasInterrupci�n-----------
Interr_Tmr0:
    reiniciar_Tmr0	;2 ms
    
    Bcf	    STATUS, 0
    clrf    PORTD 
    btfsc   banderas, 0	    ;Revisar bit 1 de banderas
    goto    displayunidad   ;Llamar a subrutina de displayunidad	    ;
    btfsc   banderas, 1	    ;Revisar bit 2 de banderas
    goto    displaydecena   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 2	    ;Revisar bit 2 de banderas
    goto    displayunidad_SE1   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 3	    ;Revisar bit 2 de banderas
    goto    displaydecen_SE1   ;Llamar a subrutina de displaydecena
    
    btfsc   banderas, 4	    ;Revisar bit 2 de banderas
    goto    displayunidad_SE3   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 5	    ;Revisar bit 2 de banderas
    goto    displaydecen_SE3   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 6	    ;Revisar bit 2 de banderas
    goto    displayunidad_SE4   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 7	    ;Revisar bit 2 de banderas
    goto    displaydecen_SE4   ;Llamar a subrutina de displaydecena
    movlw   00000001B
    movwf   banderas


siguientedisplay:
    movlw   4			;titilro sem3
    subwf   semaforo3, 0	;Guarda en w
    btfss   STATUS, 0
    GOTO    amarillo_semaforo3
    movlw   7
    subwf   semaforo3, 0
    btfss   STATUS, 0
    GOTO    RUTINA_TITILEO3
    
    call    titileo2
    
    movlw   4			;titileo Sem1
    subwf   semaforo1, 0	;Guarda en w
    btfss   STATUS, 0
    goto    amarillo_semaforo1
    movlw   7
    subwf   semaforo1,0
    btfss   STATUS, 0
    goto    RUTINA_TITILEO1
    
    return
    
titileo2:
    movlw   4
    subwf   semaforo2, 0	;Guarda en w
    btfss   STATUS, 0
    GOTO    amarillo_semaforo2
    movlw   7
    subwf   semaforo2,0
    btfss   STATUS, 0
    GOTO    RUTINA_TITILEO2
    return
    
RUTINA_TITILEO1:
    btfss   valor_titileo,0
    goto    DISP_OFF 
    bsf     PORTA,0
    return
    
RUTINA_TITILEO2:
    btfss   valor_titileo,0
    goto    DISP_OFF 
    bsf     PORTA,3
    return
RUTINA_TITILEO3:
    btfss   valor_titileo,0
    goto    DISP_OFF 
    bsf     PORTA, 6
    bcf	    PORTA, 3
    return
    
DISP_OFF:
    bcf     PORTA, 0
    bcf	    PORTA, 3
    bcf	    PORTA, 6 
    RETURN

amarillo_semaforo1:
    bcf	    PORTA, 0
    bsf	    PORTA, 1
    bcf	    PORTA, 2
    return    
amarillo_semaforo2:
    bcf	    PORTA, 3
    bsf	    PORTA, 4
    bcf	    PORTA, 5
    return    
amarillo_semaforo3:
    bcf	    PORTA, 3
    bcf	    PORTA, 6
    bsf	    PORTA, 7
    bcf	    PORTB, 7
    return    
    
displayunidad_SE1:
    movlw   00001000B
    movwf   banderas
    movf    unidad22, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 7	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay
displaydecen_SE1:
    movlw   00010000B
    movwf   banderas
    movf    decena22, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 6	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay
displaydecena:
    movlw   00000100B
    movwf   banderas
    movf    decena1, w	    //Mover el valor de decena1(Tabla) a w
    movwf   PORTC	    //Mover el valor de w a PORTD
    bsf	    PORTD, 0	    //Encender bit 5 PORTB para transistor
    goto    siguientedisplay	//Siguiente display
displayunidad:
    movlw   00000010B
    movwf   banderas  
    movf    unidad1, w	    //Mover el valor de Unidad1(Tabla) a w
    movwf   PORTC	    //mover el valor de w a PORTD
    bsf	    PORTD, 1	    //Encender bit 5 de PORTB para transistor
    goto    siguientedisplay	//Siguiente display
    
displayunidad_SE3:
    movlw   00100000B
    movwf   banderas
    movf    unidad33, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 3	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay
displaydecen_SE3:
    movlw   01000000B
    movwf   banderas
    movf    decena33, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 2	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay    
    
displayunidad_SE4:
    movlw   10000000B
    movwf   banderas
    movf    unidad44, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 5	//Encender bit4 de PORTB para transistor 
    
    goto    siguientedisplay
displaydecen_SE4:
    movlw   00000001B
    movwf   banderas
    movf    decena44, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 4	    //Encender bit4 de PORTB para transistor 
    movlw   0x00
    movwf   banderas	    ;Mover literal a banderas
    goto    siguientedisplay    
        

int_ioCB: 
    movf    estado, W
    clrf    PCLATH		
    andlw   0x07
    addwf   PCL
    goto    interrup_estado_0
    goto    interrup_estado_1
    goto    interrup_estado_2
    goto    interrup_estado_3; 0
    goto    interrup_estado_4
    goto    finalIOC
    goto    finalIOC
 interrup_estado_0:
    banksel PORTB
    BCF     PORTA,1
    BSF     PORTA,0
    btfsc   PORTB, MODO
    goto    finalIOC
    incf    estado
    movf    T0_Actual, W
    movwf   Tmr0_temporal
    goto    finalIOC
 
 interrup_estado_1:
    btfss   PORTB, INC
    incf    Tmr0_temporal, 1   ;se guarda en mismo registro 
    movlw   21
    subwf   Tmr0_temporal, 0
    btfsc   STATUS, 2
    goto    valor_minSemaforo1
    
    btfss   PORTB, DECRE
    decf    Tmr0_temporal, 1
    movlw   9
    subwf   Tmr0_temporal, 0
    btfsc   STATUS, 2
    goto    valor_maxSemaforo1
    
    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC
 interrup_estado_2:

    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC
 interrup_estado_3:
    
    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC
 interrup_estado_4:
    
    btfss   PORTB, DECRE
    clrf    estado
    btfsc   PORTB, INC
    goto    finalIOC
    
    movf    Tmr0_temporal, W
    movwf   T0_Actual
    movf    T0_Actual, W
    movwf   semaforo1
    clrf    estado
 finalIOC:
    bcf	    RBIF
    return
config_SE1:
    return
config_SE2:
    btfss   PORTB, INC
    incf    SE2_temporal, 1   ;se guarda en mismo registro 
    movlw   21
    subwf   SE2_temporal, 0
    btfsc   STATUS, 2
    goto    valor_minSemaforo2
    
    btfss   PORTB, DECRE
    decf    SE2_temporal, 1
    movlw   9
    subwf   SE2_temporal, 0
    btfsc   STATUS, 2
    goto    valor_maxSemaforo2
    return
config_SE3:
    return
valor_minSemaforo1:
    movlw   10
    movwf   Tmr0_temporal
    bcf	    RBIF
    return
valor_maxSemaforo1:
    movlw   20
    movwf   Tmr0_temporal
    bcf	    RBIF
    return
valor_minSemaforo2:
    movlw   10
    movwf   SE2_temporal
    bcf	    RBIF
    return
valor_maxSemaforo2:
    movlw   20
    movwf   SE2_temporal
    bcf	    RBIF
    return
valor_minSemaforo3:
    movlw   10
    movwf   SE3_temporal
    bcf	    RBIF
    return
valor_maxSemaforo3:
    movlw   20
    movwf   SE3_temporal
    bcf	    RBIF
    return
Interr_Tmr2:
    BCF    TMR2IF
    INCF   valor_titileo
    return
    
  PSECT code, delta=2, abs
  ORG 100h	;Posici�n para el c�digo
 ;------------------ TABLA -----------------------
  Tabla:
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
  ;---------------configuraci�n------------------------------
  main: 
 ;--------Configuracion para las entradas y salidas-----------
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    clrf    TRISA	;PORTA A salida
    clrf    TRISC
    clrf    TRISD
    clrf    TRISE
    bsf	    TRISB, MODO
    bsf	    TRISB, INC
    bsf	    TRISB, DECRE
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, MODO
    bsf	    WPUB, INC
    bsf	    WPUB, DECRE
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTA	;Valor incial 0 en puerto A
    clrf    PORTC
    clrf    PORTB
    clrf    PORTD
 ;-----------------------------------------------------------------------------
    call    config_reloj
    call    config_IOChange
    call    config_tmr0
    call    config_tmr1
    call    config_tmr2
    call    config_InterrupEnable
;------------Ciclo Principal de los semaforos-------------------------------
    banksel PORTA 
    movlw   0x0F
    movwf   T0_Actual
    movf    T0_Actual, W
    movwf   semaforo1
    bsf	    PORTA, 0
    bcf	    PORTA, 1
    bsf	    PORTA, 5
    bsf	    PORTB, 7
    movlw   0x0A
    movwf   SE2_Actual
    movf    SE2_Actual, W
    movwf   semaforo2
    movlw   0x0A
    movwf   SE3_Actual
    movf    SE3_Actual, W
    movwf   semaforo3
    clrf    estado

;----------loop principal---------------------
 loop:
    btfss   TMR1IF	    ;Funcionamiento semaforo1
    goto    $-1
    reiniciar_Tmr1
    CALL INICIO_SEMAFORO1
    
    movf    semaforo1, w    ;Displays semaforo1
    
    movwf   V1
    call    Centenas	
    call    displaydecimal
    
    movf    semaforo2, w    ;Displays semaforo2    
    movwf   V3
    call    Centenas_S2	
    call    displaydecimal_S2
    
    movf    semaforo3, w    ;Displays semaforo1    
    movwf   V4
    call    Centenas_S3	
    call    displaydecimal_S3
       
    bcf	    GIE
    movf    estado, W
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0x07
    addwf   PCL
    goto    estado_0
    goto    estado_1
    goto    estado_2
    goto    estado_3
    goto    estado_4
    goto    loop
    goto    loop
 estado_0:
    bsf	    GIE
    clrf    valor_actual    
    movlw   000B
    movwf   PORTE   
    goto    loop    ;loop forever
 estado_1:
    bsf	    GIE
    movf    Tmr0_temporal, w
    movwf   V2
    call    Centenas_S1	//Subrutina de divisi�n para contador DECIMAL 
    call    displaydecimal_S1
    movlw   001B
    movwf   PORTE
    goto    loop
 estado_2:
    bsf	    GIE
    movlw   010B
    movwf   PORTE
    goto    loop
 estado_3:
    bsf	    GIE
    movlw   011B
    movwf   PORTE
    goto    loop
 estado_4:
    bsf	    GIE
    movlw   100B
    movwf   PORTE
    goto    loop
;------------sub rutinas---------------------
INICIO_Semaforo1:
    movlw   0x00
    subwf   semaforo1
    btfsc   STATUS, 2
    goto    INICIO_SEMAFORO2
    decf    semaforo1
    return 
INICIO_Semaforo2:
    bsf     PORTA,3
    clrf    semaforo1   
    movlw   0x00
    subwf   semaforo2
    btfsc   STATUS, 2
    goto    INICIO_SEMAFORO3
    decf    semaforo2
    return 
    
INICIO_Semaforo3:
    bsf     PORTA,6
    clrf    semaforo2
    movlw   0x00
    subwf   semaforo3 
    btfsc   STATUS, 2
    goto    asignarvalor
    decf    semaforo3
    return 
    
asignarvalor:
    bsf	    PORTA, 0
    bcf	    PORTA, 1
    bcf	    PORTA, 2
    bcf	    PORTA, 3
    bcf	    PORTA, 4
    bsf	    PORTA, 5
    bcf	    PORTA, 6
    bcf	    PORTA, 7
    bsf	    PORTB, 7
    movf    T0_Actual, W
    movwf   semaforo1
    movf    SE2_Actual, W
    movwf   semaforo2
    movf    SE3_Actual, W
    movwf   semaforo3
    bcf	    PORTA, 1
    return
;------------------Divisi�nRutinaPrincipal-------------------
;--------------Rutina para DisplayDecimal para Configuracion--------------------  
displaydecimal:
    movf    centena, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena1	//Lo guardamos en variable centena1
    movf    decena, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena1	//Lo guardamos en variable decena1
    movf    unidad, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad1	//Lo guardamos en variable unidad1
    return
Centenas:
    clrf    centena	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V1, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    Decenas	 //llama a subrutina para resta en decena
    incf    centena, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 l�neas atras y resta nuevamente 
Decenas:
    clrf    decena	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V1		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V1,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    Unidades	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
Unidades:
    clrf    unidad	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V1		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V1,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
;------------------Rutina para DisplayDecimal para Semaforo1--------------------  
displaydecimal_S1:
    movf    centena2, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena22	//Lo guardamos en variable centena1
    movf    decena2, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena22	//Lo guardamos en variable decena1
    movf    unidad2, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad22	//Lo guardamos en variable unidad1
    return
Centenas_S1:
    clrf    centena2	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V2, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    Decenas_S1	 //llama a subrutina para resta en decena
    incf    centena2, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 l�neas atras y resta nuevamente 
Decenas_S1:
    clrf    decena2	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V2		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V2,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    Unidades_S1	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena2, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
Unidades_S1:
    clrf    unidad2	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V2		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V2,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad2, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
;------------------Rutina para DisplayDecimal para Semaforo2--------------------   
displaydecimal_S2:
    movf    centena3, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena33	//Lo guardamos en variable centena1
    movf    decena3, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena33	//Lo guardamos en variable decena1
    movf    unidad3, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad33	//Lo guardamos en variable unidad1
    return
Centenas_S2:
    clrf    centena3	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V3, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    Decenas_S2	 //llama a subrutina para resta en decena
    incf    centena3, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 l�neas atras y resta nuevamente 
Decenas_S2:
    clrf    decena3	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V3		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V3,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    Unidades_S2	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena3, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
Unidades_S2:
    clrf    unidad3	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V3		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V3,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad3, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad    
;------------------Rutina para DisplayDecimal para Semaforo3-------------------- 
displaydecimal_S3:
    movf    centena4, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena44	//Lo guardamos en variable centena1
    movf    decena4, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena44	//Lo guardamos en variable decena1
    movf    unidad4, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad44	//Lo guardamos en variable unidad1
    return
Centenas_S3:
    clrf    centena4	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V4, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    Decenas_S3	 //llama a subrutina para resta en decena
    incf    centena4, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 l�neas atras y resta nuevamente 
Decenas_S3:
    clrf    decena4	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V4		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V4,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    Unidades_S3	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena4, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
Unidades_S3:
    clrf    unidad4	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V4		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V4,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad4, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad    
;-------------------------------------------------------------------------------    
config_IOChange:
    banksel TRISA
    bsf	    IOCB, MODO
    bsf	    IOCB, INC
    bsf	    IOCB, DECRE
    
    banksel PORTA
    movf    PORTB, W	;Condici�n mismatch
    return

    
 config_tmr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0	    ;PS = 111 Tiempo en ejecutar , 256
    
    reiniciar_Tmr0  ;Macro reiniciar tmr0
    return
    
 config_tmr1:
    banksel T1CON
    bcf	    TMR1GE	;tmr1 como contador
    bcf	    TMR1CS	;Seleccionar reloj interno (FOSC/4)
    bsf	    TMR1ON	;Encender Tmr1
    bcf	    T1OSCEN	;Oscilador LP apagado
    bsf	    T1CKPS1	;Preescaler 10 = 1:4
    bcf	    T1CKPS0 
    
    reiniciar_Tmr1
    return
 

 config_tmr2:
    banksel T2CON
    bsf	    T2CON, 7 
    bsf	    TMR2ON
    bsf	    TOUTPS3	;Postscaler 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    bsf	    T2CKPS1	;Preescaler 1:16
    bsf	    T2CKPS0
    
    reiniciar_tmr2
    return
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuraci�n bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracu�n bit1 IRCF
    bcf	    IRCF0	;OSCCON configuraci�n bit0 IRCF
    bsf	    SCS		;reloj interno , 1Mhz
    return
    

config_InterrupEnable:
    BANKSEL PIE1
    bsf	    T0IE	;Habilitar bit de interrupci�n tmr0
    BSF     TMR2IE
    BANKSEL T1CON 
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    BCF     TMR2IF
    return
 
end