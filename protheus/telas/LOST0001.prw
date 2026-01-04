#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "topconn.ch"
#include "tbicode.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} LOST0001
Tela de integraÃ§Ã£o de notas CTE GW
@type user function
@author Leonardo Freitas
@since 15/10/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function LOST0001()

  CHKFILE("ZZ1")
  CHKFILE("ZZ2")

  FwCallApp("integrador-cte-dashboard")
Return 

/*/{Protheus.doc} JsToAdvpl
  (long_description)
  @type  Static Function
  @author user
  @since 15/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function JsToAdvpl(oWebChannel,cType,cContent)

  Do Case
    Case cType == 'getQuantityDocuments'
      oWebChannel:AdvPLToJS('getQuantityDocuments', cValToChar(qtdRegists()))
    Case cType == 'getQuantityIntegrated'
      oWebChannel:AdvPLToJS('getQuantityIntegrated', cValToChar(qtdRegists('P')))
    Case cType == 'getQuantityOpenDocuments'
      oWebChannel:AdvPLToJS('getQuantityOpenDocuments', cValToChar(qtdRegists('A')))
    Case cType == 'getQuantityErrors'
      oWebChannel:AdvPLToJS('getQuantityErrors', cValToChar(qtdRegists('E')))
    Case cType == 'chartDocumentsPerDay'
      oWebChannel:AdvPLToJS('chartDocumentsPerDay', reqPerDay(cContent))
    Case cType == 'chartDocumentsPerMonth'
      oWebChannel:AdvPLToJS('chartDocumentsPerMonth', rqPerMonth(cContent))
    Case cType == 'chartDocumentsPerYear'
      oWebChannel:AdvPLToJS('chartDocumentsPerYear', rqPerYear(cContent))
    Case cType == 'chartDocumentsPerYears'
      oWebChannel:AdvPLToJS('chartDocumentsPerYears', rqPerYears(cContent))
    Case cType == 'getDocuments'
      oWebChannel:AdvPLToJS('getDocuments', getAllDocs(cContent))
    Case cType == 'excluiDocument'
      oWebChannel:AdvPLToJS('excluiDocument', ExcluirDoc(cContent))
    Case cType == 'downloadDocument'
      oWebChannel:AdvPLToJS('downloadDocument', encodeutf8(baixaDocto(cContent)))
    Case cType == 'reprocessDocument'
      oWebChannel:AdvPLToJS('reprocessDocument', reproDocto(cContent))
    Case cType == 'getLog'
      oWebChannel:AdvPLToJS('getLog', encodeutf8(getLog(cContent)))
  End

Return .T.

/*/{Protheus.doc} qtdAllDocs
  Retorna a quantidade total de documentos de integraÃ§Ã£o
  @type  Static Function
  @author Leonardo Freitas
  @since 15/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function qtdRegists(cStatus)

  Local nQuantidade := 0
  Local cWhere := "% %"
  default cStatus := ""

  if !empty(cStatus)
    cWhere := "% AND ZZ1.ZZ1_STATUS = '" + alltrim(cStatus) + "' %"
  endif

  BeginSQL alias 'ZZ1TOT'
    SELECT COUNT(*) quantidade
      FROM %table:ZZ1% ZZ1 
     WHERE ZZ1.%notdel%
     %exp:cWhere%
  EndSql
  
  if ZZ1TOT->( !eof() )
    nQuantidade := ZZ1TOT->quantidade
  endif

  ZZ1TOT->( dbCloseArea() )

Return nQuantidade


/*/{Protheus.doc} reqPerDay
  Retorna a quantidade de documentos por dia
  @type  Static Function
  @author Leonardo Freitas
  @since 15/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function reqPerDay(cContent)
  local jContent    := JsonObject():New()
  local jResponse   := JsonObject():New()
  local jAxios      := JsonObject():New()
  local aDados      := {}
  local aHoras      := {}
  local aConcluidos := {}
  local aAbertos    := {}
  local aErros     := {}
  local nMaxRange   := 0
  local i

  jContent:fromJson(cContent)

  aDate := strtokarr2(jContent["date"], "-")

  for i := 0 to 23
    aAdd(aHoras, strzero(i, 2) + "h")    
    aAdd(aConcluidos, 0)    
    aAdd(aAbertos, 0)    
    aAdd(aErros, 0)    
  next i

    
  cQuery := "    SELECT substring(ZZ1_HORA, 1 ,2) hora, "
  cQuery += "           ZZ1_STATUS "
  cQuery += "      FROM " + retSqlName("ZZ1") + " ZZ1  "
  cQuery += "     WHERE ZZ1_DATA = '" + aDate[1] + aDate[2] + aDate[3] + "' AND  "
  cQuery += "           ZZ1.D_E_L_E_T_ = ' ' "
  cQuery += "     ORDER BY substring(ZZ1_HORA, 1 ,2) "

  cQuery := ChangeQuery( cQuery )

  tcQuery cQuery new alias 'QRYPerDay'
    
  if QRYPerDay->( !EOF( ) )

    while QRYPerDay->( !EOF( ) )

      nPos := ascan(aHoras, {|x| x == QRYPerDay->hora + "h"})
      
      if nPos > 0
        Do Case
        Case QRYPerDay->ZZ1_STATUS == 'A'
          aAbertos[nPos] += 1
        Case QRYPerDay->ZZ1_STATUS == 'P'
          aConcluidos[nPos] += 1
        Case QRYPerDay->ZZ1_STATUS == 'E'
          aErros[nPos] += 1
        EndCase
      endif

      QRYPerDay->( dbSkip( ) )
    endDo

  endif
  QRYPerDay->( dbCloseArea( ) )

  jAbertos := JsonObject():new()
    jAbertos["label"] := "Abertos"
    jAbertos["data"] := aAbertos
    jAbertos["color"] := "green"
    aAdd(aDados, jAbertos)

  jConcluidos := JsonObject():new()
    jConcluidos["label"] := "Concluidos"
    jConcluidos["data"] := aConcluidos
    jConcluidos["color"] := "blue"
    aAdd(aDados, jConcluidos)

  jErros := JsonObject():new()
    jErros["label"] := "Erros"
    jErros["data"] := aErros
    jErros["color"] := "red"
    aAdd(aDados, jErros)

  //Pega a maior quantidade de registros para formar o maxRange do Axios
  for i := 1 to len(aAbertos)
    if aAbertos[i] > nMaxRange
      nMaxRange := aAbertos[i]
    endif 
  next i

  jAxios["maxRange"] := nMaxRange + (nMaxRange / 2) //a partir da maior quantidade de registros, acrescenta mais 20%
  jAxios["gridLines"] := 8

  jResponse["axis"] := jAxios
  jResponse["axisX"] := aHoras
  jResponse["data"] := aDados
  
Return jResponse:toJson()

/*/{Protheus.doc} rqPerMonth
  Retorna a quantidade de documentos por mÃªs
  @type  Static Function
  @author Leonardo Freitas
  @since 15/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function rqPerMonth(cContent)
  local jContent := JsonObject():new()
  local jResponse := JsonObject():new()
  local jAxios := JsonObject():new()
  local aDados := {}
  local aDias := {}
  local aConcluidos := {}
  local aAbertos := {}
  local aErros := {}
  local i
  local nMaxRange := 0

  jContent:fromJson(cContent)

  aDate := strtokarr2(jContent["date"], "/")

  nLastDay := last_day(sToD(aDate[2] + aDate[1] + "01"))

  for i := 1 to nLastDay
    aAdd( aDias, strzero(i, 2) )    
    aAdd( aConcluidos, 0 )    
    aAdd( aAbertos, 0 )    
    aAdd( aErros, 0 )    
  next i

  cQuery := " SELECT substring(ZZ1_DATA, 7, 2) dia, "
  cQuery +=        " ZZ1_STATUS, "
  cQuery +=        " count(*) quantidade "
  cQuery +=   " FROM " + retSqlName("ZZ1") + " zz1 "
  cQuery +=  " WHERE substring(ZZ1_DATA, 1, 6) = '" + aDate[2] + aDate[1] + "'  "
  cQuery += " AND D_E_L_E_T_ = ' ' "
  cQuery +=  " GROUP BY substring(ZZ1_DATA, 7, 2), "
  cQuery +=   " ZZ1_STATUS "
  cQuery += " ORDER BY substring(ZZ1_DATA, 7, 2) "

  cQuery := ChangeQuery( cQuery )
  tcQuery cQuery new alias 'QRYPerMonth'

  conout(cQuery)

  if QRYPerMonth->( !EOF( ) )

    while QRYPerMonth->( !EOF( ) )

      nPos := ascan(aDias, {|x| x == QRYPerMonth->dia})

      if QRYPerMonth->ZZ1_STATUS == 'A'
        aAbertos[nPos] := QRYPerMonth->quantidade
      elseif QRYPerMonth->ZZ1_STATUS == 'P'
        aConcluidos[nPos] := QRYPerMonth->quantidade
      elseif QRYPerMonth->ZZ1_STATUS == 'E'
        aErros[nPos] := QRYPerMonth->quantidade
      endif
      QRYPerMonth->( dbSkip( ) )
    endDo

  endif
  QRYPerMonth->( dbCloseArea( ) )

  jAbertos := JsonObject():new()
    jAbertos["label"] := "Abertos"
    jAbertos["data"] := aAbertos
    jAbertos["color"] := "green"
    aAdd(aDados, jAbertos)

  jConcluidos := JsonObject():new()
    jConcluidos["label"] := "Concluidos"
    jConcluidos["data"] := aConcluidos
    jConcluidos["color"] := "blue"
    aAdd(aDados, jConcluidos)

  jErros := JsonObject():new()
    jErros["label"] := "Erros"
    jErros["data"] := aErros
    jErros["color"] := "red"
    aAdd(aDados, jErros)


  //Pega a maior quantidade de registros para formar o maxRange do Axios
  for i := 1 to len(aAbertos)
    if aAbertos[i] > nMaxRange
      nMaxRange := aAbertos[i]
    endif 
  next i
  for i := 1 to len(aConcluidos)
    if aConcluidos[i] > nMaxRange
      nMaxRange := aConcluidos[i]
    endif 
  next i
  for i := 1 to len(aErros)
    if aErros[i] > nMaxRange
      nMaxRange := aErros[i]
    endif 
  next i

  jAxios["maxRange"] := nMaxRange + (nMaxRange / 2) //a partir da maior quantidade de registros, acrescenta mais 20%
  jAxios["gridLines"] := 8

  jResponse["axis"] := jAxios
  jResponse["axisX"] := aDias
  jResponse["data"] := aDados
  
Return jResponse:toJson()

/*/{Protheus.doc} rqPerYear
  Retorna a quantidade de documentos por ano
  @type  Static Function
  @author user
  @since 15/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function rqPerYear(cContent)
  local jContent := JsonObject():new()
  local jResponse := JsonObject():new()
  local jAxios := JsonObject():new()
  local aDados := {}
  local aMeses := {}
  local aConcluidos := {}
  local aAbertos := {}
  local aErros := {}
  local i
  local nMaxRange := 0

  jContent:fromJson(cContent)

  for i := 1 to 12
    aAdd( aMeses, strzero(i, 2) )    
    aAdd( aAbertos, 0 )    
    aAdd( aConcluidos, 0 )    
    aAdd( aErros, 0 )    
  next i

  cQuery := " SELECT substring(ZZ1_DATA, 5, 2) mes, "
  cQuery +=        " ZZ1_STATUS, "
  cQuery +=        " count(*) quantidade "
  cQuery +=   " FROM " + retSqlName("ZZ1")
  cQuery +=  " WHERE substring(ZZ1_DATA, 1, 4) = '" + jContent["date"] + "'  "
  cQuery += " AND D_E_L_E_T_ = ' ' "
  cQuery +=  " GROUP BY substring(ZZ1_DATA, 5, 2), "
  cQuery +=   " ZZ1_STATUS "
  cQuery += " ORDER BY substring(ZZ1_DATA, 5, 2) "

  cQuery := ChangeQuery( cQuery )
  tcQuery cQuery new alias 'QRYPerYear'

  if QRYPerYear->( !EOF( ) )

    while QRYPerYear->( !EOF( ) )

      nPos := ascan(aMeses, {|x| x == QRYPerYear->mes})

      if QRYPerYear->ZZ1_STATUS == 'A'
        aAbertos[nPos] := QRYPerYear->quantidade
      elseif QRYPerYear->ZZ1_STATUS == 'P'
        aConcluidos[nPos] := QRYPerYear->quantidade
      elseif QRYPerYear->ZZ1_STATUS == 'E'
        aErros[nPos] := QRYPerYear->quantidade
      endif
      QRYPerYear->( dbSkip( ) )
    endDo

  endif
  QRYPerYear->( dbCloseArea( ) )

  jAbertos := JsonObject():new()
    jAbertos["label"] := "Abertos"
    jAbertos["data"] := aAbertos
    jAbertos["color"] := "green"
    aAdd(aDados, jAbertos)

  jConcluidos := JsonObject():new()
    jConcluidos["label"] := "Concluidos"
    jConcluidos["data"] := aConcluidos
    jConcluidos["color"] := "blue"
    aAdd(aDados, jConcluidos)

  jErros := JsonObject():new()
    jErros["label"] := "Erros"
    jErros["data"] := aErros
    jErros["color"] := "red"
    aAdd(aDados, jErros)


  
  //Pega a maior quantidade de registros para formar o maxRange do Axios
  for i := 1 to len(aAbertos)
    if aAbertos[i] > nMaxRange
      nMaxRange := aAbertos[i]
    endif 
  next i
  for i := 1 to len(aConcluidos)
    if aConcluidos[i] > nMaxRange
      nMaxRange := aConcluidos[i]
    endif 
  next i
  for i := 1 to len(aErros)
    if aErros[i] > nMaxRange
      nMaxRange := aErros[i]
    endif 
  next i

  jAxios["maxRange"] := nMaxRange + (nMaxRange / 2) //a partir da maior quantidade de registros, acrescenta mais 20%
  jAxios["gridLines"] := 8

  jResponse["axis"] := jAxios
  jResponse["axisX"] := aMeses
  jResponse["data"] := aDados
  
Return jResponse:toJson()

/*/{Protheus.doc} rqPerYears
  Retorna a quantidade de documentos de todos os anos
  @type  Static Function
  @author user
  @since 15/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function rqPerYears(cContent)
  local jContent := JsonObject():new()
  local jResponse := JsonObject():new()
  local jAxios := JsonObject():new()
  local aDados := {}
  local aYears := {}
  local aConcluidos := {}
  local aAbertos := {}
  local aErros := {}
  local i
  local nMaxRange := 0

  jContent:fromJson(cContent)


  cQuery := " SELECT substring(ZZ1_DATA, 1, 4) year, "
  cQuery +=        " ZZ1_STATUS , "
  cQuery +=        " count(*) quantidade "
  cQuery +=   " FROM " + retSqlName("ZZ1")
  cQuery +=  " WHERE D_E_L_E_T_ = ' '  "
  
  cQuery +=  " GROUP BY substring(ZZ1_DATA, 1, 4), "
  cQuery +=   " ZZ1_STATUS "
  cQuery += " ORDER BY substring(ZZ1_DATA, 1, 4) "

  cQuery := ChangeQuery( cQuery )
  tcQuery cQuery new alias 'QRYPYears'

  if QRYPYears->( !EOF( ) )

    while QRYPYears->( !EOF( ) )

      nPos := ascan(aYears, {|x| x == QRYPYears->year})

      if nPos <= 0
        aadd(aYears, QRYPYears->year)
        aadd(aConcluidos, 0)
        aadd(aAbertos, 0)
        aadd(aErros, 0)

        nPos := len(aYears)
      endif

      if QRYPYears->ZZ1_STATUS == 'A'
        aAbertos[nPos] := QRYPYears->quantidade
      elseif QRYPYears->ZZ1_STATUS == 'P'
        aConcluidos[nPos] := QRYPYears->quantidade
      elseif QRYPYears->ZZ1_STATUS == 'E'
        aErros[nPos] := QRYPYears->quantidade
      endif
      QRYPYears->( dbSkip( ) )
    endDo

  endif
  QRYPYears->( dbCloseArea( ) )

  jAbertos := JsonObject():new()
    jAbertos["label"] := "Abertos"
    jAbertos["data"] := aAbertos
    jAbertos["color"] := "green"
    aAdd(aDados, jAbertos)
  
  jConcluidos := JsonObject():new()
    jConcluidos["label"] := "Concluidos"
    jConcluidos["data"] := aConcluidos
    jConcluidos["color"] := "blue"
    aAdd(aDados, jConcluidos)

  jErros := JsonObject():new()
    jErros["label"] := "Erros"
    jErros["data"] := aErros
    jErros["color"] := "red"
    aAdd(aDados, jErros)


  //Pega a maior quantidade de registros para formar o maxRange do Axios
  for i := 1 to len(aAbertos)
    if aAbertos[i] > nMaxRange
      nMaxRange := aAbertos[i]
    endif 
  next i
  for i := 1 to len(aConcluidos)
    if aConcluidos[i] > nMaxRange
      nMaxRange := aConcluidos[i]
    endif 
  next i
  for i := 1 to len(aErros)
    if aErros[i] > nMaxRange
      nMaxRange := aErros[i]
    endif 
  next i

  jAxios["maxRange"] := nMaxRange + (nMaxRange / 2) //a partir da maior quantidade de registros, acrescenta mais 20%
  jAxios["gridLines"] := 8

  jResponse["axis"] := jAxios
  jResponse["axisX"] := aYears
  jResponse["data"] := aDados
  
Return jResponse:toJson()

/*/{Protheus.doc} getAllDocs
  Retorna todos os documentos
  @type  Static Function
  @author Leonardo Freitas
  @since 16/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function getAllDocs(cContent)
  Local cAlias_ := "QRY"
  Local aDados := {}
  Local oDados := JsonObject():new()
  local jContent := JsonObject():new()
  Local nCount := 0
  Local nStart := 1
  Local nReg := 0
  local cFilters := ""
  Local cWhere := ""
  local i := 0


  jContent:fromJson(cContent)

  if jContent:hasProperty("status")
    if !empty(jContent["status"])
      cWhere += " AND ZZ1_STATUS = '" + upper(alltrim(jcontent["status"])) +  "' "
    endif
  endif

  if jContent:hasProperty("filters")

    if jContent["filters"]:hasProperty("chave")
      cFilters += " AND ZZ1_CHAVE like '%" + alltrim(jContent["filters"]["chave"]) + "%' "
    endif

    if jContent["filters"]:hasProperty("tomador") 
      cFilters += " AND ZZ1_CGC like '%" + alltrim(jContent["filters"]["tomador"]) + "%' "
    endif

    if jContent["filters"]:hasProperty("dataDe") .or. jContent["filters"]:hasProperty("dataAte")

      if !empty(jContent["filters"]["dataDe"]) .and. !empty(jContent["filters"]["dataAte"])
        cFilters += " AND ZZ1_DATA between '" + strtran(jContent["filters"]["dataDe"], '-', '') + "' AND '" + strtran(jContent["filters"]["dataAte"], '-', '') + "' "
      elseif !empty(jContent["filters"]["dataDe"])
        cFilters += " AND ZZ1_DATA >= '" + strtran(jContent["filters"]["dataDe"], '-', '') + "' "
      elseif !empty(jContent["filters"]["dataAte"])
        cFilters += " AND ZZ1_DATA <= '" + strtran(jContent["filters"]["dataAte"], '-', '') + "' "
      endif 
    else
       cFilters += " AND ZZ1_DATA between '" + dtos(FirstDate(ddatabase)) + "' AND '" + dtos(LastDate(ddatabase)) + "' "
    endif

    if jContent["filters"]:hasProperty("numeroDe") .or. jContent["filters"]:hasProperty("numeroAte")

      if !empty(jContent["filters"]["numeroDe"]) .and. !empty(jContent["filters"]["numeroAte"])
        cFilters += " AND f2_doc between '" + alltrim(jContent["filters"]["numeroDe"]) + "' and '" + alltrim(jContent["filters"]["numeroAte"]) + "' "
      elseif !empty(jContent["filters"]["numeroDe"])
        cFilters += " AND f2_doc >= '" + alltrim(jContent["filters"]["numeroDe"]) + "' "
      elseif !empty(jContent["filters"]["numeroAte"])
        cFilters += " AND f2_doc <= '" + alltrim(jContent["filters"]["numeroAte"]) + "' "
      endif 
    endif

    if jContent["filters"]:hasProperty("serieDe") .or. jContent["filters"]:hasProperty("serieAte")

      if !empty(jContent["filters"]["serieDe"]) .and. !empty(jContent["filters"]["serieAte"])
        cFilters += " AND f2_serie between '" + upper(alltrim(jContent["filters"]["serieDe"])) + "' and '" + upper(alltrim(jContent["filters"]["serieAte"])) + "' "
      elseif !empty(jContent["filters"]["serieDe"])
        cFilters += " AND f2_serie >= '" + upper(alltrim(jContent["filters"]["serieDe"])) + "' "
      elseif !empty(jContent["filters"]["serieAte"])
        cFilters += " AND f2_serie <= '" + upper(alltrim(jContent["filters"]["serieAte"])) + "' "
      endif

    endif

    if jContent["filters"]:hasProperty("tipo")
      if len(jContent["filters"]["tipo"]) > 0

        for i := 1 to len(jContent["filters"]["tipo"])
          if i == 1
            cFilters += " AND ZZ1_ACAO in ( '" + upper(alltrim(jContent["filters"]["tipo"][i])) +  "' "
          else
            cFilters += " , '" + upper(alltrim(jContent["filters"]["tipo"][i])) +  "' "
          endif
          
        next i 

        cFilters += " ) "

      endif
    endif

    if jContent["filters"]:hasProperty("status")
      if len(jContent["filters"]["status"]) > 0

        for i := 1 to len(jContent["filters"]["status"])
          if i == 1
            cFilters += " AND ZZ1_STATUS in ( '" + upper(alltrim(jContent["filters"]["status"][i])) +  "' "
          else
            cFilters += " , '" + upper(alltrim(jContent["filters"]["status"][i])) +  "' "
          endif
          
        next i

        cFilters += " ) "

      endif
    endif
  endif

  cWhere := "% " + cFilters + " %"

  BeginSql alias cAlias_
    SELECT zz1.R_E_C_N_O_ recno, zz1.*, f2.*
      FROM %table:ZZ1% zz1 
      LEFT JOIN %table:SF2% f2 ON f2.f2_filial = zz1.zz1_filcte 
       AND f2.f2_doc = zz1.ZZ1_NUMCTE
       AND f2.f2_serie = zz1.zz1_SERCTE 
       AND f2.f2_cliente = ZZ1.ZZ1_CLIENT 
       AND f2.f2_loja = ZZ1.ZZ1_LOJA 
       AND f2.D_E_L_E_T_ = ' '
     WHERE zz1.D_E_L_E_T_ = ' '
     %exp:cWhere%
     ORDER BY ZZ1.R_E_C_N_O_ desc
  EndSql

  if ( cAlias_ )->( !eof() )
    //Identifica a quantidade de registro
    count to nRecord 

    if jContent["page"] > 1 
      nStart := ( ( jContent["page"] - 1 ) * jContent["pageSize"] ) + 1
      nReg := nRecord - nStart + 1
    else 
      nReg := nRecord
    endif

    //Posiciona na primeira linha do registro
    ( cAlias_ )->( dbGoTop() )

    if nReg > jContent["pageSize"]
      oDados['hasNext'] := .T.
      oDados['nextPage'] := jContent["page"] + 1
    else 
      oDados['hasNext'] := .F.
    Endif 

  else
    oDados['hasNext'] := .F.
  endif

  while ( cAlias_ )->( !EOF( ) )

    nCount++

    if nCount >= nStart 

      oJson := JsonObject():new()
      oJson['recno'] := ( cAlias_ )->recno
      oJson['codigo'] := ( cAlias_ )->ZZ1_CODIGO
      oJson['status'] := ( cAlias_ )->ZZ1_STATUS
      oJson['acao'] := alltrim(( cAlias_ )->ZZ1_ACAO)
      oJson['filial'] := alltrim(( cAlias_ )->ZZ1_FILCTE)
      oJson['data'] := dtoc(stod(( cAlias_ )->ZZ1_DATA))
      oJson['hora'] := ( cAlias_ )->ZZ1_HORA
      oJson['chave'] := alltrim(( cAlias_ )->ZZ1_CHAVE)
      oJson['documento'] := alltrim(( cAlias_ )->ZZ1_NUMCTE)
      oJson['serie'] := alltrim(( cAlias_ )->ZZ1_SERCTE)
      oJson['details'] := {}

      aadd(aDados, oJson)

      if len(aDados) >= jContent["pageSize"] 
        exit
      endif
    endif

    ( cAlias_ )->( dbSkip( ) )   
  endDo 
  ( cAlias_ )->( dbCloseArea() )

  oDados["data"] := aDados

Return oDados:toJson()

/*/{Protheus.doc} ExcluirDoc(cContent)
  (long_description)
  @type  Static Function
  @author user
  @since 22/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function ExcluirDoc(cContent)
  
  local jContent := JsonObject():new()
  
  jContent:fromJson(cContent)

  ZZ1->( dbSetOrder( 1 ) )
  ZZ1->( dbGoTo( jContent["recno"] ) )

  Begin Transaction

    recLock("ZZ1", .F.)
      ZZ1->(dbDelete())
    ZZ1->( MsUnLock() )
  
  end transaction

Return ""

/*/{Protheus.doc} baixaDocto
  (long_description)
  @type  Static Function
  @author user
  @since 22/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function baixaDocto(cContent)
  local jContent := JsonObject():new()
  local cCaminho := ""
  local oJson := JsonObject():new()

  jContent:fromJson(cContent)

  ZZ1->( dbSetOrder( 1 ) )
  ZZ1->( dbGoTo( jContent["recno"] ) )

  cCaminho := "c:\temp\" + alltrim(ZZ1->ZZ1_CHAVE) + ".xml"

  //Se o arquivo já existir, fará a exclusão
    If File(cCaminho)
        FErase(cCaminho)
    EndIf

  lReturn := memoWrite(cCaminho, ZZ1->ZZ1_XML)

  if lReturn 
    oJson["status"] := .T.
    oJson["message"] := "Arquivo salvo em: " + cCaminho
  else 
    oJson["status"] := .F.
    oJson["message"] := "Ocorreu um erro ao salvar o arquivo no caminho: " + cCaminho
  endif

Return oJson:toJson()

/*/{Protheus.doc} reproDocto
  (long_description)
  @type  Static Function
  @author user
  @since 24/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function reproDocto(cContent)

  local jContent := JsonObject():new()
  local cRetorno := ""

  jContent:fromJson(cContent)

  ZZ1->( dbSetOrder( 1 ) )
  ZZ1->( dbGoTo( jContent["recno"] ) )

  cRetorno := u_LOSF001D(ZZ1->(recno()), ZZ1->ZZ1_STATUS)

Return "Processamento realizado com sucesso!"

/*/{Protheus.doc} getLog
  (long_description)
  @type  Static Function
  @author user
  @since 30/10/2025
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function getLog(cContent)
  Local jContent := JsonObject():new()
  Local oData := JsonObject():new()

  jContent:fromJson(cContent)

  cCodigo := jContent["codigo"]

  BeginSql alias 'QRY'
    SELECT zz2.R_E_C_N_O_ recno
      FROM %table:ZZ2% zz2 
     WHERE zz2.ZZ2_codzz1 = %exp:cCodigo% AND 
           zz2.%notdel% AND 
           ROWNUM = 1
     ORDER BY R_E_C_N_O_ desc
  Endsql

  if QRY->( !EOF() )

    ZZ2->( dbSetOrder(1) )
    ZZ2->( dbGoTo(QRY->recno) )

    oData["data"] := dToc(ZZ2->ZZ2_DTPROS)
    oData["hora"] := alltrim(ZZ2->ZZ2_HRPROS)
    oData["detalhe"] := ZZ2->ZZ2_LOG
  endif 
  QRY->( dbCloseArea() )  

Return oData:toJson()
