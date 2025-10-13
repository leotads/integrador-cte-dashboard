#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "tbiconn.ch"

WSRESTFUL cte DESCRIPTION 'Integrador CTE' FORMAT 'application/xml'
  WSMETHOD POST DESCRIPTION 'Metodo post para gravação da CTE na tabela de integração' WSSYNTAX '/acao/{}'
END WSRESTFUL

WSMETHOD POST WSSERVICE cte 
  Local lRet      := .T.
  Local cBody     := self:getContent()

  ::SetContentType("application/json")   	
  nOpc := 2

  If len(::aURLParms) < 2
    oResponse["message"]    := 'acao e/ou chave nao enviada'
    oResponse["type"]       := "error"
    oResponse["status"]     := 400    

    self:SetStatus(400)
    self:SetResponse(EncodeUtf8(oResponse:toJson()))
    return .F.    
  endif

  cTipo   := ::aURLParms[1]
  cChave  := ::aURLParms[2]

  oResponse := postCte(cBody, cTipo, cChave)

  self:SetStatus(oResponse:status)
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
Static Function postCte(cBody, cTipo, cChave)
  Local oResponse := JsonObject():new()

  if empty(cTipo)
    oResponse["message"] := "É necessário enviar a acao!"
    oResponse["type"] := "error"
    oResponse["status"] := 400

    return oResponse
    
  endif

  if empty(cChave)
    oResponse["message"] := "É necessário enviar a chave!"
    oResponse["type"] := "error"
    oResponse["status"] := 400
    
    return oResponse
    
  endif

  Do Case
    Case alltrim(cTipo) $ 'inclusao,cartacorrecao'
      if existReg(cChave, cTipo)
        oResponse["message"] := "Chave ("+cChave+") já está cadastrada!"
        oResponse["type"] := "error"
        oResponse["status"] := 400
        
        return oResponse
      endif

      cMensagem := popula(cBody, cChave, cTipo)

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
      
    Otherwise
      oResponse["message"] := "Não existe essa ação disponível!"
      oResponse["type"] := "error"
      oResponse["status"] := 400
      
      return oResponse
  EndCase
  
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
Static Function existReg(cChave, cTipo)
  local lRet := .F.

  BeginSql alias 'QRY'
    SELECT ZA4.R_E_C_N_O_ as RECNO, 
           ZA4.*
      FROM %table:ZA4% as ZA4 
     WHERE ZA4.%notdel% AND 
           RTRIM(ZA4_ACAO) = %exp:cTipo% AND
           RTRIM(ZA4_CHAVE) = %exp:cChave%
  Endsql

  lRet := !QRY->( eof() )
  QRY->( dbCloseArea() )

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

      cCNPJ := oCTE:_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:TEXT
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
      If Empty(cCNPJCli)
        Return 'Erro ao tentar obter o CNPJ('+cCNPJCli+') do tomador.'
      EndIf
      
      SA1->(dbSetOrder(3))
      If SA1->(DbSeek( xFilial("SA1") + PADR(cCNPJCli,TamSx3("A1_CGC")[1]) ))
        cCodCli  := SA1->A1_COD
        cLojaCli := SA1->A1_LOJA
      Else
        Return 'Tomador de CNPJ('+cCNPJCli+') não encontrado.'
      EndIf

      RecLock('ZA4', .T.)
        ZA4->ZA4_FILIAL := xFilial("ZA4")
        ZA4->ZA4_FILCTE := cFilant
        ZA4->ZA4_NUMCTE := PADL(Alltrim(cYNumNF),LEN(ZA4->ZA4_NUMCTE),"0")
        ZA4->ZA4_SERCTE := cYNumSer
        ZA4->ZA4_CLIENT := cCodCli
        ZA4->ZA4_LOJA   := cLojaCli
        ZA4->ZA4_CNPJ   := cCNPJCli
        ZA4->ZA4_BODY   := cXml
        ZA4->ZA4_DATA   := dDataBase
        ZA4->ZA4_HORA   := Time()
        ZA4->ZA4_CHAVE  := cChave
        ZA4->ZA4_TIPO   := cTipo
        ZA4->ZA4_STATUS := 'A'
      ZA4->(MsUnLock())
      
    Otherwise
      Return "Ação: '" + alltrim(aAcao) + "' não configurado! "
  EndCase

  fwRestArea(aAreaSA1)
Return ""
