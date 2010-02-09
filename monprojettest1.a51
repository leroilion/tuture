;*****************************************************************
;* 								Racine Carrée								  *
;* Auteur : Jérémy                                               *
;* Date : 03/02/2010                                             *
;* Version : V1.2                                                *
;* Commentaire : Programme qui affiche le nombre entré           *
;* sur le port P0 et l'affiche sur 3 digit d'un afficheur 7      *
;* segment. Lorsuq'on appuie sur P2.7, on calcul la partie       *
;* entière de la racine carrée que l'on affiche sur un afficheur *
;* 7 segments.                                                   *
;* Un afficheur affiche "b" si le carré est parfait, d sinon	  *	
;*****************************************************************

;*****************************************************************
;* On créer ici les alias pour les différents port               *
;*****************************************************************

Bouton_poussoir	equ p3.7


;*****************************************************************
;* On se place au debut pour envoyer le programme là ou se       *
;* le programme, et on charge la banque 0 en appelant un         *
;* sous programme                                                *
;* On active aussi l'interruption INT0 sur front descendant      *
;***************************************************************** 

						org 0000h
						ljmp debut2
						
						org 0030h
debut2:				acall selec_bank_0
						setb ex0
						setb ea
						setb it0
					

						
;*****************************************************************
;* Boucle principal, main :                                      *
;* On fait que lire le port P0 et afficher le nombre sélectionné *
;* Si on appuie sur P2.7 (bouton poussoir), alors on extrait     *
;* la partie entière de la racine carrée du nombre et on         *
;* l'affiche                                                     *
;*****************************************************************

debut:				mov R0,P1
						acall conv_bin_dcb
						jmp debut

;*****************************************************************
;* Conversion Binaire ==> BCD                                    *
;* On fait la conversion du nombre binaire et code BCD sur 3     *
;* bits.                                                         *
;* On utilise des divisions successives par 10 pour avoir le     *
;* code BCD ou DCB.                                              *
;* De plus, ce programme affiche directement le résultat         *
;*****************************************************************

conv_bin_dcb:		mov A,R0                ;On stocke dans l'accu le nombre à convertir.
						mov B,#10					;On stocke 10 dans l'accu b
						div ab						;On divise le nombre par 10
						mov r3,a
						mov a,b
						swap a
						jb 00h,oui
						orl a,#0dh
						jmp suite
oui:					orl a,#07h
suite:				mov P3,a	
						mov a,R3					
						mov b,#10
						div ab
						swap a
						orl a,b
						mov P2,a
						ret
						
			
;*****************************************************************
;* Selection de la banque 0                                      *
;* Programme qui sert à la sélection de la banque 0.             *
;* En pratique ce programme est inutile puisque on utilise que   *
;* la banque 0. On appel donc le programme une seule fois.		  *
;*****************************************************************			
						
selec_bank_0:		mov A,11100111b			;On prépare le masque pour le PSW (choisir la bonne banque).
						anl A,PSW					;On fait le calcul
						mov PSW,A					;On met la variable dans le registre d'etat.
						ret
						
;*****************************************************************
;* Racine Carrée                                                 *
;* Voici le coeur du programme, la fonction que l'on voulait     *
;* avoir.                                                        *
;* L'algorithme utilisé utilise une propriété des carrés         *
;* parfaits. Tout les carrés parfaits sont sommes d'une suite de *
;* nombre impair. Donc on soustrait lsuite des premiers nombre   *
;* impair jusqu'à avoir 0 ou un nombre négatif pour arréter      *
;* l'algo. Il suffit alors de compter le nombre d'itération      *
;* pour avoir la partie entière de la racine carrée.             *
;*****************************************************************
						
calcul_racine:		mov a,R0						;On met le N dans l'accu a pour faire le calcul
						mov b,#01h					;On charge la valeur initiale
						mov R1,#0h					;On met le compteur à 0
						
boucle:				clr c							;Clear le carry
						subb a,b						;debut de l'algo
						inc b
						inc b
						inc R1
						jz carree_parfait
						jnc boucle
						dec R1
						clr 00h
						ret
carree_parfait:	setb 00h
						ret

;****************************************************************
;* Afficher n                                                   *
;* Ce programme ce contente d'afficher le résultat de la racine.*
;* En effet, celle-ci est calculé puis stocké dans R1 de la     *
;* banque 0. Ici, on va récupérer le résultat, et le            *
;* convertir en DCB ou BCD et l'afficher sur 2 digits d'un      *
;* afficheur 7 segments.                                        *
;****************************************************************
					
affich_n:			mov a,R1
						mov B,#10
						div ab
						swap a
						orl a,b
						mov P0,a
						ret
						
;*****************************************************************
;* Gestion de l'interruption                                     *
;* Appel du bon sous programme                                   *
;*****************************************************************

						org 0003h
						acall calcul_racine
						acall affich_n
						reti
						
						end	


