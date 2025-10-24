#INCLUDE 'PROTHEUS.CH'
#include 'TOPCONN.CH'
#include 'tbiconn.ch'
CLASS TNYXPEDIDOS

	DATA		TAG
	DATA		RETORNO			AS STRING
	DATA		LRETORNO		AS BOOLEAN
	DATA		SC5				AS ARRAY

	//³A propriedade C6CUSTOMFIELDS serve para incluirmos mais campos no execauto,³
	//³campos que nao estao no execauto aqui posto.                               ³
	DATA		aC6CUSTOMFIELDS	AS ARRAY
	DATA		aC6toD2			AS ARRAY
	
	//³A propriedade C5CUSTOMFIELDS serve para incluirmos mais campos no execauto,³
	//³campos que nao estao no execauto aqui posto.                               ³
	DATA		aC5CUSTOMFIELDS	AS ARRAY
	DATA		aC5toF2			AS ARRAY	

	//³As propriedades FILIAL, SERIENF, DOC, CLIENTENF, LOJACLINF, TIPONF e FORMULNF servem             ³
	//³para gerarmos as NFs, ou seja, se o objetivo for gerar NF entao estas propriedades deverao estar ³
	//³preenchidas.                                                                                     ³
	DATA		FILIAL			AS STRING
	DATA		SERIENF			AS STRING
	DATA		DOC				AS STRING
	DATA		CLIENTENF		AS STRING
	DATA		LOJACLINF		AS STRING
	DATA		TIPONF			AS STRING
	DATA 		FORMULNF			AS STRING     
	 
	//³A propriedade DOCS serve para guardar as NFs que foram geradas ou as que       ³
	//³o usuario quer passar como parametro para cancelamentos, entao, se quiser lidar³
	//³so com uma NF entao preenche-se so os FILIAL, SERIENF e ETC e se quiser lidar  ³
	//³com varias NFs preenche-se o array DOCS.                                       ³
	//³Esta propriedade guarda um array de 'cruds' do SF2                             ³
	DATA		DOCS				AS ARRAY

	//³A propriedade lVERIFCAMPOS quando ativada chama a funcao u_VerifCampos,        ³
	//³esta funcao faz verificacoes basicas de preenchimento das tabelas SA1, SA2, SB1³
	//³e SF4. Para detectar alguns erros basicos que ha em notas eletronicas.         ³
   DATA		lVERIFCAMPOS


	DATA		lCRIASB2
	
	
	DATA		aSC9Validos
	DATA		lExluiPedido
	DATA 		lMostrarErro
	
	DATA 		aNUMNFS //Numeracao das NFS informadas pelo usuario
	DATA 		cTIPOTIT //Tipo que sera gerado o titulo no financeiro
	 
	//³Breve explicacao sobre as propriedades SC5  e DOCS.                 ³
	//³Ambas as propriedades sao arrays de 'crud', na propriedade          ³
	//³SC5 guardaremos um array com os crud de SC5/SC6 e no DOCS           ³
	//³guardaremos um array de crud de SF2.                                ³
	//³Estes arrays servirao tanto de parametro como de retorno.           ³
	//³Por exemplo, se vc quiser gerar NFs e passou 1 pedido como pa-      ³
	//³rametro, entao vc preenche a propriedade SC5 com os dados do        ³
	//³pedido, chama o metodo INCLUIRNF e ao final do metodo a             ³
	//³propriedade DOCS estara preenchida com as NF geradas.               ³
	//³Da mesma forma que se voce preencher o array DOCS com as NFs        ³
	//³e chamar o metodo EXCLUIRNF entao o sistema preenchera no           ³
	//³SC5 os pedidos referentes a estas NFs (ou seja, se vc tinha informa-³
	//³coes no SC5 estas informacoes serao perdidas)                       ³
	//³E por fim, ainda utilizaremos as propriedades FILIAL, SERIENF, DOC  ³
	//³e etc pois ha casos em que queremos gerar apenas uma NF e nao       ³
	//³queremos preencher um array                                         ³
  METHOD 	NEW() constructor
	METHOD	INCLUIRPEDIDO()
	METHOD	EXCLUIRPEDIDO()
	METHOD	LIBERAPEDIDO()
	METHOD	DESLIBERARPEDIDO()
	METHOD	QUALPEDIDO()
	METHOD	GERANF()
	METHOD	INCLUIRNF()
	METHOD	ACAO()
	METHOD	VERIFICA()
	METHOD	EXCLUIRNF()
	METHOD	CANCELNF()
	METHOD	QUALNF()
	METHOD	REPLICARCAMPOS()
ENDCLASS

METHOD NEW() CLASS TNYXPEDIDOS
	self:SC5					:= {}
	self:DOCS				:= {}
	self:aC6CUSTOMFIELDS	:= {}
	self:aC6toD2			:= {}
	self:aC5CUSTOMFIELDS	:= {}
	self:aC5toF2			:= {}
	self:FILIAL				:= ''
	self:lVERIFCAMPOS		:= .F.
	self:lCRIASB2			:= .T.        
	self:aSC9Validos		:= {}	   
	self:lExluiPedido		:= .T.
	self:lMostrarErro		:= .T.
	self:aNUMNFS			:= {}	
	self:cTIPOTIT			:= ''
RETURN SELF

//±±ºDesc.     ³Metodo principal de inclusao da NF                          º±±
//±±º          ³Este metodo utiliza outros metodos para fazer todo o proce- º±±
//±±º          ³dimento, que inicia com a inclusao do pedido de venda e vai º±±
//±±º          ³ate a geracao da NF de saida.                               º±±
METHOD INCLUIRNF() CLASS TNYXPEDIDOS
   local lResult	:= .T.
   local nStart, cCodZZ1 
   Static cSaida := ''
	SetacFilAnt(self:FILIAL)
	if lResult
  		lResult	:= ::VERIFICA()
	endif
	if lResult
		lResult	:= ::INCLUIRPEDIDO()
	endif
	if lResult
		lResult	:= ::GERANF()
	endif
	if lResult
		lResult	:= ::REPLICARCAMPOS()
	endif
  	MSUNLOCKALL()
return lResult

//±±ºDesc.     ³Metodo auxiliar para fazer verificacoes antes da inclusao daº±±
//±±º          ³NF                                                          º±±
METHOD VERIFICA() CLASS TNYXPEDIDOS
	local lResult	:= .T.
	local aTabelas	:= {'SC5', 'SC6', 'SC9', 'SF2', 'SD2'}
	local i
	local cAuxConteudo	:= xFilial('SC5')

	for i:= 2 to len(aTabelas)
		if cAuxConteudo <> xFilial(aTabelas[i])
			lResult	:= .F.
		endif
	next
	if !lResult
		self:RETORNO	:= 'TNYXPEDIDOS:VERIFICA, VERIFIQUE OS COMPARTILHAMENTOS DE SC5, SC6, SC9, SF2 e SD2, devem estar iguais.'
		Conout(self:RETORNO)
		alert(self:RETORNO)/*apagar*/
	endif

return lResult

//±±ºDesc.     ³Metodo auxiliar utilizado para incluir pedido de venda      º±±
METHOD INCLUIRPEDIDO() CLASS TNYXPEDIDOS
	local 	lResult
	private 	lMsErroAuto := .F.    
	private 	nAcao 		:= 3
	lResult	:= ::ACAO()
return lResult

//±±ºDesc.     ³Metodo auxiliar que serve para liberar o pedido de venda    º±±
METHOD LIBERAPEDIDO() CLASS TNYXPEDIDOS
	local i
	local oAuxPed
	private cPerg			:= "MT460A"
	private aPvlNfs		:= {}
	private aBloqueio		:= {}
	
	for i	:= 1 to len(self:SC5)
		oAuxPed	:= self:SC5[i]
		SetacFilAnt(oAuxPed:Get('C5_FILIAL'))

		//³ Gera as variaveis das perguntas com as ultimas definicoes do usuario ³
		//³ para que nao seja necessario exibir a tela de pergunta               ³
		SX1->(dbSeek(cPerg))
		while SX1->(!eof()) .and. SX1->X1_GRUPO == cPerg
			&(SX1->X1_VAR01) := iif(SX1->X1_GSC == "C",SX1->X1_PRESEL,SX1->X1_CNT01)
			SX1->(dbSkip())
		endDo
	
		SC9->(DbSetOrder(1)) //FILIAL+NUMERO+ITEM
		SC9->(DbSeek(xFilial("SC9")+oAuxPed:Get('C5_NUM')))
		While SC9->(!EOF()) .and. SC9->C9_FILIAL == xFilial("SC9") .and. SC9->C9_PEDIDO == oAuxPed:Get('C5_NUM')
		   Ma410LbNfs(2,@aPvlNfs,@aBloqueio)
		   SC9->(DbSkip())
		End
	next
return .T.  

//±±ºDesc.     ³Metodo auxiliar que serve para gerar a nota fiscal de saida º±±
//±±º          ³a partir de um pedido de venda ja liberado.                 º±±
METHOD GERANF() CLASS TNYXPEDIDOS
	local lResult		:= .T.
	Local aPvlNfs 		:= {}
	Local aMata520Cab	:= {}
	local i, j
   local oAuxPed
   local aAliasNFe	:= {}   
   local cNumNota
	local cMV_TPNRNFS :=  GetMv('MV_TPNRNFS')
			

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Seta as tabelas  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SC9->(dbSetOrder(1))
 	SC9->(DbSetOrder(1))
	SC5->(DbSetOrder(1))
	SC6->(DbSetOrder(1))
	SE4->(DbSetOrder(1))
	SB1->(DbSetOrder(1))
	SB2->(DbSetOrder(1))
	SF4->(DbSetOrder(1))
   SA1->(dbSetOrder(1)) //A1_FILIAL, A1_COD, A1_LOJA, R_E_C_N_O_, D_E_L_E_T_
   DA3->(dbSetOrder(1)) //DA3_FILIAL, DA3_COD, R_E_C_N_O_, D_E_L_E_T_
   SA4->(dbSetOrder(1)) //A4_FILIAL, A4_COD, R_E_C_N_O_, D_E_L_E_T_

	for i:= 1 to len(self:SC5) 
		
	   	oAuxPed	:= self:SC5[i]
		aAdd(aAliasNFe, 'SA1')

		if !empty(oAuxPed:Get('C5_TRANSP'))
			aAdd(aAliasNFe, 'SA4')
		endif

		if !empty(oAuxPed:Get('C5_VEICULO'))
			aAdd(aAliasNFe, 'DA3')
		endif

		aAdd(aAliasNFe, 'SB1')
		aAdd(aAliasNFe, 'SF4')
		aPvlNfs 		:= {}
		aMata520Cab	:= {}

		SetacFilAnt(oAuxPed:Get('C5_FILIAL'))
		ConOut('::GERANF NOTA ' + StrZero(i, 6) + ' CLIENTE ' + oAuxPed:Get('C5_CLIENTE') + oAuxPed:Get('C5_LOJACLI') + ' - Antes:  ' + (cHoraIni := Time()))

		//Numeracao da nf feita pelo usuario, realiza validacao se a nota nao ja existe 
		If Len(self:aNUMNFS) > 0
			cYNumNF := self:aNUMNFS[i]
			SF2->(DbSetOrder(1))//F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA
			If SF2->(DbSeek(xFilial('SF2') + Padr(cYNumNF, Len(SF2->F2_DOC)) + Padr(self:SERIENF, Len(SF2->F2_SERIE)) + oAuxPed:Get('C5_CLIENTE') + oAuxPed:Get('C5_LOJACLI') ))
				lResult := .F.
				AutoGrLog('Nota fiscal ' + cYNumNF + ' ja cadastrada no sistema. ')
				::RETORNO := 'Nota fiscal ' + cYNumNF + ' ja cadastrada no sistema. '
				Exit
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿                                                                                    
		//³ Obtem os itens a serem faturados   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SC9->(dbSeek(cSeekSC9 := xFilial("SC9") + oAuxPed:Get('C5_NUM')))
		
		while SC9->(!eof()) .and. SC9->C9_FILIAL + SC9->C9_PEDIDO == cSeekSC9

			If ! Empty(self:aSC9Validos)
				If aScan(self:aSC9Validos, SC9->(RecNO())) == 0						
					SC9->(DbSkip())
					Loop
				EndIf
			EndIf

			If !Empty(SC9->C9_NFISCAL)
				SC9->(DbSkip())
				Loop
			EndIf			

			if !empty(SC9->C9_BLCRED + SC9->C9_BLEST + SC9->C9_BLWMS)
				recLock("SC9",.F.)
					SC9->C9_BLCRED	:= "  "
					SC9->C9_BLEST	:= "  "
					SC9->C9_BLWMS	:= "  "
				SC9->(msUnLock())
			endIf
			SC5->(dbSeek(xFilial("SC5") + SC9->C9_PEDIDO))
			SC6->(dbSeek(xFilial("SC6") + SC9->C9_PEDIDO + SC9->C9_ITEM + SC9->C9_PRODUTO))
			SE4->(dbSeek(xFilial("SE4") + oAuxPed:Get('C5_CONDPAG')))
			SB1->(dbSeek(xFilial("SB1") + SC6->C6_PRODUTO))
			SB2->(dbSeek(xFilial("SB2") + SC9->C9_PRODUTO + SC9->C9_LOCAL))
			SF4->(dbSeek(xFilial("SF4") + SC6->C6_TES))
			DA3->(dbSeek(xFilial('DA3') + oAuxPed:Get('C5_VEICULO')))
			SA4->(dbSeek(xFilial('DA3') + oAuxPed:Get('C5_TRANSP')))
			SA1->(dbSeek(xFilial('SA1') + oAuxPed:Get('C5_CLIENTE')+oAuxPed:Get('C5_LOJACLI')))
			
			if self:lVerifCampos
				lResult	:= u_VerifCamposNFe(aAliasNFe)
				if !lResult
					exit
				endif
			endif	
			aAdd(aPvlNfs, { SC9->C9_PEDIDO, SC9->C9_ITEM, SC9->C9_SEQUEN, SC9->C9_QTDLIB, SC9->C9_PRCVEN, SC9->C9_PRODUTO, ;
								 SF4->F4_ISS == "S", SC9->(recno()), SC5->(recno()), SC6->(recno()), SE4->(recno()), SB1->(recno()), ;
								 SB2->(recno()), SF4->(recno())} )
			SC9->(dbSkip())
		endDo

		ConOut('::GERANF NOTA ' + StrZero(i, 6) + ' CLIENTE ' + oAuxPed:Get('C5_CLIENTE') + oAuxPed:Get('C5_LOJACLI') + ' - Depois: ' + Time())
		ConOut('TEMPO TOTAL: ' + ElapTime(cHoraIni, Time()) + ' - QTD ITENS: ' + cValToChar(Len(aPvlNfs)))
                                                                           
		if !lResult
			exit
		endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Fatura o Pedido de Venda ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 
		private cPerg			:= "MT460A"
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gera as variaveis das perguntas com as ultimas definicoes do usuario ³
		//³ para que nao seja necessario exibir a tela de pergunta               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SX1->(dbSeek(cPerg))
		while SX1->(!eof()) .and. AllTrim(SX1->X1_GRUPO) == cPerg
			&(SX1->X1_VAR01) := iif(SX1->X1_GSC == "C",SX1->X1_PRESEL,SX1->X1_CNT01)
			SX1->(dbSkip())
		endDo
		dAux			:= dDataBase
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Comentando em 04/01/15 pois vimos que essa alteracao para emissao nao era correto³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//dDatabase	:= oAuxPed:Get('C5_EMISSAO')
	
		if len(aPvlNfs) > 0

			CONOUT('VAI EXECUTARO O MaPvlNfs ' + Time())
			
			//backup do tipo para geracao do titulo
			cMVNOTBKP := MVNOTAFIS

			//verifica se foi informado			If !Empty(self:cTIPOTIT)			
				MVNOTAFIS := self:cTIPOTIT
			EndIf

			cNumNota := MaPvlNfs(aPvlNfs,self:SERIENF)

			//restaura o tipo do titulo
			MVNOTAFIS := cMVNOTBKP

			lResult	:= !Empty(cNumNota) 
			
			CONOUT(cNumNota)

			if Empty(::RETORNO)
				::RETORNO	:= 'NF INCLUIDA COM SUCESSO'                                              
			else
				::RETORNO 	+= 'NF INCLUIDA COM SUCESSO' 
			endif				

			CONOUT('EXECUTOU O MaPvlNfs ' + Time())

		else
			lMsErroAuto	:= .T.
			lResult	:= .F.
		endif
		dDataBase := dAux
	next
	if lResult
		self:QUALNF()
	endif
Return lResult

//±±ºDesc.     ³Metodo principal da exclusao da nota fiscal de saida.       º±±
//±±º          ³Este metodo chamara diversos metodos auxiliares.            º±±
METHOD EXCLUIRNF() CLASS TNYXPEDIDOS
	local lResult	:= .T.

	local cDoc		:= Padr(self:DOC			, len(SF2->F2_DOC		))
	local cSerie	:= Padr(self:SERIENF		, len(SF2->F2_SERIE	))
	local cCliente := Padr(self:CLIENTENF	, len(SF2->F2_CLIENTE))
	local cLoja		:= Padr(self:LOJACLINF	, len(SF2->F2_LOJA	))
	local cTipo		:= Padr(self:TIPONF		, len(SF2->F2_TIPO	))
	local cFormul	:= Space(len(SF2->F2_FORMUL))

	local nStart	:= 0
	local cCodZZ1	:= ''
	local oAuxCrud   
	local i

	SetacFilAnt(self:FILIAL)
	
	private cSaida	:= ''	
	private lMsErroAuto	:= .F.
   
	nStart := Seconds()
   
	SF2->(dbSetOrder(1)) //F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO
	
	if empty(self:DOCS) .AND. SF2->(dbSeek(cFilAnt+cDoc+cSerie+cCliente+cLoja+cFormul+cTipo))
		oAuxCrud	:= Crud():New('SF2', SF2->(recNo()))
		aAdd(self:DOCS, oAuxCrud)
	endif
	for i := 1 to len(self:DOCS)
			// BeginTran()
			oAuxCrud	:= self:DOCS[i]
			SetacFilAnt(oAuxCrud:Get('F2_FILIAL'))
			SF2->(dbSeek(oAuxCrud:Get('F2_FILIAL')+oAuxCrud:Get('F2_DOC')+oAuxCrud:Get('F2_SERIE')+oAuxCrud:Get('F2_CLIENTE')+oAuxCrud:Get('F2_LOJA')+oAuxCrud:Get('F2_FORMUL')+oAuxCrud:Get('F2_TIPO')))

			self:FILIAL		:= SF2->F2_FILIAL
			self:DOC			:= SF2->F2_DOC
			self:SERIENF	:= SF2->F2_SERIE
			self:CLIENTENF	:= SF2->F2_CLIENTE
			self:LOJACLINF	:= SF2->F2_LOJA
			self:TIPONF		:= SF2->F2_TIPO
			self:FORMULNF	:= SF2->F2_FORMUL

			if lResult     
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Este metodo eh chamado apenas para guardar qual eh o pedido de venda da nota fiscal passada no parametro³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lResult	:= ::QUALPEDIDO()
			endif
			if lResult
				lResult	:= ::CANCELNF()
			endif
			If self:lExluiPedido
				if lResult
					lResult	:= ::DESLIBERARPEDIDO()
				endif
				if lResult
					lResult	:= ::EXCLUIRPEDIDO()
				endif     
			Endif
			if lResult
				::RETORNO	:= 'NOTA FISCAL ' + cDoc + ' ' + cSerie + ' - CANCELADA COM SUCESSO'
				cSaida	:= self:RETORNO
			endif 
			/*if lResult
		  		EndTran()
			else
			 	DisarmTransaction()
			endif*/
	
			nStop := Seconds() 
	
			if nStop < nStart
				nDuraca := 86399 - nStart + nStop
			else
				nDuraca := nStop - nStart			
			endif
	
			MSUNLOCKALL()  
	next
return lResult 

//±±ºDesc.     ³Metodo auxiliar que serve para por no ::SC5:C5_NUM o numero º±±
//±±º          ³do pedido de venda vinculado a nota fiscal passada nos pa-  º±±
//±±º          ³rametros.                                                   º±±
//±±º          ³Eh necessario este metodo pois ficamos sem o numero do pe-  º±±
//±±º          ³dido apos a exclusao da nota e, apos a exclusao da nota nos º±±
//±±º          ³precisamos desliberar o pedido e exclui-lo, para nao ficar  º±±
//±±º          ³com lixo na base de dados                                   º±±
METHOD QUALPEDIDO() CLASS TNYXPEDIDOS
	local lResult	:= .T.     
	local cQuery	:= ''      
	local cNumPed
	local i
	local oAuxPed

	cQuery 	:= " SELECT R_E_C_N_O_ AS RECNOSC5 "
	cQuery 	+= " FROM " + RetSQLName('SC5') + " SC5 "
	cQuery 	+= " WHERE 	C5_FILIAL 	= '" + Padr(self:FILIAL		, len(SF2->F2_FILIAL		)) + "'"
	cQuery	+= " AND 	C5_NOTA 		= '" + Padr(self:DOC			, len(SF2->F2_DOC			)) + "'"
	cQuery	+= " AND 	C5_SERIE 	= '" + Padr(self:SERIENF	, len(SF2->F2_SERIE		)) + "'"
	cQuery	+= " AND 	C5_CLIENTE 	= '" + Padr(self:CLIENTENF	, len(SF2->F2_CLIENTE	)) + "'"
	cQuery	+= " AND 	C5_LOJACLI	= '" + Padr(self:LOJACLINF	, len(SF2->F2_LOJA		)) + "'"
	cQuery	+= " AND 	C5_TIPO 		= '" + Padr(self:TIPONF	 	, len(SF2->F2_TIPO		)) + "'"
	cQuery	+= " AND 	SC5.D_E_L_E_T_ <> '*'	"

	cQuery := ChangeQuery(cQuery)
	
	If Select("QRY") > 0
		QRY->(dbCloseArea())
	EndIf
	
	TcQuery cQuery New Alias "QRY" 
	
	if QRY->(EOF())
		lResult	:= .F.
		CONOUT("====================================="+cSaida+"========================================")
	else

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Limpa o array que teria os pedidos pois, esta delecao eh feita se³
		//³baseando no numero da NF, entao via de regra este array estaria  ³
		//³vazio neste momento                                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		self:SC5	:= {}
		while !QRY->(EOF())
			
			oAuxPed	:= crud():new("SC5", QRY->RECNOSC5, 1)
			oAuxPed:addChild('SC6', 1)
			
			aAdd(self:SC5, oAuxPed)
			
			QRY->(dbSkip())
		enddo
	endif 
	
	QRY->(dbCloseArea())

return lResult 

//±±ºDesc.     ³Metodo que retorna quais foram as NFs geradas a partir dos  º±±
//±±º          ³pedidos informados                                          º±±
METHOD QUALNF() CLASS TNYXPEDIDOS
	local lResult	:= .T.     
	local cQuery	:= ''      
	local cNumPed
	local i
	local oAuxPed
	local aAuxNF	:= {}
	local aNF		:= {}   
	local oAuxCrud

	SF2->(dbSetOrder(1)) //F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO, R_E_C_N_O_, D_E_L_E_T_
	for i:= 1 to len(self:SC5)
		oAuxPed	:= self:SC5[i]
		SetacFilAnt(oAuxPed:Get('C5_FILIAL'))
		SC9->(dbSetOrder(1)) //FILIAL+NUMERO+ITEM
		SC9->(dbSeek(xFilial("SC9")+oAuxPed:Get('C5_NUM')))
		while SC9->(!EOF()) .and. SC9->C9_FILIAL == oAuxPed:Get('C5_FILIAL') .and. SC9->C9_PEDIDO == oAuxPed:Get('C5_NUM')
			if SF2->(dbSeek(SC9->C9_FILIAL+SC9->C9_NFISCAL+SC9->C9_SERIENF+SC9->C9_CLIENTE+SC9->C9_LOJA+self:FORMULNF+self:TIPONF))
				aAdd(aAuxNF, SF2->(recNo()))
			endif
			SC9->(dbSkip())
		enddo		
	next
 	
	for i:= 1 to len(aAuxNF)
		if Ascan(aNF,{|x| x == aAuxNF[i]}) == 0
			aAdd(aNF, aAuxNF[i])
		endif
	next
	for i:= 1 to len(aNF)
		oAuxCrud	:= Crud():New('SF2', aNF[i])
		aAdd(self:DOCS, oAuxCrud)
	next
return lResult 

//±±ºDesc.     ³Metodo auxiliar que serve para cancelar a nota fiscal de    º±±
//±±º          ³saida.                                                      º±±
METHOD CANCELNF() CLASS TNYXPEDIDOS
	local lResult	:= .T.                       
	
	local _cFilial	:= Padr(self:FILIAL		, len(SF2->F2_FILIAL	))
	local cDoc		:= Padr(self:DOC			, len(SF2->F2_DOC		))
	local cSerie	:= Padr(self:SERIENF		, len(SF2->F2_SERIE	))
	local cCliente := Padr(self:CLIENTENF	, len(SF2->F2_CLIENTE))
	local cLoja		:= Padr(self:LOJACLINF	, len(SF2->F2_LOJA	))
	local cTipo		:= Padr(self:TIPONF		, len(SF2->F2_TIPO	))
	local cFormul	:= Space(len(SF2->F2_FORMUL))

	private lMsErroAuto	:= .F.
	SF2->(dbSetOrder(1))	//filial + doc + serie + cliente + loja + formul + tipo   
	SF2->(dbSeek(_cFilial+cDoc+cSerie+cCliente+cLoja+cFormul+cTipo))
	cFilAnt	:= (_cFilial)
  		aMata520Cab   :={{"F2_DOC"    	,cDoc			,Nil},; 
      				  {"F2_SERIE"    	,cSerie		,Nil},;
      				  {"F2_CLIENTE" 	,cCliente	,Nil},;
      				  {"F2_LOJA"    	,cLoja   	,Nil},;
      				  {"F2_FORMUL"   	,cFormul   	,Nil},;      				  
      				  {"F2_TIPO"    	,cTipo		,Nil}}

	MSExecAuto({|x| u_MATA520(x)},aMata520Cab)
	//MSExecAuto({|x| MATA520(x)},aMata520Cab)
	

	If lMsErroAuto
//		MostraErro()
		lResult	:= .F.
	EndIf   
return lResult  

//±±ºDesc.     ³Metodo auxiliar que serve para desliberar o pedido de venda º±±
//±±º          ³vinculado a nota fiscal passada no parametro pois, sem des- º±±
//±±º          ³liberar o sistema nao aceita exclui-lo                      º±±
METHOD DESLIBERARPEDIDO() CLASS TNYXPEDIDOS
	local lResult	:= .T.     
	local cQuery	:= ''      
	local cNumPed
	local	aMata410Cab 
	local aMata410Itens 
   local i
   local oAuxPed
	SC9->(dbSetOrder(1))   
	
   for i:= 1 to len(self:SC5)         
   	oAuxPed			:= self:SC5[i]
   	SetacFilAnt(oAuxPed:Get('C5_FILIAL'))
   	oAuxPed:Get('C5_FILIAL')
		cNumPed			:= Padr(AllTrim(oAuxPed:get('C5_NUM')), len(SC5->C5_NUM))
		aMata410Cab  	:= {{"C5_NUM"      , cNumPed       ,Nil}}   // Numero do pedido SC5
		aMata410Itens 	:= {{"C6_NUM"      , cNumPed       ,Nil}}   // Numero do Pedido SC6
		

		SC9->(dbSeek(xFilial("SC9")+cNumPed)) // f2ilial + pedido   
		while !SC9->(Eof()) .And. xFilial('SC9') == SC9->C9_FILIAL .and. cNumPed == SC9->C9_PEDIDO
			SC9->(a460Estorna())
			SC9->(dbSkip())
		enddo
	next
return lResult

//±±ºDesc.     ³Metodo auxiliar utilizado para excluir pedido de venda      º±±
METHOD EXCLUIRPEDIDO() CLASS TNYXPEDIDOS
	local lResult			:= .T.
	private lMsErroAuto  := .F.    
	private nAcao 			:= 5
	lResult 					:= ::ACAO()
  
return lResult

//±±ºDesc.     ³Metodo auxiliar que serve para incluir, alterar e excluir   º±±
//±±º          ³pedidos de venda, utilize a variavel nAcao para definir istoº±±
METHOD ACAO() CLASS TNYXPEDIDOS

	local aCamposSC5		:= {}
	local aCamposSC6		:= {}
	local aCpoSC6Aux		:= {}
	local cRetorno 		:= 'PEDIDO'
	local lResult			:= .T.
	local i, t, z
	local oPedAux
	local laC6CustomFields	:= !empty(self:aC6CUSTOMFIELDS)
	local laC5CustomFields	:= !empty(self:aC5CUSTOMFIELDS)
	
	private lMsErroAuto  := .F.    
	private nOpc 			:= 3
	private lMsHelpAuto	 := .T.
	private _cC5TipLib 	 := Alltrim(SuperGetMv("MS_C5TPLIB",.F.,"2"))
	
	SB1->(dbSetOrder(1)) // filial + cod
	//Cabecalho
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³preenche o pedido³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  
	for t:= 1 to len(self:SC5)

		oPedAux	:= self:SC5[t]
		SetacFilAnt(oPedAux:Get('C5_FILIAL'))
		dDataBase	:= iif(Empty(oPedAux:Get('C5_EMISSAO')), dDatabase, oPedAux:Get('C5_EMISSAO'))

		if nAcao	== 5 .or. nAcao == 4
	  		aAdd(aCamposSC5, {"C5_NUM"   	,oPedAux:Get('C5_NUM')		,nil})
		endif
		aAdd(aCamposSC5, {"C5_TIPO"   ,oPedAux:Get('C5_TIPO')		,nil})

		aAdd(aCamposSC5, {"C5_CLIENTE",oPedAux:Get('C5_CLIENTE')	,nil})
		aAdd(aCamposSC5, {"C5_LOJACLI",oPedAux:Get('C5_LOJACLI')	,nil})
		aAdd(aCamposSC5, {"C5_TIPOCLI",oPedAux:Get('C5_TIPOCLI')	,nil})
		aAdd(aCamposSC5, {"C5_CONDPAG",oPedAux:Get('C5_CONDPAG')	,nil})
		aAdd(aCamposSC5, {'C5_TRANSP'	,oPedAux:Get('C5_TRANSP' )	,nil})
		aAdd(aCamposSC5, {'C5_VEICULO',oPedAux:Get('C5_VEICULO')	,nil})
		aAdd(aCamposSC5, {'C5_DESPESA',oPedAux:Get('C5_DESPESA')	,nil})
		
		aAdd(aCamposSC5, {"C5_TIPLIB" ,_cC5TipLib        			,Nil}) // Tipo de Liberacao. 1 - Por item	 	

		if laC5CustomFields
			for z:= 1 to len(self:aC5CUSTOMFIELDS)
				If aScan(aCamposSC5,{|x| x[1] == self:aC5CUSTOMFIELDS[Z] } ) == 0
					aAdd(aCamposSC5, {self:aC5CUSTOMFIELDS[Z],oPedAux:Get(self:aC5CUSTOMFIELDS[Z])	,nil})					
				EndIf
			next
		endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³itens do pedido³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		for i:= 1 to oPedAux:GetLenChild('SC6')
	
			oPedAux:SetLine('SC6', i)
			
			SB1->(dbSeek(xFilial('SB1')+AllTrim(oPedAux:Get('C6_PRODUTO'))))

			if self:lCriaSB2
				CriaSB2(SB1->B1_COD,'01',oPedAux:Get('C5_FILIAL'))
			endif

			cTes	:=	iif(!empty(SB1->B1_TS),SB1->B1_TS,oPedAux:Get('C6_TES'))
			cCFOP	:= oPedAux:Get('C6_CF')
			
			if !empty(oPedAux:Get('C6_ITEM'))
				aAdd(aCpoSC6Aux, {"C6_ITEM"   ,oPedAux:Get('C6_ITEM')		,nil})
			endif

			aAdd(aCpoSC6Aux, {"C6_PRODUTO",oPedAux:Get('C6_PRODUTO')	,nil})
			aAdd(aCpoSC6Aux, {"C6_QTDVEN" ,oPedAux:Get('C6_QTDVEN')	,nil})
			aAdd(aCpoSC6Aux, {"C6_PRCVEN" ,oPedAux:Get('C6_PRCVEN')	,nil})
			aAdd(aCpoSC6Aux, {"C6_PRUNIT" ,oPedAux:Get('C6_PRCVEN')	,nil})
			aAdd(aCpoSC6Aux, {"C6_TES"    ,oPedAux:Get('C6_TES')		,nil})
			aAdd(aCpoSC6Aux, {"C6_DESPESA",oPedAux:Get('C6_DESPESA')	,nil})

			aAdd(aCpoSC6Aux, {"C6_VALDESC",oPedAux:Get('C6_VALDESC')	,nil})
         
           if !empty(oPedAux:Get('C6_LOCAL'))
				aAdd(aCpoSC6Aux, {"C6_LOCAL"  ,oPedAux:Get('C6_LOCAL')	,nil})
			endif
			
			if laC6CustomFields
				for z:= 1 to len(self:aC6CUSTOMFIELDS)
					If aScan(aCpoSC6Aux, {|x| x[1] == self:aC6CUSTOMFIELDS[Z] }) == 0
						aAdd(aCpoSC6Aux, {self:aC6CUSTOMFIELDS[Z],oPedAux:Get(self:aC6CUSTOMFIELDS[Z])	,nil})					
					EndIf
				next
			endif

			aAdd(aCpoSC6Aux, {"C6_QTDLIB" ,oPedAux:Get('C6_QTDVEN')	,nil})

			aAdd(aCamposSC6,aCpoSC6Aux)
			aCpoSC6Aux	:= {}
		next



	    ConOut('::ACAO ' + StrZero(t, 3) + ' CLIENTE: ' + oPedAux:Get('C5_CLIENTE') + oPedAux:Get('C5_LOJACLI') + " nOpc: " + cValToChar(nOpc) + " Antes  - Hora: " + (cHoraIni := Time()))
				
		MSExecAuto({|x,y,z|Mata410(x,y,z)},aCamposSC5,aCamposSC6,nAcao)   
	   
	    ConOut('::ACAO ' + StrZero(t, 3) + ' CLIENTE: ' + oPedAux:Get('C5_CLIENTE') + oPedAux:Get('C5_LOJACLI') + " nOpc: " + cValToChar(nOpc) + " Depois - Hora: " + Time() )
		ConOut('TEMPO TOTAL:' + ElapTime(cHoraIni, Time()) + " QTD ITENS: " + cValToChar(oPedAux:GetLenChild('SC6'))) 

		cSaida	:= ''
		if lMsErroAuto
			If ::Self:lMostrarErro
				MostraErro()
			EndIf
		  	CONOUT("=====================================ERRO NA GERAÇÃO DA NF "+cSaida+"========================================")
		else
			if nAcao	<> 5
				oPedAux:Set('C5_NUM'		, SC5->C5_NUM		)
				oPedAux:Set('C5_FILIAL'	, SC5->C5_FILIAL	)
				
				self:SC5[t]	:= oPedAux
			
			endif
			::RETORNO 	:= 'INCLUIDO COM SUCESSO'
			cSaida		:= ::RETORNO
		endif
		aCamposSC5	:= {}
		aCamposSC6	:= {}
	next
	
return !lMsErroAuto

Static Function SetacFilAnt(_cFilial)
	local cAuxFilAnt	:= cFilAnt
	cFilAnt	:= _cFilial
	if empty(cFilAnt)
		cFilAnt	:= cAuxFilAnt
	endif
return             

//±±ºDesc.     ³Metodo responsavel por replicar os campos do SC6 para o SD2,º±±
//±±º          ³os campos que serao replicados sao os que estao no array    º±±
//±±º          ³self:aC6toD2                                                º±±
METHOD REPLICARCAMPOS() CLASS TNYXPEDIDOS
	local lResult		:= .T.
	local aFieldsC6	:= self:aC6toD2
	local aFieldsC5	:= self:aC5toF2	
	local oSC5
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Exemplo de aFields: ³
	//³{                   ³
	//³{'C6_Z15', 'D2_Z15'}³
	//³{'C6_Z21', 'D2_Z21'}³
	//³}                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	local i, t, z
	SF2->(dbSetOrder(1)) //F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FORMUL, F2_TIPO, R_E_C_N_O_, D_E_L_E_T_
	if !empty(aFieldsC5) .OR. !empty(aFieldsC6)
		SD2->(dbSetOrder(8)) //D2_FILIAL, D2_PEDIDO, D2_ITEMPV, R_E_C_N_O_, D_E_L_E_T_
		for i:= 1 to len(self:SC5)
			oSC5	:= self:SC5[i]

	
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Primeiro preenche os campos que vao do C5 para o F2³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			if !empty(aFieldsC5)
				if SD2->(dbSeek(oSC5:Get('C5_FILIAL')+oSC5:Get('C5_NUM')))	
					if SF2->(dbSeek(SD2->(D2_FILIAL +D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA)))
						RecLock('SF2', .F.)
							for z:= 1 to len(aFieldsC5)
								SF2->&(aFieldsC5[z][2])	:= oSC5:Get(aFieldsC5[z][1])
							next
						SD2->(msUnLock())
					endif
				endif
			endif

			for t:= 1 to oSC5:getLenChild('SC6')
				oSC5:setLine('SC6', t)

				SD2->(dbSeek(cSeek:= oSC5:Get('C5_FILIAL')+oSC5:Get('C5_NUM')+oSC5:Get('C6_ITEM')))
				while !SD2->(EOF()) .AND. cSeek == SD2->D2_FILIAL + SD2->D2_PEDIDO + SD2->D2_ITEMPV
					RecLock('SD2', .F.)
						for z:= 1 to len(aFieldsC6)
							SD2->&(aFieldsC6[z][2])	:= oSC5:Get(aFieldsC6[z][1])
						next
					SD2->(msUnLock())
					SD2->(dbSkip())
				enddo
			next
		next 
	endif
	
return lResult


//±±ºDesc.     ³Funcao que testa o componente, fazendo as operacoes basicas º±±
//±±º          ³do mesmo.                                                   º±±
User Function 50TestPedido()
	local aSC6		:= {}
	local oPedido	:=	TNYXPEDIDOS():New()
	local oCrud
	LOCAL I
	PREPARE ENVIRONMENT EMPRESA '99' FILIAL '01' TABLES 'SC5'

 	oPedido:SERIENF	:= '1  '
	oPedido:FILIAL		:= u_QQUm('SM0', 'M0_CODFIL')
	oPedido:TIPONF		:= 'N'
	oPedido:FORMULNF	:= Space(len(SF2->F2_FORMUL))

	for i:= 1 to 1
		oCrud				:= crud():new("SC5", nil, 1)
		oCrud:Set('C5_FILIAL', u_QQUm('SM0', 'M0_CODFIL'))
		oCrud:Set('C5_TIPO'		, 'N'			)
		oCrud:Set('C5_EMISSAO'	, dDatabase)
		cCliAux	:= u_QQUM('SA1', 'A1_COD+A1_LOJA')
//		cCliAux	:= '00000301'
		SA1->(dbSeek(xFilial('SA1')+cCliAux))
		oCrud:Set('C5_CLIENTE'	, left(cCliAux, 6))
		oCrud:Set('C5_LOJACLI'	, Right(cCliAux, 2)	)
		oCrud:Set('C5_CLIENT'	, left(cCliAux, 6)	)
		oCrud:Set('C5_LOJAENT'	, Right(cCliAux, 2)		)
		oCrud:Set('C5_TIPOCLI'	, 'F'	)
		oCrud:Set('C5_CONDPAG'	, '001'		)
		oCrud:Set('C5_TIPLIB' 	, '1'			)
		oCrud:Set('C5_YTPNF' 	, 'C'			)

		oCrud:addChild('SC6')
	
		oCrud:addLine("SC6")
	
	   oCrud:set('C6_PRODUTO'	, u_QQUM('SB1', 'B1_COD')	)
		oCrud:set('C6_ITEM'		, '01'					)
		nQtd	:= Randomize(1, 99)
		nPrc	:= Randomize(1, 2000)
		oCrud:set('C6_QTDVEN'	, nQtd						)
		oCrud:set('C6_QTDLIB'	, nQtd						)
		oCrud:set('C6_PRCVEN'	, nPrc						)
		oCrud:set('C6_PRUNIT'	, nPrc						)
		oCrud:set('C6_TES'		, '501'					)
		oCrud:set('C6_Z15'		, '501'					)
		oCrud:set('C6_Z21'		, '502'					)				
	//	oCrud:set('C6_CF'			, '5512'					)

		aAdd(oPedido:SC5, oCrud)
	next
	oPedido:aC6toD2			:= {{'C6_Z15','D2_Z15'},{'C6_Z21','D2_Z21'}}
	oPedido:aC6CUSTOMFIELDS	:= {'C6_Z15', 'C6_Z21'}

	oPedido:aC5CUSTOMFIELDS	:= {'C5_YTPNF'}
	oPedido:aC5toF2			:= {{'C5_YTPNF','F2_YTPNF'}}

	oPedido:INCLUIRNF()
//	oPedido:EXCLUIRNF()
Return
                         
User Function 01P11edVend(nOpc)
	local aSC6		:= {}
	local oPedido	:=	TNYXPEDIDOS():New()
	local oCrud
	LOCAL I
	PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' TABLES 'SC5'
	cFilAnt	:= u_QQUm('SM0', 'M0_CODFIL')
 	oPedido:SERIENF	:= '1  '
	oPedido:FILIAL		:= cFilAnt
	oPedido:TIPONF		:= 'N'
	oPedido:FORMULNF	:= Space(len(SF2->F2_FORMUL))

		oCrud				:= crud():new("SC5", nil, 1)
		oCrud:Set('C5_FILIAL', u_QQUm('SM0', 'M0_CODFIL'))
		oCrud:Set('C5_TIPO'		, 'N'			)
		oCrud:Set('C5_EMISSAO'	, dDatabase)
		cCliAux	:= u_QQUM('SA1', 'A1_COD+A1_LOJA')
//		cCliAux	:= '00000301'
		SA1->(dbSeek(xFilial('SA1')+cCliAux))
		oCrud:Set('C5_CLIENTE'	, left(cCliAux, 6))
		oCrud:Set('C5_LOJACLI'	, Right(cCliAux, 2)	)
		oCrud:Set('C5_CLIENT'	, left(cCliAux, 6)	)
		oCrud:Set('C5_LOJAENT'	, Right(cCliAux, 2)		)
		oCrud:Set('C5_TIPOCLI'	, 'F'	)
		oCrud:Set('C5_CONDPAG'	, '001'		)
		oCrud:Set('C5_TIPLIB' 	, '1'			)

		oCrud:addChild('SC6')
	
		oCrud:addLine("SC6")
	
	   oCrud:set('C6_PRODUTO'	, u_QQUM('SB1', 'B1_COD')	)
		oCrud:set('C6_ITEM'		, '01'					)
		nQtd	:= Randomize(1, 99)
		nPrc	:= Randomize(1, 2000)
		oCrud:set('C6_QTDVEN'	, nQtd						)
		oCrud:set('C6_QTDLIB'	, nQtd						)
		oCrud:set('C6_PRCVEN'	, nPrc						)
		oCrud:set('C6_PRUNIT'	, nPrc						)
		oCrud:set('C6_TES'		, '501'					)
	//	oCrud:set('C6_CF'			, '5512'					)

		aAdd(oPedido:SC5, oCrud)

	oPedido:INCLUIRNF()
//	oPedido:EXCLUIRNF()
	
	   cDocOri	:= SF2->F2_DOC
return      

user function 010PedVend()
	local nPos := 0

	PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' TABLES 'SC5'	   
   private oCrud
	private aEntregas

	aEntregas	:= {}
	oAux			:= Crud():new('Z15', 4, 1)
	aAdd(aEntregas, oAux)
	oAux			:= Crud():new('Z15', 5, 1)
  	aAdd(aEntregas, oAux)

	Z21->(dbGoTo(20))
	oAcao	:= Crud():New('Z21', Z21->(RecNo()))

	U_FatLojVen()
 	SD2->(dbGoBottom())
 	aNFs	:= {}
// 	aAdd(aNFs, SD2->(RecNo()))
 //	aAdd(aNFs, SD2->(RecNo())-1)

	cFilAnt	:= '010101'
   aCab := {{ "F1_DOC"    , 'D' + StrZero(aNFs[1], 8)       , Nil, Nil },;
				{ "F1_SERIE" , '1  '        	, Nil, Nil },;
            { "F1_FORNECE", '000003'   	, Nil, Nil },;
            { "F1_LOJA"   , '01' 			, Nil, Nil },;
            { "F1_COND"   , "001"      	, Nil, Nil },;
            { "F1_EMISSAO", Date()     	, Nil, Nil },;
				{ "F1_EST"       , 'RN'    	, Nil, Nil },;      
            { "F1_TIPO"   , "D"           , Nil, Nil },;
            { "F1_FORMUL" , "S"           , Nil, Nil },;
            { "F1_ESPECIE", "NF"          , Nil, Nil },;
            { "E2_NATUREZ", "NOTA DE CR"  , Nil, Nil }}

   dbSelectarea("SD2")
   dbSetorder(3)   
   aItensD1	:= {}
   aIt			:= {}
   For nPos := 1 To Len(aNFs)
   
		SD2->(dbGoTo(aNFs[nPos]))
		SF4->(DbSetOrder(1))
      SF4->(DbSeek(xFilial("SF4")+SD2->D2_TES))
     
      aAreaSF4 := SF4->(GetArea())          
     
      If !Empty(SF4->F4_TESDV)              
      	cTesDev := SF4->F4_TESDV     
         SF4->(DbSetOrder(1))
         SF4->(DbSeek(xFilial("SF4") + cTesDev))
         cCfOpF4 := SF4->F4_CF                    
		Endif
      RestArea(aAreaSF4)

      aItensD1	:= {}
      AAdd( aItensD1, { "D1_COD"     , SD2->D2_COD    , Nil})
      AAdd( aItensD1, { "D1_QUANT"   , SD2->D2_QUANT 	, Nil})
      AAdd( aItensD1, { "D1_VUNIT"   , SD2->D2_PRCVEN , Nil})
		AAdd( aItensD1, { "D1_TOTAL"   , SD2->D2_TOTAL 	, Nil})
		AAdd( aItensD1, { "D1_TES"     , "401"    		, Nil})
      AAdd( aItensD1, { "D1_TIPO"    , "D"            , Nil})
//    AAdd( aItensD1, { "D1_CF"       , "1202"   , Nil})
      AAdd( aItensD1, { "D1_NFORI"   , SD2->D2_DOC    , Nil})
      AAdd( aItensD1, { "D1_SERIORI" , SD2->D2_SERIE , Nil})
      AAdd( aItensD1, { "D1_ITEMORI" , SD2->D2_ITEM   , Nil})
//    AAdd( aItensD1, { "D1_CONTA"   , "13101"        , Nil})
      AAdd(aIt,aItensD1)
	Next nPos      


   lMsErroAuto := .F.

   MsExecAuto({|x,y,z,w|Mata103(x,y,z,w)},aCab, aIt,3,.F.)

   If lMsErroAuto
//      MostraErro()
   Endif   

Return

//±±ºDesc.     ³Funcao que testa o componente, fazendo as operacoes basicas º±±
//±±º          ³do mesmo.                                                   º±±
User Function geraNF(cFil,aProds)
	local aSC6		:= {}
	local oPedido	:=	TNYXPEDIDOS():New()
	local oCrud
	LOCAL I
	//PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' TABLES 'SC5'

 	oPedido:SERIENF	:= '1  '
	oPedido:FILIAL		:= cFil                                        //u_QQUm('SM0', 'M0_CODFIL')
	oPedido:TIPONF		:= 'N'
	oPedido:FORMULNF	:= Space(len(SF2->F2_FORMUL))
	
	oCrud := crud():new("SC5", nil, 1)
	oCrud:Set('C5_FILIAL'   , cFil)                                 //u_QQUm('SM0', 'M0_CODFIL')
	oCrud:Set('C5_TIPO'		, 'N')
	oCrud:Set('C5_EMISSAO'	, dDatabase)
	cCliAux	:= u_QQUM('SA1', 'A1_COD+A1_LOJA')
//	cCliAux	:= '00000301'
	SA1->(dbSeek(xFilial('SA1')+cCliAux))
	oCrud:Set('C5_CLIENTE'	, left(cCliAux, 6))
	oCrud:Set('C5_LOJACLI'	, Right(cCliAux, 2))
	oCrud:Set('C5_CLIENT'	, left(cCliAux, 6))
	oCrud:Set('C5_LOJAENT'	, Right(cCliAux, 2))
	oCrud:Set('C5_TIPOCLI'	, 'F'	)
	oCrud:Set('C5_CONDPAG'	, '001')
	oCrud:Set('C5_TIPLIB' 	, '1')
	oCrud:Set('C5_YTPNF' 	, 'C')
	
	oCrud:addChild('SC6')	
	
	for i:=1 to len(aProds)	
		
		oCrud:addLine("SC6")
	   oCrud:set('C6_PRODUTO'	, aProds[i])                        // u_QQUM('SB1', 'B1_COD')
		oCrud:set('C6_ITEM'		, StrZero(i, 2))                    // '01'
		nQtd	:= 1                                                  // Randomize(1, 99)
		nPrc	:= 1                                                  // Randomize(1, 2000)
		oCrud:set('C6_QTDVEN'	, nQtd)
		oCrud:set('C6_QTDLIB'	, nQtd)
		oCrud:set('C6_PRCVEN'	, nPrc)
		oCrud:set('C6_PRUNIT'	, nPrc)
		oCrud:set('C6_TES'		, '704')
		oCrud:set('C6_Z15'		, '501')
		oCrud:set('C6_Z21'		, '502')				
	//	oCrud:set('C6_CF'			, '5512')	

	next
	
	aAdd(oPedido:SC5, oCrud)
	oPedido:aC6toD2			:= {{'C6_Z15','D2_Z15'},{'C6_Z21','D2_Z21'}}
	oPedido:aC6CUSTOMFIELDS	:= {'C6_Z15', 'C6_Z21'}

	oPedido:aC5CUSTOMFIELDS	:= {'C5_YTPNF'}
	oPedido:aC5toF2			:= {{'C5_YTPNF','F2_YTPNF'}}

	oPedido:INCLUIRNF()
//	oPedido:EXCLUIRNF()
Return

//±±ºDesc.     ³Funcao que testa o componente, fazendo as operacoes basicas º±±
//±±º          ³do mesmo.                                                   º±±
User Function criaSaldo(cFil,aProds)
	
	local cLocal := '01'

	For i=1 to len(aProds)
		criaSb2(aProds[i], cLocal, cFil)
	next

return

