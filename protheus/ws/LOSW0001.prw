#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "tbiconn.ch"

WSRESTFUL LOSW0001 DESCRIPTION 'Integrador CTE' FORMAT 'application/xml'
  WSMETHOD POST DESCRIPTION 'Metodo post para gravação da CTE na tabela de integração' WSSYNTAX '/acao/{}'
END WSRESTFUL

WSMETHOD POST WSSERVICE LOSW0001 

  Local lRet      := .T.
  Local cXML     := self:getContent()

  ::SetContentType("application/json")   	
  nOpc := 2

  If len(::aURLParms) < 3
    oResponse["message"]    := 'tipo e/ou acao e/ou chave nao enviada'
    oResponse["type"]       := "error"
    oResponse["status"]     := 400    

    self:SetStatus(400)
    self:SetResponse(EncodeUtf8(oResponse:toJson()))
    return .F.    
  endif

  cTipo_   := ::aURLParms[1]
  cAcao_   := ::aURLParms[2]
  cChave_  := ::aURLParms[3]

  oResponse := postCte(cXML, cTipo_, cAcao_, cChave_)

  self:SetStatus(oResponse['status'])
  self:SetResponse(EncodeUtf8(oResponse:toJson()))

return lRet

/*/{Protheus.doc} postCte
  (long_description)
  @type  Static Function
  @author user
  @since 13/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function postCte(cXML, cTipo_, cAcao_, cChave_)
  Local oResponse := JsonObject():new()
  Local cAcao := ""
  Local cTipo := ""

  if empty(cTipo_)
    oResponse["message"] := "É necessário enviar o tipo do XML!"
    oResponse["type"] := "error"
    oResponse["status"] := 400

    return oResponse
    
  endif

  Do Case
  Case cTipo_ == "cte"
    cTipo := "1"
  Case cTipo_ == "nfse"
    cTipo := "2"
  Otherwise
    oResponse["message"] := "O tipo (" + alltrim(cTipo_) + ") não está configurada!"
    oResponse["type"] := "error"
    oResponse["status"] := 400

    return oResponse
  EndCase

  if empty(cAcao_)
    oResponse["message"] := "É necessário enviar a ação a ser executada!"
    oResponse["type"] := "error"
    oResponse["status"] := 400

    return oResponse
    
  endif

  Do Case
  Case cAcao_ == "inclusao"
    cAcao := "I"
  Case cAcao_ == "cartacorrecao"
    cAcao := "C"
  Case cAcao_ == "exclusao"
    cAcao := "E"
  Otherwise
    oResponse["message"] := "A ação (" + alltrim(cAcao_) + ") não está configurada!"
    oResponse["type"] := "error"
    oResponse["status"] := 400

    return oResponse
    
  EndCase

  if empty(cChave_)
    oResponse["message"] := "É necessário enviar a chave!"
    oResponse["type"] := "error"
    oResponse["status"] := 400
    
    return oResponse
    
  endif

  if empty(cXML)
    oResponse["message"] := "É necessário enviar o XML no Body da requisição!"
    oResponse["type"] := "error"
    oResponse["status"] := 400
    
    return oResponse
    
  endif

  if existReg(cChave_, cTipo, cAcao)
    oResponse["message"] := "Já existe um registro para a chave (" + alltrim(cChave_) + ") para essa ação (" + alltrim(cAcao_) + ")!"
    oResponse["type"] := "error"
    oResponse["status"] := 400
    
    return oResponse
    
  endif

  cXml := strtran(strtran(cXml, Chr(9), ''), Chr(10), '')
  cXml := fRemoveCarc(cXml)

  ZZ1->( dbSetOrder(1) )
  RecLock('ZZ1', .T.)
    ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
    ZZ1->ZZ1_XML   := cXml
    ZZ1->ZZ1_DATA   := dDataBase
    ZZ1->ZZ1_HORA   := Time()
    ZZ1->ZZ1_CHAVE  := cChave_
    ZZ1->ZZ1_ACAO   := cAcao
    ZZ1->ZZ1_TIPO   := cTipo
    ZZ1->ZZ1_STATUS := 'A'
  ZZ1->(MsUnLock())

  oResponse["message"] := "Registro incluído na tabela de integração para processamento!"
  oResponse["type"] := "success"
  oResponse["status"] := 201

/*
  Do Case
    Case alltrim(cTipo) $ 'inclusao,cartacorrecao'
      if existReg(cChave, cTipo)
        oResponse["message"] := "Chave ("+cChave+") já está cadastrada!"
        oResponse["type"] := "error"
        oResponse["status"] := 400
        
        return oResponse
      endif

      cMensagem := popula(cXML, cChave, cTipo)

      //Caso retorne erro ao popular a tabela
      if !empty(cMensagem)
        oResponse["message"] := cTipo + ' - acao NAO permitida.'+cMensagem
        oResponse["type"] := "error"
        oResponse["status"] := 400
        
        return oResponse
      endif

      oResponse["message"] := cTipo + ' - concluido com sucesso'
      oResponse["type"] := "success"
      oResponse["status"] := 201

      return oResponse

    case alltrim(cTipo) $ 'possocancelar,possoinutilizar' 

      lExistReg := ExistReg(cChave, 'inclusao')   

      If !lExistReg
          oResponse["message"]    := cAcao + ' - acao NAO permitida. Título não está cadastrado no Protheus. '
          oResponse["type"]       := "error"
          oResponse["status"]     := 403 
          return oResponse
      ElseIf lExistReg .AND. ( QRY->ZZ1_STATUS $ 'A,E' .or. ( QRY->ZZ1_STATUS == 'P' .AND. !validBaixa(cChave) ) )
          oResponse["message"]    := cAcao + ' - acao permitida'
          oResponse["type"]       := "sucess"
          oResponse["status"]     := 201       
          return oResponse             
      ElseIf (lExistReg .AND. QRY->ZZ1_STATUS == 'P')
          oResponse["message"]    := cAcao + ' - acao NAO permitida. Já feita a baixa do titulo. '
          oResponse["type"]       := "error"
          oResponse["status"]     := 403          
          return oResponse                          
      EndIf 
      
    case alltrim(cTipo) $ 'cancelar,inutilizar'
      
      if ExistReg(cChave, cTipo)

        cMensagem := popula(cXML,cChave,cAcao)
        If Empty(cMensagem)
            oResponse["message"]    := cAcao + ' - concluido com sucesso'
            oResponse["type"]       := "sucess"
            oResponse["status"]     := 201
            return oResponse
        Else
            oResponse["type"]       := "error"
            oResponse["status"]     := 400
            oResponse["message"]    := cAcao + ' - acao NAO permitida.'+cMensagem
            return oResponse
        EndIf

      else 
        oResponse["type"]       := "error"
        oResponse["status"]     := 400
        oResponse["message"]    := "Chave ("+alltrim(cChave)+") já está cadastrada."
        return oResponse
      endif


    Otherwise
      oResponse["message"] := "Não existe essa ação disponível!"
      oResponse["type"] := "error"
      oResponse["status"] := 403
      
      return oResponse
  EndCase
  */
Return oResponse

/*/{Protheus.doc} existReg
  (long_description)
  @type  Static Function
  @author user
  @since 13/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function existReg(cChave, cTipo, cAcao)
  local lRet := .F.

  BeginSql alias 'QRY'
    SELECT ZZ1.R_E_C_N_O_ RECNO, 
           ZZ1.*
      FROM %table:ZZ1% ZZ1 
     WHERE ZZ1.%notdel% AND 
           RTRIM(ZZ1_ACAO) = %exp:cAcao% AND
           RTRIM(ZZ1_TIPO) = %exp:cTipo% AND
           RTRIM(ZZ1_CHAVE) = %exp:cChave%
  Endsql

  lRet := !QRY->( eof() )
  QRY->( dbCloseArea() )

Return lRet

/*/{Protheus.doc} validBaixa
  Valida se já houve baixa de titulo da NF
  @type  Static Function
  @author Leonardo Freitas
  @since 19/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function validBaixa(cChave)
  local lRet := .F.

  BeginSQL alias 'QRYBX'
    SELECT *
      FROM %table:SF2% f2 
     INNER JOIN %table:SE1% E1 ON
           e1_filial = f2_filial AND 
           e1_num = f2_doc AND 
           e1_prefixo = f2_serie AND 
           e1_cliente = f2_cliente AND 
           e1_loja = f2_loja AND
           (e1_saldo = 0 or e1_baixa != ' ') AND
           e1.%notdel%
     WHERE f2_chvnfe = %exp:alltrim(cChave)% AND
           f2.%notdel%
  EndSQL  

  if QRYBX->( !eof() )
    lRet := .T.
  endif
  QRYBX->( dbCloseArea() )
  
Return lRet

/*/{Protheus.doc} popula
  (long_description)
  @type  Static Function
  @author user
  @since 13/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function popula(cXml, cChave, cTipo)
  Local aAreaSA1 := SA1->( getArea() )
  Local cErro    := ""
  Local cAviso   := ""
  Local i
  Local cCodCli       := ""
  Local cLojaCli      := ""
  Local cTomador      := ""
  Local cCNPJ       := "" 
  Local cCNPJCli       := "" 
  Private cYNumSer    := ""
  Private cYNumNF     := ""
  Private cCHVNFE     := ""
  Private dEmissao  
  Private nVlrFrete   := 0

  Default cXml := ""

  oCTE := xmlParser(cXml, "_", @cErro, @cAviso)

  If ValType(oCTE) == 'U'
    return 'Erro no objeto XML: ' + cErro
  EndIf

  Do Case
    Case alltrim(cTipo) == 'inclusao' 
      aVars := {}
      aAdd(aVars, {"Serie CTE"        , "cYNumSer"    , WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_IDE:_SERIE:TEXT","string")        })
      aAdd(aVars, {"Numero CTE"       , "cYNumNF"     , WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_IDE:_NCT:TEXT","string")          })
      aAdd(aVars, {"CNPJ Emitente"    , "cCNPJ"       , WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:TEXT","string")        })
      aAdd(aVars, {"Chave CTE"        , "cCHVNFE"     , WSAdvValue(oCTE,"_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:TEXT","string")        })
      aAdd(aVars, {"Emissao"          , "dEmissao"    , WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_IDE:_DHEMI:TEXT","string")        })
      aAdd(aVars, {"Valor Frete"      , "nVlrFrete"   , WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_VPREST:_VTPREST:TEXT","string")   })

      //Valida se conseguiu recuperar as variaveis
      For i := 1 to Len(aVars)
        &(aVars[i][2]) := aVars[i][3]
        If ValType(&(aVars[i][2])) == 'U'
          Return "Tag " + aVars[i][1] + " não encontrada no xml do CTE"
        EndIf
      Next

      cYNumNF := strTran( strTran( oCTE:_CTEPROC:_CTE:_INFCTE:_IDE:_NCT:TEXT, Chr(9), '' ), Chr(10), '' ) 
      cYNumSer := strTran( strTran( oCTE:_CTEPROC:_CTE:_INFCTE:_IDE:_SERIE:TEXT, Chr(9), '' ), Chr(10), '' ) 

      cCNPJ := strtran(strtran(oCTE:_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:TEXT, Chr(9), ''), Chr(10), '')

      dEmissao    := StoD(StrTran(Left(dEmissao,10),'-',''))
      
      If !setEmpresa(cCNPJ)
        return 'Cadastro de filial não localizado com o CNPJ ' + cCNPJ
      EndIf

      cTomador := WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_IDE:_TOMA3:_TOMA:TEXT","string")
      If ValType(cTomador) == 'U'
        cTomador := WSAdvValue(oCTE,"_CTEPROC:_CTE:_INFCTE:_IDE:_TOMA4:_TOMA:TEXT","string")
      EndIf

      If cTomador == 'U'
        Return "Tag Tomador não encontrada no xml do CTE"
      EndIf

      cCNPJCli :=  getTomador(cTomador, oCTE)
      //Valida o CNPJ tomador
//      If Empty(cCNPJCli)
//        Return 'Erro ao tentar obter o CNPJ('+cCNPJCli+') do tomador.'
//      EndIf
      
      cCodCli  := ''
      cLojaCli := ''
      SA1->(dbSetOrder(3))
      If SA1->(DbSeek( xFilial("SA1") + PADR(cCNPJCli,TamSx3("A1_CGC")[1]) ))
        cCodCli  := SA1->A1_COD
        cLojaCli := SA1->A1_LOJA
      EndIf

      RecLock('ZZ1', .T.)
        ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
        ZZ1->ZZ1_FILCTE := cFilant
        ZZ1->ZZ1_NUMCTE := PADL(Alltrim(cYNumNF),LEN(ZZ1->ZZ1_NUMCTE),"0")
        ZZ1->ZZ1_SERCTE := cYNumSer
        ZZ1->ZZ1_CLIENT := cCodCli
        ZZ1->ZZ1_LOJA   := cLojaCli
        ZZ1->ZZ1_CGC   := cCNPJCli
        ZZ1->ZZ1_XML   := cXml
        ZZ1->ZZ1_DATA   := dDataBase
        ZZ1->ZZ1_HORA   := Time()
        ZZ1->ZZ1_CHAVE  := cChave
        ZZ1->ZZ1_ACAO   := cTipo
        ZZ1->ZZ1_STATUS := 'A'
      ZZ1->(MsUnLock())
      
    Case alltrim(cTipo) == 'cancelar'

      cCnpj := SubStr(Alltrim(cChave), 7, 14)

      If ValType(cCNPJ) == "U"
          return '_procEventoCTe:_eventoCTe:_infEvento:_CNPJ INVALIDA ' 
      EndIf

      If !setEmpresa(cCNPJ)
          return 'Cadastro de filial não localizado com o CNPJ ' + cCNPJ
      EndIf

      cDtcanc := WSAdvValue(oCTE,"_PROCEVENTOCTE:_EVENTOCTE:_infEvento:_dhevento:TEXT","string") 
      If ValType(cDtcanc) == "U"
          cDtcanc := WSAdvValue(oCTE,"_retEventoCTe:_infEvento:_dhRegEvento:TEXT","string") 
          If ValType(cDtcanc) == "U"
                  cDtcanc := WSAdvValue(oCTE,"_PROCEVENTOCTE:_retEventoCTe:_infEvento:_dhRegEvento:TEXT","string") 
          EndIf
      EndIf

      If ValType(cDtcanc) == "U"
          Return "Data do evento não encontrada no XML." + CRLF
      EndIf

      dDtCanc := StoD(StrTran(cDtcanc,"-",""))

      beginSQL alias 'QRYZZ1'
        SELECT * 
          FROM %table:ZZ1% zz1 
         WHERE zz1_chave = %exp:alltrim(cChave)% AND 
               zz1_acao = 'inclusao' AND 
               zz1.%notdel%
      endSQL

      If QRYZZ1->( Eof() )
          QRYZZ1->( dbCloseArea() )
          Return "Não foi encontrada requisição de inclusão para esta chave("+cChave+")."
      endif
      
      ZZ1->( dbSetOrder( 1 ) )
      RecLock('ZZ1', .T.)
        ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
        ZZ1->ZZ1_FILCTE := cFilant
        ZZ1->ZZ1_NUMCTE := PADL(Alltrim(QRYZZ1->ZZ1_NUMCTE),LEN(ZZ1->ZZ1_NUMCTE),"0")
        ZZ1->ZZ1_SERCTE := QRYZZ1->ZZ1_SERCTE
        ZZ1->ZZ1_CLIENT := QRYZZ1->ZZ1_CLIENT
        ZZ1->ZZ1_LOJA   := QRYZZ1->ZZ1_LOJA
        ZZ1->ZZ1_CGC   := Posicione("SA1",1,xFilial("SA1") + QRYZZ1->(ZZ1_CLIENT+ZZ1_LOJA),"A1_CGC")
        ZZ1->ZZ1_XML   := cXml
        ZZ1->ZZ1_DATA   := dDataBase
        ZZ1->ZZ1_HORA   := Time()
        ZZ1->ZZ1_CHAVE  := cChave
        ZZ1->ZZ1_ACAO   := cTipo
        ZZ1->ZZ1_STATUS := 'A'
      ZZ1->(MsUnLock())
      
      QRYZZ1->( dbCloseArea() )

    case Alltrim(cTipo) = 'inutilizar'
        cStat       := WSAdvValue(oCTE,"_soap_Envelope:_soap_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_cStat:TEXT"   ,"string")
        cCNPJ       := WSAdvValue(oCTE,"_soap_Envelope:_soap_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_CNPJ:TEXT"    ,"string")
        cSerie      := WSAdvValue(oCTE,"_soap_Envelope:_soap_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_SERIE:TEXT"   ,"string")
        cYNumNFIni  := WSAdvValue(oCTE,"_soap_Envelope:_soap_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_nCTIni:TEXT"  ,"string")
        cYNumNFFim  := WSAdvValue(oCTE,"_soap_Envelope:_soap_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_nCTFin:TEXT"  ,"string")
        dDataRec    := WSAdvValue(oCTE,"_soap_Envelope:_soap_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_dhRecbto:TEXT","string")
        
        If ValType(cCNPJ) == "U"
          cStat       := WSAdvValue(oCTE,"_env_Envelope:_env_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_cStat:TEXT"   ,"string")
          cCNPJ       := WSAdvValue(oCTE,"_env_Envelope:_env_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_CNPJ:TEXT"    ,"string")
          cSerie      := WSAdvValue(oCTE,"_env_Envelope:_env_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_SERIE:TEXT"   ,"string")
          cYNumNFIni  := WSAdvValue(oCTE,"_env_Envelope:_env_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_nCTIni:TEXT"  ,"string")
          cYNumNFFim  := WSAdvValue(oCTE,"_env_Envelope:_env_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_nCTFin:TEXT"  ,"string")
          dDataRec    := WSAdvValue(oCTE,"_env_Envelope:_env_Body:_cteInutilizacaoCTResult:_retInutCTe:_infInut:_dhRecbto:TEXT","string")
          If ValType(cCNPJ) == "U"
            return "Tag de CNPJ não encontrada no XML."
          EndIf
            
        EndIf

        If !setEmpresa(cCNPJ)
            return 'Cadastro de filial não localizado com o CNPJ ' + cCNPJ
        EndIf
        cYNumNF := IIF(cYNumNFIni == cYNumNFFim,  PadL(cYNumNFIni, len(SF2->F2_DOC), "0"), cYNumNFIni+"*" )
        dDataRec    := StoD(StrTran(dDataRec,"-",""))

        RecLock('ZZ1', .T.)
            ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
            ZZ1->ZZ1_FILCTE := cFilant
            ZZ1->ZZ1_NUMCTE := PADL(Alltrim(cYNumNF),LEN(ZZ1->ZZ1_NUMCTE),"0")
            ZZ1->ZZ1_SERCTE := cSerie
            ZZ1->ZZ1_XML       := cXml
            ZZ1->ZZ1_DATA       := dDataBase
            ZZ1->ZZ1_HORA       := Time()
            ZZ1->ZZ1_CHAVE      := cChave
            ZZ1->ZZ1_ACAO       := cAcao
            ZZ1->ZZ1_STATUS     := 'A'
        ZZ1->(MsUnLock())
    
    case cAcao == 'cartacorrecao'
      ZZ1->(DbSetOrder(1))
      If ZZ1->(DbSeek(xFilial('ZZ1') + cChave + PADR("inclusao",len(ZZ1->ZZ1_ACAO))))
        cNumNf      := ZZ1->ZZ1_NUMCTE
        cYNumSer    := ZZ1->ZZ1_SERCTE
        cCodCli     := ZZ1->ZZ1_CLIENT
        cLojaCli    := ZZ1->ZZ1_LOJA
        _cFilial    := ZZ1->ZZ1_FILCTE
        
        RecLock('ZZ1', .T.)                 
          ZZ1->ZZ1_XML       := cXml
          ZZ1->ZZ1_DATA       := dDataBase
          ZZ1->ZZ1_HORA       := Time()
          ZZ1->ZZ1_CHAVE      := cChave
          ZZ1->ZZ1_ACAO       := cAcao
          ZZ1->ZZ1_STATUS     := 'A'
          ZZ1->ZZ1_NUMCTE     := cNumNf
          ZZ1->ZZ1_SERCTE     := cYNumSer
          ZZ1->ZZ1_CLIENT     := cCodCli
          ZZ1->ZZ1_LOJA       := cLojaCli
          ZZ1->ZZ1_FILCTE     := _cFilial
        ZZ1->(MsUnLockAll())
      Else
          Return "Não houve inclusão para esta chave ("+cChave+") no Protheus." 
      EndIf

    Otherwise
      Return "Ação: '" + alltrim(aAcao) + "' não configurado! "
  EndCase

  fwRestArea(aAreaSA1)
Return ""

/*/{Protheus.doc} setEmpresa
  (long_description)
  @type  Static Function
  @author user
  @since 19/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function setEmpresa(cCNPJ)
    
  Local lRet := .F.
  
  OpenSM0(cEmpAnt)
  
  SM0->(DbGoTop())

  While SM0->(!Eof())
    conout('cCNPJ')
    conout("'" + cCNPJ + "'")
    conout('m0_cgc')
    conout("'" + SM0->M0_CGC + "'")
    If alltrim(SM0->M0_CGC) == alltrim(cCNPJ)
      cFilAnt := SM0->M0_CODFIL
      lRet    := .T.
      Exit
    EndIf
    SM0->(DbSkip())
  EndDo

Return lRet

/*/{Protheus.doc} getTomador
  (long_description)
  @type  Static Function
  @author user
  @since 19/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
static function getTomador(cTomador, oCTE)
  Local cRet      := ''
  Local aTomador  := {}

  aAdd(aTomador, {'0', '_CTEPROC:_CTE:_INFCTE:_REM:_CNPJ:TEXT'    })
  aAdd(aTomador, {'1', '_CTEPROC:_CTE:_INFCTE:_EXPED:_CNPJ:TEXT'  })
  aAdd(aTomador, {'2', '_CTEPROC:_CTE:_INFCTE:_RECEB:_CNPJ:TEXT'  })
  aAdd(aTomador, {'3', '_CTEPROC:_CTE:_INFCTE:_DEST:_CNPJ:TEXT'   })
  aAdd(aTomador, {'4', '_CTEPROC:_CTE:_INFCTE:_IDE:_TOMA4:_CNPJ:TEXT'})

  nPos    := aScan(aTomador,{|x| x[1] == cTomador})
  
  If nPos <> 0
    cRet := WSAdvValue(oCTE,aTomador[nPos][2],"string")
    If ValType(cRet) == 'U'
      aTomador := {}
      aAdd(aTomador, {'0', '_CTEPROC:_CTE:_INFCTE:_REM:_CPF:TEXT'    })
      aAdd(aTomador, {'1', '_CTEPROC:_CTE:_INFCTE:_EXPED:_CPF:TEXT'  })
      aAdd(aTomador, {'2', '_CTEPROC:_CTE:_INFCTE:_RECEB:_CPF:TEXT'  })
      aAdd(aTomador, {'3', '_CTEPROC:_CTE:_INFCTE:_DEST:_CPF:TEXT'   })
      aAdd(aTomador, {'4', '_CTEPROC:_CTE:_INFCTE:_IDE:_TOMA4:_CPF:TEXT'})

      cRet := WSAdvValue(oCTE,aTomador[nPos][2],"string")
      If ValType(cRet) == 'U'
        cRet   := ''
      EndIf
    EndIf
  EndIf

Return cRet

/*/{Protheus.doc} fRemoveCarc
    Remover caracteres especiais 
    @type  Static Function
    @author user
    @since 22/03/2024
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function fRemoveCarc(cString_)
    cString_ := FwCutOff(cString_, .T.)
    cString_ := strtran(cString_,"ã","a")
	cString_ := strtran(cString_,"á","a")
	cString_ := strtran(cString_,"à","a")
	cString_ := strtran(cString_,"ä","a")
    cString_ := strtran(cString_,"º","")
    cString_ := strtran(cString_,"%","")
    cString_ := strtran(cString_,"*","")     
    cString_ := strtran(cString_,"&","")
    cString_ := strtran(cString_,"$","")
    cString_ := strtran(cString_,"#","")
    cString_ := strtran(cString_,"§","") 
    cString_ := strtran(cString_,",","")
    cString_ := StrTran(cString_, "'", "")
    cString_ := StrTran(cString_, "#", "")
    cString_ := StrTran(cString_, "%", "")
    cString_ := StrTran(cString_, "*", "")
    cString_ := StrTran(cString_, "&", "E")
    cString_ := StrTran(cString_, "!", "")
    cString_ := StrTran(cString_, "@", "")
    cString_ := StrTran(cString_, "$", "")
    cString_ := StrTran(cString_, "?", "")
    cString_ := StrTran(cString_, '°', '')
    cString_ := StrTran(cString_, 'ª', '')
    cString_ := Alltrim(Lower(cString_))
Return cString_
