;************************************************************************
;* Asservissement de la voiture en direction                            *
;* Version : v0.0                                                       *
;* Le 17/02/2010                                                        *
;* Cette partie g�re l'interruption du timer0 pour l'asservissement     *
;* du servomoteur et du moteur														*
;************************************************************************



;************************************************************************
;* Definition des ports et des bit													*
;* Entr�e : capteur droit et capteur gauche, B.P. droite et gauche		*
;* Sortie : moteur, servo de direction, led d'indication                *
;************************************************************************

moteur						bit	p1.5
direction					bit	p1.4
led							bit	p1.0
bpdroit						bit	p1.1
bpgauche						bit	p1.2
capteur_droit				bit	p3.3														;Sur interruption INT0
capteur_gauche				bit	p3.2              									;Sur interruption INT1
esclave						bit	p1.6

;************************************************************************
;* Definition des variables (octet et bit)										*
;* Bit : mutex																				*
;* Byte : direction (low, high, reste, normal) et idem pour le moteur	*
;************************************************************************

mutex							bit	7fh														;Permet de locker le changement de valeur dans le timer pour ne pas perturber un cycle
dir_low						equ	7fh														;Variable contenant la valeur � charger dans le timer pour la direction
dir_high						equ	7eh
dir_rest_low				equ	7dh
dir_rest_high				equ	7ch
mot_low						equ	7bh
mot_high						equ	7ah
mot_rest_low				equ	79h
mot_rest_high				equ	78h
var_etat						equ	77h
tempo							equ	76h
le_truc_qu_on_decremente_pour_attendre_plus_longtemps_qu_un_tour_de_timer		equ	75h
var_etat_2					equ	75h
vit							equ	74h
vit2							equ	73h

pause_faite					bit	7eh
prec_g						bit   7dh
prec_m						bit	7ch

tim_low						equ	6eh														;Variable interm�diaire pour le timer	
tim_high						equ	6fh

;Le registre R0 servira � connaitre la phase du timer 0
;Les registres R7,R6 et R5,R4serviront de variation par rapport � la valeur par d�faut sur les moteurs et la direction (R7,R6 pour mot et R5,R4 pour dir)
;Les registres R3 et R2 serviront pour stocker le PWM sur 8 bit

;************************************************************************
;* Defintion des valeurs (#define)													*
;* Valeur de timer de r�f�rence														*
;************************************************************************

dir_ref_low					equ	0fah
dir_ref_high				equ	24h
dir_ref_rest_low			equ	0fch
dir_ref_rest_high			equ	18h
mot_ref_low					equ	0fah
mot_ref_high				equ	24h
mot_ref_rest_low			equ	0c1h
mot_ref_rest_high			equ	80h
temp							equ	3fh
lim_bas						equ	10
lim_haut						equ	245
temp_mot						equ	20
t50ms_h						equ   3Ch
t50ms_l						equ   0AFh
;vitesse						equ	175
;vitesse2						equ	175

;************************************************************************
;* Debut du programme : ou �crire													*
;************************************************************************

								org 	0000h
								ljmp	init
								
								org	0003h														;int 0
								
								org	000bh             									;timer 0
								ljmp	int_timer_0
								
								org	0013h														;int 1
								
								org	001bh														;timer 1
								
								org	0023h														;liaison serie
								
								org	0030h														;C'est ici que l'on va �crire le coeur du programme
								
;************************************************************************
;* Initialisation																			*
;*	Phase d'initialisation des timers (0 pour l'instant)						*
;* Changement de position de la pile												*
;************************************************************************

init:							mov	sp,#30h													;On change le StackPointer de place pour ne pas mettre la pile dans la zone de banque
								clr	direction
								clr	moteur
								clr	mutex
								mov	tmod,#00010001b
								lcall	init_bits_choix_etat
								
								mov	vit,#170
								mov	vit2,#175
								
								
;Activation des interruptions :								
								setb	et0														;activation du timer 0
								setb	ea															;activation de l'ensemble des interruptions
								clr	pt0														;Placer l'interruption timer 0 en priorit�
								
;Mise en place des valeurs par d�faut :
								mov	dir_low,#dir_ref_low								
								mov	dir_high,#dir_ref_high
								mov	dir_rest_low,#dir_ref_rest_low
								mov	dir_rest_high,#dir_ref_rest_high
								mov	mot_low,#mot_ref_low
								mov	mot_high,#mot_ref_high
								mov	mot_rest_low,#mot_ref_rest_low
								mov	mot_rest_high,#mot_ref_rest_high
								mov r2,#128
								mov r3,#160
								
;Mise en place de la phase 1 pour le cycle asservissement :
								mov	r0,#0

;Lancement du timer 0 :
								mov 	th0,#0ffh												;On le lance proche de la fin pour que le cycle asservissement commence
								mov 	tl0,#0f0h                                    ;le plus rapidement possible
								setb 	tr0
								
;Saut au debut du main :								
								ljmp	main
								
;************************************************************************
;* Main : boucle principal																*
;************************************************************************

main:							
								lcall	choix_etat
								lcall	choix_etat_2
								lcall reglage_btn
								lcall	agir
								lcall conv_pourcent_nb
								lcall chargement
								sjmp main

;************************************************************************
;* Interruption timer 0 pour le cycle asservissement							*
;* Check de r0 pour connaitre la phase dans laquelle nous sommes			*
;* Rechargement du timer 0																*
;*	Prise du mutex de la phase 0 � 3 (une fois la derni�re phase lanc�e,	*
;* On lib�re le mutex																	*
;************************************************************************

int_timer_0:				push	psw														;Sauvegarde du psw et de l'accumulateur
								push	acc
								
;Prise du mutex
								setb	mutex
								
asserv0:						cjne	r0,#0,asserv1											;Si ce n'est pas la phase 0, on va tester la phase 1
								mov	tim_low,dir_low
								mov	tim_high,dir_high
								mov 	r0,#1;
								setb	direction
								sjmp	relancer
								
asserv1:						cjne	r0,#1,asserv2
								mov	tim_low,dir_rest_low
								mov	tim_high,dir_rest_high
								mov 	r0,#2
								clr	direction
								sjmp	relancer		
								
asserv2:						cjne	r0,#2,asserv3
								mov	tim_low,mot_low
								mov	tim_high,mot_high
								mov 	r0,#3
								setb	moteur
								sjmp	relancer		
								
asserv3:						mov	tim_low,mot_rest_low
								mov	tim_high,mot_rest_high
								mov 	r0,#0
								clr	moteur
								clr	mutex
suite:						sjmp	relancer	 
								
;Relancer le timer :
relancer:					clr	tr0
								mov	a,tl0
								add	a,#08
								addc	a,tim_low
								mov	tl0,a
								mov	a,tim_high
								addc	a,th0
								mov	th0,a
								setb	tr0
								
;Remise dans la pile de psw et psw
								pop	acc
								pop	psw
								
								reti	
								
								
;***************************************************************
;* Conversin pourcentage tic												*
;* Le but est de passer de la valeur en pourcentage de l'�tat  *
;* du moteur et direction en nombre � ajouter ou soustraire		*
;* On va utiliser des entiers sign� (128 �tant le z�ro)			*
;***************************************************************

conv_pourcent_nb:			mov	a,R2
								mov	b,#4
								mul	ab
								mov	r4,a
								mov	r5,b
								mov	a,r3
								mov	b,#2
								mul	ab
								mov	r6,a
								mov	r7,b
								
								ret
								
;*********************************************************************
;* Chargement de la nouvelle valeur pour la direction et le moteur   *	
;* si le mutex est libre.															*
;*********************************************************************

chargement:					jb		mutex,chargement_fin
;On commence par la direction, normal
								clr 	c
								mov	a,#0dch
								add	a,r4
								mov	6dh,a
								mov	a,#03h
								addc	a,r5
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	dir_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	dir_high,a
								
;Ensuite, le compl�ment de la direction 
								clr 	c
								mov	a,#0e8h
								subb	a,r4
								mov	6dh,a
								mov	a,#05h
								subb	a,r5
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	dir_rest_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	dir_rest_high,a
								
;Puis on s'occupe du moteur
								clr 	c
								mov	a,#0dch
								add	a,r6
								mov	6dh,a
								mov	a,#04h
								addc	a,r7
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	mot_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	mot_high,a
								
;Ensuite, le compl�ment de la direction
								clr 	c
								mov	a,#080h
								subb	a,r6
								mov	6dh,a
								mov	a,#40h
								subb	a,r7
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	mot_rest_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	mot_rest_high,a

chargement_fin:			ret

;*************************************************************************************
;* Fonction permettant de changer la direction et la vitesse en fonction             *
;* de notre variable d'�tat                                                          *
;*************************************************************************************
agir:							mov	a,var_etat_2
								cjne	a,#0,etat1
etat0_1:						mov	R2,#128
								mov	R3,vit2													;Activation du moteur
								ret
								
; Si la variable d'�tat vaut 1, on fait:
; if( var_etat == 1 )
; {
;		R3 = 150;									//Activation du moteur
;		if( !(R2 < 128))							//Si R2 ne correspond pas � la variable d'�tat (genre aller � droite alors qu'i lfaut aller � gauche)
;		{
;			R2 = 128;
;			tempo = 0;
;		}
;		else
;		{
;			if( tempo != temp )					//Si la temporisation n'a pas eu lieu
;			{
;				if( R2 != lim_bas )				//Si R2 n'a pas atteint la valeur limite
;				{
;					tempo = 0;						//alors on reset le tempo et on incr�mente la direction
;					R2--;
;				}
;			}
;		}
;		tempo++;
;	}
etat1:						cjne	a,#1,etat2
etat1_0_1:					mov	R3,vit													;Activation du moteur
								clr 	c															;On verifie si le registre R2 est bien dans la bonne section
								mov	a,R2
								subb	a,#129
								;jc		etat1_1
								sjmp		etat1_1
								mov	R2,#128													;On charge la valeur du milieu
								mov	tempo,#0
etat1_1:						mov	a,tempo
								cjne	a,#temp,etat1_2									;Verification de la temporisation pour ne pas braquer trop vite
								cjne	R2,#lim_bas,etat1_1_1							;Si on est en but� basse, on arrete tout
								sjmp	etat1_2
etat1_1_1:					mov	tempo,#0
								dec	R2
								ret
etat1_2:						inc	tempo
								ret
								
										
etat2:						cjne	a,#2,etat3
								sjmp	etat1_0_1
								
etat3:						cjne	a,#3,etat4
etat3_0_1:					mov	R3,vit
								clr 	c															;On verifie si le registre R2 est bien dans la bonne section
								mov	a,R2
								subb	a,#127
								;jnc	etat3_1
								sjmp	etat3_1
								mov	R2,#128													;On charge la valeur du milieu
								mov	tempo,#0
etat3_1:						mov	a,tempo
								cjne	a,#temp,etat3_2										;Verification de la temporisation pour ne pas braquer trop vite
								cjne	R2,#lim_haut,etat3_1_1								;Si on est en but� basse, on arrete tout
								sjmp	etat3_2
etat3_1_1:					mov	tempo,#0
								inc	R2
etat3_2:						inc	tempo
								ret	
								
etat4:						cjne	a,#4,etat5
								sjmp	etat3_0_1

										 
etat5:						cjne	a,#5,etat6
								mov R3,#0
								ret		
								
etat6:						ljmp	etat0_1
		
;******************************************************************************
; Fonction de TomK                                                            *
;******************************************************************************

choix_etat:					mov	A,P3
								anl	A,#1100b ; on garde uniquement les pins des capteurs
								
t_nn:							cjne	A,#1100b,t_nb
								mov	var_etat,#0
								ljmp	t_fin

t_nb:							cjne	A,#0100b,t_bn
								mov	var_etat,#1
								ljmp	t_fin

t_bn:							cjne	A,#1000b,t_bb
								mov	var_etat,#3
								ljmp	t_fin
								
t_bb:							;dernier cas, pas besoin de cjne
								mov	A,var_etat
								cjne	A,#0,t_bbd
								mov	var_etat,#5
								lcall	init_bits_choix_etat
								setb	prec_m
								ljmp	t_timer_start_pause

t_bbd:						cjne	A,#1,t_bbg
								mov	var_etat,#2
								lcall	init_bits_choix_etat
								clr	prec_g
								ljmp	t_timer_start_attente

t_bbg:						cjne	A,#3,t_prec
								mov	var_etat,#4
								lcall	init_bits_choix_etat
								setb	prec_g
								ljmp	t_timer_start_attente
									
t_prec:						cjne	A,#5,t_bbmb
								jnb	tf1,t_fin
								lcall	t_regler_50ms
								djnz	le_truc_qu_on_decremente_pour_attendre_plus_longtemps_qu_un_tour_de_timer,	t_fin
								setb	pause_faite
								clr	tr1
								jnb	prec_m,t_pg
								mov	var_etat,#6
								ljmp	t_fin

t_pg:							jnb	prec_g,t_pd
								mov	var_etat,#4
								ljmp	t_fin

t_pd:							;
								mov	var_etat,#2
								ljmp	t_fin

t_bbmb:						;dernier cas aussi
								jb		pause_faite,t_fin
								jnb	tf1,t_fin
								lcall	t_regler_50ms
								djnz	le_truc_qu_on_decremente_pour_attendre_plus_longtemps_qu_un_tour_de_timer,	t_fin
								mov 	var_etat,#5
								ljmp	t_timer_start_pause
                                       
t_timer_start_attente:	lcall	t_regler_50ms
								mov	le_truc_qu_on_decremente_pour_attendre_plus_longtemps_qu_un_tour_de_timer, #10
								ljmp	t_fin

t_timer_start_pause:		lcall	t_regler_50ms
								mov	le_truc_qu_on_decremente_pour_attendre_plus_longtemps_qu_un_tour_de_timer, #40
								ljmp	t_fin
								
t_fin:						ret
								
t_regler_50ms:				mov	th1,#t50ms_h
								mov	tl1,#t50ms_l
								clr	tf1
								setb	tr1
								ret
								
init_bits_choix_etat:	clr	prec_g
								clr	prec_m
								clr	pause_faite
								ret	
								
								
								
choix_etat_2:				jb		esclave,choix_etat_2_1
								mov	var_etat_2,#5
								ret
choix_etat_2_1:			mov	var_etat_2,var_etat
								ret

reglage_btn:				jb 	bpdroit,rb_2
								jnb	bpdroit, $
								dec 	vit
								mov   a, vit
								add	a,#5
								mov	vit2, a
								
rb_2:							jb 	bpgauche,rb_fin
								jnb	bpgauche, $
								inc 	vit
								mov   a, vit
								add	a,#5
								mov	vit2, a	
								
rb_fin:						ret
					
								end
