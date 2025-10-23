#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'MATA520.CH'


user FUNCTION Mata520(aRotAuto)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define Variaveis                                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	LOCAL   cMarca
	LOCAL nIndice
	LOCAL cFilSF2   := ""
	LOCAL aIndexSF2 := {}
	Local lTop      := .F.
	Local aRegSd2   := {}
	Local aRegSe1   := {}
	Local aRegSe2   := {}
	
	If aRotAuto == Nil
		Mata521A()
	Else
		aChave := {"F2_DOC","F2_SERIE"}
		aRotAuto := SF2->(MSArrayXDB(aRotAuto,,5,,aChave))
		If !( Len(aRotAuto) > 0 )
			Return .T.
		EndIf
		If MaCanDelF2("SF2",SF2->(RecNo()),@aRegSD2,@aRegSE1,@aRegSE2)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Estorna o documento de saida                                   ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ					
			SF2->(MaDelNFS(aRegSD2,aRegSE1,aRegSE2,.F.,.F.,.T.,.F.))
		EndIf
	EndIf

	#IFDEF TOP
		TCInternal(5,"*OFF")   // Desliga Refresh no Lock do Top
		lTop := .T.
	#ENDIF
	return	
	l520Auto   := (aRotAuto <> Nil) //Variavel para rotina automatica
	
	PRIVATE lSD2520T:= (ExistTemplate("MSD2520"))
	PRIVATE lSD2520 := (existblock("MSD2520"))
	PRIVATE lA520EXC:= (existblock("A520EXC"))
	PRIVATE cFilter := ""
	
	If cPaisLoc != "BRA"
		PRIVATE cProcN := "MATA520"
	EndIf
	PRIVATE cCalcImpV:= GETMV("MV_GERIMPV")            // Internacionaliza‡„o
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define Array contendo as Rotinas a executar do programa  ³
	//³ ----------- Elementos contidos por dimensao ------------ ³
	//³ 1. Nome a aparecer no cabecalho                          ³
	//³ 2. Nome da Rotina associada                              ³
	//³ 3. Usado pela rotina                                     ³
	//³ 4. Tipo de Transa‡„o a ser efetuada                      ³
	//³    1 - Pesquisa e Posiciona em um Banco de Dados         ³
	//³    2 - Simplesmente Mostra os Campos                     ³
	//³    3 - Inclui registros no Bancos de Dados               ³
	//³    4 - Altera o registro corrente                        ³
	//³    5 - Remove o registro corrente do Banco de Dados      ³
	//³    6 - Altera determinados campos sem incluir novos Regs ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PRIVATE aRotina := {  { "Pesquisa","PesqBrw" , 0 , 0},;     //
	{ "Filtro","A520Filtro", 0 , 0},;    //"Filtro"
	{ "Visualizar","Mc090Visual", 0 , 2},;    //
	{ "Excluir","A520Elim"  , 0 , 5}  }   //
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define o cabecalho da tela de atualizacoes               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PRIVATE bFiltraBrw         // Expressao de Filtro
	PRIVATE cCadastro := OemToAnsi("Exclus„o de Notas Fiscais")	//
	
	If !l520Auto
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Ativa tecla F-10 para parametros                             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If cPaisLoc == "BRA"
			SetKey( VK_F12, { || pergunte("MT460A",.T.) } )
		Else
			SetKey( VK_F12, { || pergunte("MT520A",.T.) } )
		EndIf
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define parametros abertos                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cPaisLoc == "BRA"
		Pergunte("MT460A",.F.)
	Else
		If ! Pergunte("MT520A",.T.)
			Return
		EndIf
	EndIf
	cMarca  := GetMark(,"SF2","F2_OK")
	If ( l520Auto )
		aChave := {"F2_DOC","F2_SERIE"}
	//	aRotAuto := SF2->(MSArrayXDB(aRotAuto,,5,,aChave)) ##############
		If !( Len(aRotAuto) > 0 )
			Return .T.
		EndIf
		RecLock("SF2",.f.)
		SF2->F2_OK := cMarca
		MSUNLOCK()
		u_A520Elim("SF2",SF2->(RECNO()),5,cMarca)
	Else
		If cPaisLoc <> "BRA"
			cFilSF2  := ' F2_DOC >="'+mv_par07+'" .And. F2_DOC <="'+mv_par08+'"'
			cFilSF2  += ' .And. F2_SERIE >="'+mv_par09+'" .And. F2_SERIE <="'+mv_par10+'"' 
			cFilSF2  += ' .And. F2_CLIENTE >="'+mv_par11+'" .And. F2_CLIENTE <="'+mv_par12+'"' 
			cFilSF2  += ' .And. (F2_TIPO)$ "N " '
	   Endif
	
		If ExistBlock( "M520FIL" )
			cFilSF2 += Iif(cPaisLoc <> "BRA",".And.","")+ExecBlock("M520FIL",.F.,.F.)
		Endif
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Realiza a Filtragem                                                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SF2")
		bFiltraBrw := {|x| FilBrowse("SF2",@aIndexSF2,@cFilSF2+IIf(!Empty(cFilter).And.lTop,".and."+cFilter,"")) } 
		Eval(bFiltraBrw)
		SF2->(MsSeek(xFilial()))
	
	    //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	    //³ Ponto de entrada para pre-validar os dados a serem  ³
	    //³ exibidos.                                           ³
	    //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	    IF ExistBlock("M520BROW")
	       ExecBlock("M520BROW",.f.,.f.)
	    Endif
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Endereca a funcao de BROWSE                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		MarkBrow("SF2","F2_OK", , ,.F.,cMarca)
		
		dbSelectArea("SF2")
			Retindex("SF2")
		dbClearFilter()
		aEval(aIndexSF2,{|x| Ferase(x[1]+OrdBagExt())})
	
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Limpa o filtro e restaura as ordens originais.           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SF2")
	Set Filter to
	
	dbSelectArea("SD2")
	dbSetOrder(1)
	dbSelectArea("SF3")
	dbSetOrder(1)
	dbSelectArea("SD1")
	dbSetOrder(1)
Return .T. 


User FUNCTION A520Elim(cAlias,nReg,nOpc,cMarca,lInverte)

LOCAL cSavMenuh,nOpcA,cPedido,nDif:=0,cSavCur
LOCAL dDataFec := If(FindFunction("MVUlmes"),MVUlmes(),GetMV("MV_ULMES"))
LOCAL nIndice, cTxtMsg
Local cRetTitle := RTrim(RetTitle("CN_REMITO"))
Local cArqTrb   := ""

PRIVATE cArquivo,lLancPad30:=.F.,lLancPad35:=.F.,lLancPad27:=.F.,nHdlPrv:=0,nTotal:=0,cLoteFat
PRIVATE lDigita,lAglutina,lGeraLanc,lDtLanc := .F.
l520Auto := If (Type("l520Auto") == "U",.f.,l520Auto)
Private lExcRemito	:=	.F.
Private lLiber	:=	.T.
If !(FisChkDt(SF2->F2_EMISSAO))
	Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define variaveis de parametrizacao de lancamentos   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc=="BRA"
	Pergunte("MT460A",.F.)
Else
	Pergunte("MT520A",.F.)
	
	If mv_par05 == 1
		SA1->(dbSetOrder(1))
		SA1->(dbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))
		If !(SA1->A1_TIPO $ "E|3")      
		   cTxtMsg := OemToAnsi("Tem certeza que deseja eliminar os(as) ")+cRetTitle+OemToAnsi("s(es)?")  //+cRetTitle+
			If MsgYesNo(cTxtMsg,OemToAnsi(STR0007))  //"Atencion"
					lExcRemito := .T.
				EndIf
			EndIf
		EndIf
	EndIf
lDigita  := IIF(mv_par01==1,.T.,.F.)
lAglutina:= IIF(mv_par02==1,.T.,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica a existencia de lanc. Padronizados p/ Faturamento   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lLancPad30:=VerPadrao("630")	// Cancelamento de Notas Fiscais (Itens)
lLancPad35:=VerPadrao("635")	// Cancelamento de Notas Fiscais (Cabecalho)

dbSelectArea(cAlias)
If !(l520Auto)
	If MsgYesNo(OemToAnsi(STR0006),OemToAnsi(STR0007))		//"Confirma Dele‡„o das NFs Marcadas ?"###"Aten‡„o"
		Processa({|lEnd| fa520Processa(cAlias,nReg,nOpc,cMarca,lInverte,nOpca)})
	Endif
Else
	u_fa520Processa(cAlias,nReg,nOpc,cMarca,.F.,nOpca)
EndIf

If cPaisLoc <> "BRA"
	IndRegua("SF2",cArqTrb,"F2_FILIAL+F2_DOC",,'!(F2_TIPO)$"DC"',"Seleccionando Registros...")
	DbSelectArea("SF2")
	nIndice	:=	Retindex("SF2")
	#IFNDEF TOP
		DbSetIndex(cArqTrb+OrdBagExt())
	#ENDIF
	DbSetOrder(nIndice+1)
Endif
SF2->(dbSeek(xFilial())) //Edu
Return( nOpca )


User Function Fa520Processa(cAlias,nReg,nOpc,cMarca,lInverte,nOpca)
LOCAL cPedido,nDif:=0, cNomeArq, cIndex, cCond

dbSelectArea(cAlias)


If ! l520Auto
	ProcRegua(SF2->(RecCount()),21,4)
EndIf

While .T.
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Utiliza arquivo de liberados para geracao na nota      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    cCond := 'F2_FILIAL == "'+xFilial("SF2")+'" .and. '
	cCond += IIF(lInverte,'F2_OK <> "'+cMarca+'"', 'F2_OK == "'+cMarca+'"')
	
	If ExistBlock( "M520FIL" )
		cCond += ".And."+ExecBlock("M520FIL",.F.,.F.)
	EndIf
   
    If !InTransact() .and. !l520Auto
		dbSelectArea(cAlias)
  		cNomeArq := Criatrab(,.f.)
		dbSetOrder(1)
		cIndex := IndexKey()
		IndRegua("SF2",cNomeArq,cIndex,,cCond,OemToAnsi(STR0008))		//"Selecionando Registros..."
		nIndex := RetIndex("SF2")
		#IFNDEF TOP
			dbSetIndex(cNomeArq+OrdBAgExt())
		#ENDIF
		dbSetOrder(nIndex+1)
   Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se notas a serem excluidas foram geradas antes do   ³
	//³ ultimo fechamento de estoque                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If u_A520CheckUlt(cMarca,cAlias,If(FindFunction("MVUlmes"),MVUlmes(),GetMV("MV_ULMES")),lInverte)
		If !InTransact() .and. !l520Auto
  			dbGoTop()
  		Endif	
		While !Eof() 
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Processa condicao do filtro do usuario                       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !Empty(cFilter) .And. !&(cFilter)
				Dbskip()
				Loop
			Endif
			If &(cCond)	
				Begin Transaction Extended
				lDelSF2 := A520Dele(cAlias,cMarca,lInverte)
				End Transaction Extended
				dbSelectArea(cAlias)
			Endif
			dbSkip()
			If ! l520Auto
				IncProc(21,4)
			EndIf
		End
	Endif
	
    If !Intransact() .and. !l520Auto
		Retindex("SF2")
	Endif
	Set Filter To
	dbSetOrder(1)
	If !Intransact() .and. !l520Auto
		Ferase(cNomeArq+OrdBagExt())
	Endif	
	If !Empty(cFilter)
		Set Filter to &cFilter.
	EndIf
	Exit
End

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia para Lancamento Contabil, se gerado arquivo   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF (lLancPad30 .Or. lLancPad35) .And. lDtLanc .And. nHdlPrv != 0
	RodaProva(nHdlPrv,nTotal)
	ca100Incl(cArquivo,nHdlPrv,3,cLoteFat,lDigita,lAglutina)
Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a gravacao dos lancamentos do SIGAPCO            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PcoFinLan("000102")

If Type("bFiltraBrw")<>"U" .And. !Empty(bFiltraBrw)
	Eval(bFiltraBrw)
EndIf

Return nOpca


User Function A520CheckUlt(cMarca,cAlias,dDataFec,lInverte)

Local	cMsg,aNotas,aSave,cNotas,i,cSvCor,cCRLF,cSvScr,;
nOpc:=0,oDlg,cTitulo,lRet:=.T.
l520Auto := If (Type("l520Auto") == "U", .F., l520Auto)

aNotas:={}
aSave:={Alias(),IndexOrd(),Recno()}
cNotas:=""
cCRLF:=Chr(13)+Chr(10)
cTitulo:=OemToAnsi(STR0007)

dbSelectArea(cAlias)
dbSeek(xFilial())

/* ###### ALTERADO #######
While !Eof() .And. F2_FILIAL == xFilial()
	If (lInverte .Or. cMarca==F2_OK) .And. F2_EMISSAO<=dDataFec
		AADD(aNotas,{F2_DOC,F2_SERIE,F2_EMISSAO})
	Endif
	dbSkip()
End
*/

If Len(aNotas)>0
	
	lRet:=.F.
	
	cMsg:=OemToAnsi(STR0026)	//"As Notas Fiscais abaixo foram geradas antes do £ltimo "
	cMsg:=cMsg+OemToAnsi(STR0027)+DTOC(dDataFec)+OemToAnsi(STR0028)			//"fechamento de estoque em "###", sua exclus„o ir  compromenter o "
	cMsg:=cMsg+OemToAnsi(STR0029)	//"controle de estoque. "
	
	For i:=1 to Len(aNotas)
		cNotas:=cNotas+aNotas[i,1]+" - "+aNotas[i,2]+OemToAnsi(STR0030)+DTOC(aNotas[i,3])+cCRLF		//" - Emitida em "
	Next
	
	If !( l520Auto )
		DEFINE MSDIALOG oDlg TITLE OemtoAnsi(cTitulo) FROM  150,80 TO 350,560 PIXEL OF oMainWnd
		@ 01, 12 TO 77, 228 LABEL "" OF oDlg  PIXEL
		@ 10, 20 SAY OemToAnsi(cMsg) SIZE 200,30 OF oDlg PIXEL
		@ 30, 20 GET cNotas WHEN .F. SIZE 200,42 MEMO OF oDlg PIXEL
		DEFINE SBUTTON FROM 80, 172 TYPE 2 ACTION (nOpc:=1,oDlg:End()) ENABLE OF oDlg
		DEFINE SBUTTON FROM 80, 201 TYPE 1 ACTION (nOpc:=2,oDlg:End()) ENABLE OF oDlg
		ACTIVATE MSDIALOG oDlg
	Endif
	If nOpc==2
		lRet:=.T.
	Endif
	
Endif

dbSelectArea(aSave[1])
dbSetOrder(aSave[2])
dbGoto(aSave[3])

Return (lRet)
