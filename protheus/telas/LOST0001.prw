#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "topconn.ch"
#include "tbicode.ch"
#include "tbiconn.ch"

/*/{Protheus.doc} LOST0001
Tela de integração de notas CTE GW
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
      oWebChannel:AdvPLToJS('getQuantityDocuments', cValToChar(qtdAllDocs()))
    Case cType == 'getQuantityIntegrated'
      oWebChannel:AdvPLToJS('getQuantityIntegrated', cValToChar(qtdAllInte()))
    Case cType == 'getQuantityErrors'
      oWebChannel:AdvPLToJS('getQuantityErrors', cValToChar(qtdAllErrs()))
    Case cType == 'chartDocumentsPerDay'
      oWebChannel:AdvPLToJS('chartDocumentsPerDay', cValToChar(reqPerDay(cContent)))
    Case cType == 'chartDocumentsPerMonth'
      oWebChannel:AdvPLToJS('chartDocumentsPerMonth', cValToChar(rqPerMonth(cContent)))
    Case cType == 'chartDocumentsPerYear'
      oWebChannel:AdvPLToJS('chartDocumentsPerYear', cValToChar(rqPerYear(cContent)))
    Case cType == 'chartDocumentsPerYears'
      oWebChannel:AdvPLToJS('chartDocumentsPerYears', cValToChar(rqPerYears(cContent)))
    Case cType == 'getDocuments'
      oWebChannel:AdvPLToJS('getDocuments', cValToChar(getAllDocs(cContent)))
  End

Return .T.

/*/{Protheus.doc} qtdAllDocs
  Retorna a quantidade total de documentos de integração
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
Static Function qtdAllDocs(param_name)

  Local nQuantidade := 0
  Local cAlias_ := "ZZ1"

  ( cAlias_ )->( dbsetorder( 1 ) )
  ( cAlias_ )->( dbGoTop( ) )
  count to nQuantidade

  ( cAlias_ )->( dbCloseArea() )

Return nQuantidade

/*/{Protheus.doc} qtdAllInte
  Retorna a quantidade de CTE integradas do GW
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
Static Function qtdAllInte(param_name)

  Local nQuantidade := 0

  BeginSql alias 'QRYAllInte'
    SELECT count(*) quantidade
      FROM %table:ZZ1% ZZ1
     WHERE ZZ1.ZZ1_STATUS = 'F' AND 
           ZZ1.%notdel%
  endSql

  if QRYAllInte->( !EOF( ) )
    nQuantidade := QRYAllInte->quantidade
  endif 
  QRYAllInte->( dbCloseArea( ) )

Return nQuantidade

/*/{Protheus.doc} qtdAllErrs
  Retorna a quantidade de erros de integração de CTE do GW
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
Static Function qtdAllErrs()

  Local nQuantidade := 0

  BeginSql alias 'AllErrs'
    SELECT count(*) quantidade
      FROM %table:ZZ1% ZZ1
     WHERE ZZ1.ZZ1_STATUS = 'E' AND 
           ZZ1.%notdel%
  endSql

  if AllErrs->( !EOF( ) )
    nQuantidade := AllErrs->quantidade
  endif 
  AllErrs->( dbCloseArea( ) )

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
        Case QRYPerDay->ZZ1_STATUS == 'F'
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
    jConcluidos["label"] := encodeutf8("Concluídos")
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
  Retorna a quantidade de documentos por mês
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

  cQuery := " SELECT substring(ZZ1_DATA, 5, 2) dia, "
  cQuery +=        " ZZ1_STATUS, "
  cQuery +=        " count(*) quantidade "
  cQuery +=   " FROM " + retSqlName("ZZ1") + " zz1 "
  cQuery +=  " WHERE substring(ZZ1_DATA, 1, 6) = '" + aDate[2] + aDate[1] + "'  "
  cQuery += " AND D_E_L_E_T_ = ' ' "
  cQuery +=  " GROUP BY substring(ZZ1_DATA, 5, 2), "
  cQuery +=   " ZZ1_STATUS "
  cQuery += " ORDER BY substring(ZZ1_DATA, 5, 2) "

  cQuery := ChangeQuery( cQuery )
  tcQuery cQuery new alias 'QRYPerMonth'

  conout(cQuery)

  if QRYPerMonth->( !EOF( ) )

    while QRYPerMonth->( !EOF( ) )

      nPos := ascan(aDias, {|x| x == QRYPerMonth->dia})

      if QRYPerMonth->ZZ1_STATUS == 'A'
        aAbertos[nPos] := QRYPerMonth->quantidade
      elseif QRYPerMonth->ZZ1_STATUS == 'F'
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
    jConcluidos["label"] := encodeutf8("Concluídos")
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
      elseif QRYPerYear->ZZ1_STATUS == 'F'
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
    jConcluidos["label"] := encodeutf8("Concluídos")
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
      elseif QRYPYears->ZZ1_STATUS == 'F'
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
    jConcluidos["label"] := encodeutf8("Concluídos")
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
  aDados := {}
  oDados := JsonObject():new()

  BeginSql alias 'QRY'
    SELECT *
      FROM %table:ZZ1% zz1 
     WHERE zz1.D_E_L_E_T_ = ' '
  EndSql

  while QRY->( !EOF( ) )

    oJson := JsonObject():new()
    oJson['status'] := QRY->ZZ1_STATUS
    oJson['acao'] := alltrim(QRY->ZZ1_ACAO)
    oJson['filial'] := alltrim(QRY->ZZ1_FILCTE)
    oJson['data'] := stod(QRY->ZZ1_DATA)
    oJson['hora'] := stod(QRY->ZZ1_HORA)
    oJson['chave'] := alltrim(QRY->ZZ1_CHAVE)
    oJson['documento'] := alltrim(QRY->ZZ1_NUMCTE)
    oJson['serie'] := alltrim(QRY->ZZ1_SERCTE)
    oJson['details'] := {}

  aadd(aDados, oJson)
/*
    status: 'available',
    filial: '01',
    data: '14/10/2025',
    tipo: 'CT-e',
    documento: '123456789',
    serie: 'CTE',
    detail: [
      {
        package: 'Basic',
        tour: 'City tour by public bus and visit to the main museums.',
        time: '20:10:10',
        distance: '1000'
      },
    ]
*/
    QRY->( dbSkip( ) )   
  endDo 
  QRY->( dbCloseArea() )

  oDados["data"] := aDados

Return oDados:toJson()
