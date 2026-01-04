#INCLUDE 'TBICONN.CH'
#INCLUDE "PROTHEUS.CH"
/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³acoita	   ³ Autor ³ Cesar Ramalho         ³ Data ³18-09-2009³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ FUNCAO QUE VEFICA A FUNCAO EXISTENTE E EXECULTA SE TRUE    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Analista Resp.³  Data  ³ Bops ³ Manutencao Efetuada                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³              ³  /  /  ³      ³-acoita2 executa com prepare envieroment³±±
±±³              ³  /  /  ³      ³-agora cria um parametro para auxiliar  ³±±
±±³              ³        ³      ³   a digitacao recorrente               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function acoita()
	// Variaveis Locais da Funcao
	Local oGet1
	local cFuncao	 	:= Space(100)
	local cParametro	:= 'MV_ACOITA'

	dbSelectArea("SX6")
	dbSetOrder(1)
	dbgoTop()      
	If !Dbseek('  '+cParametro)
		Reclock("SX6",.T.)
		Replace X6_VAR 		with cParametro
		Replace X6_TIPO 	with 'C'
		Replace X6_DESCRIC 	with 'Auxilio para função u_acoita()'
		Replace X6_DSCSPA 	with 'Auxilio para função u_acoita()'
		Replace X6_DSCENG 	with 'Auxilio para função u_acoita()'
		Replace X6_CONTEUD	with ''
		Replace X6_CONTSPA 	with ''
		Replace X6_CONTENG 	with ''
		Replace X6_PROPRI 	with 'S'
		Replace X6_PYME	 	with 'S'	
		Msunlock() 
	Else
		cFuncao:= SX6->X6_CONTEUD
	Endif  

	// Variaveis Private da Funcao
	Private Execute				// Dialog Principal
	// Variaveis que definem a Acao do Formulario
	Private VISUAL := .F.                        
	Private INCLUI := .F.                        
	Private ALTERA := .F.                        
	Private DELETA := .F.                        

	DEFINE MSDIALOG Execute TITLE "AÇOITA" FROM C(178),C(181) TO C(250),C(340) PIXEL

	// Cria Componentes Padroes do Sistema
	@ C(007),C(006) Say "Função" Size C(018),C(008) COLOR CLR_BLACK PIXEL OF Execute
	@ C(015),C(006) MsGet oGet1 Var cFuncao VALID u_AcoitaA(alltrim(cFuncao)) Size C(060),C(012) COLOR CLR_BLUE Picture "@!" PIXEL OF Execute
	@ C(015),C(067) Button "GO" Size C(010),C(013) PIXEL OF Execute action u_AcoitaA(alltrim(cFuncao))

	// Cria ExecBlocks dos Componentes Padroes do Sistema

	ACTIVATE MSDIALOG Execute CENTERED 

Return(.T.)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa   ³ acoitaA ³ Autores ³ Cesar ramalho			  ³ Data ³10/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao  ³ 															                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/                                                                                                

User function AcoitaA(cFuncao)  
	local cRet                

	dbSelectArea("SX6")
	dbSetOrder(1)
	dbgoTop()      
	If Dbseek('  MV_ACOITA')
		Reclock("SX6",.f.)
		Replace X6_CONTEUD	with cFuncao
		Msunlock()
	EndIf

	if Existblock(cFuncao) .and. at("(",cFuncao)==0
		ExecBlock( cFuncao, .F.,.F.)
	else
		If ApMsgYesNo("Função não existe!<br>Deseja realmente executar?")
			cFuncao := "U_"+cFuncao
			cRet := &cFuncao
		EndIf
	EndIf

return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
+±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
+±±³Programa   ³   C()   ³ Autores ³ Norbert/Ernani/Mansano ³ Data ³10/05/2005³±±
+±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
+±±³Descricao  ³ Funcao responsavel por manter o Layout independente da       ³±±
+±±³           ³ resolucao horizontal do Monitor do Usuario.                  ³±±
+±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
+±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
+ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function C(nTam)                                                         

Return Int(nTam)               
//______________________________________________________________________________       

User Function acoita2()
	PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' TABLES ''
	u_acoita()	
Return
