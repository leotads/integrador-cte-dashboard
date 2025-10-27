#INCLUDE "protheus.CH"

class Crud

data cAlias
data nIndex
data nRecno
data aData
data aChilds
data lValid
data lInicia
data cChave
data cSeek
data cExecAuto
data cMyId
data lDeleted 
data cWhile

method New(cAlias, nRecno, nIndex, lInicializa) constructor
method save()
method persist(nOpc)  
method del()
method set(cCampo, xVal)
method get(cCampo)
method getCrud(cAlias, nI)
method valid(cCampo)
method copy()
method replace(cAlias, xVal)
method isDeleted()

method setMyId()
method getMyId()

method addChild()
method getChild(cAlias)
method getChildData(cAlias)
method getLenChild(cAlias)

method addLine(cAlias)
method delLine(cAlias, n)
method undLine(cAlias, n)
method opeLine(cAlias, n, lFlag)
method setLine(cAlias, nLin)
method getLine(cAlias)
method isLineDeleted()

method setExecAuto(cExecAuto)
method execAuto(nOpc, lExibe, aAlias)
method execSave(lExibe, aAlias)
method execDel(lExibe, aAlias)

endClass


// -- ********************************
// -- Instancia um novo objeto de cpo
// -- ********************************
method new(cAlias_, nRecno, nIndex, lInicializa) class Crud
local bError 	:= ErrorBlock({|e| e:Description + e:ErrorStack})
local aArea		:= getArea()
local aData		:= {}
local xValCampo, cCampo, cAlias, nX

private Inclui, Altera, Exclui  //compatibilização com inicializadores padrões

default cAlias_		:= {}
default nRecno 		:= 0
default nIndex			:= 1
default lInicializa  := .T.

if valType(cAlias_) == "A"
	if len(cAlias_) <= 0
		return .F.
	else
		cAlias := cAlias_[1]
	endif
elseif valType(cAlias_) == "C"
	cAlias := cAlias_
else
	return .F.
endif

dbSelectArea(cAlias)
dbSetOrder(nIndex)

if nRecno > 0
	dbGoTo(nRecno)
	Inclui := .F.
	Altera := .T.
	Exclui := .F.
else
	Inclui := .T.
	Altera := .F.
	Exclui := .F.
endif

SX3->(dbSetOrder(1))
SX3->(dbSeek(cAlias))

while SX3->X3_ARQUIVO == cAlias

	cCampo		:= SX3->X3_CAMPO
	xValCampo	:= nil
		
	//se for alteração/exclusão
	if nRecno > 0 .and. (SX3->X3_CONTEXT <> "V" .or. "_FILIAL" $ cCampo)
		xValCampo := &(cCampo)
	//se for inclusão
	else
		if "_FILIAL" $ cCampo
			xValCampo := xFilial(cAlias)
		elseif lInicializa .and. !empty(SX3->X3_RELACAO) .AND. ! 'GDFIELDGET' $ Upper(SX3->X3_RELACAO) 			
			xValCampo := eval(&("{||" + SX3->X3_RELACAO + "}"))
		else
			if SX3->X3_TIPO == "C"
				xValCampo	:= space(SX3->X3_TAMANHO)
			elseif SX3->X3_TIPO == "D"
				xValCampo	:= ctod("//")
			elseif SX3->X3_TIPO == "N"
				xValCampo	:= 0
			elseif SX3->X3_TIPO == "L"
				xValCampo	:= .F.
			endif
		endif			
	endif

	//Cria as variaveis de memória
	_SetOwnerPrvt(allTrim(cCampo), xValCampo)

	//Adiciona campo no objeto
	aAdd(aData, {cCampo, xValCampo, nil})
	
	SX3->(dbSkip())
endDo

ErrorBlock(bError)

::aData		:= aClone(aData)
::nRecno		:= nRecno
::cAlias		:= cAlias
::aChilds	:= {}
::nIndex		:= nIndex
::lValid		:= .F.
::lInicia	:= lInicializa
::cSeek		:= (cAlias)->(&(indexkey()))
::lDeleted	:= .F.
::cWhile		:= indexkey()

restArea(aArea)

return self


// -- ****************************************************
// -- Método que retorna uma cópia do objeto sem o recNo
// usado para fins de copiar um registro
// -- ****************************************************
method copy() class Crud
local i, j, nX, nY

//Limpa o recno do crud
::nRecno := 0

//Limpa os recnos dos childs
nX := len(::aChilds)
for i := 1 to nX
	nY := len(::aChilds[i]:aData)
	for j := 1 to nY
		::aChilds[i]:aData[j]:copy()
	next
next

return self


// -- ****************************************************
// -- Método para salvar (inclusão ou edição ) do registro
// -- ****************************************************
method save(lSaveChilds) class Crud
local aArea := getArea()
local aArea2:= (::cAlias)->(getArea())
local i, j, nX, nY  

default lSaveChilds := .T.

//Salva o crud
::persist(1)

//Restaura a area
restArea(aArea)
(::cAlias)->(restArea(aArea2))

//Salva os childs
if lSaveChilds
	nX := len(::aChilds)
	for i := 1 to nX
		nY := len(::aChilds[i]:aData)
		for j := 1 to nY
			::aChilds[i]:aData[j]:save()
		next
	next
endif

return .T.


// -- ************************************
// -- Método para apagar registro 
// -- ************************************
method del() class Crud
local i, nX, j, nY

//Apaga o crud
::persist(2)

//Apaga os childs
nX := len(::aChilds)
for i := 1 to nX
	nY := len(::aChilds[i]:aData)
	for j := 1 to nY
		::aChilds[i]:aData[j]:del()
	next
next

return .T.

// -- Persiste o registro - inclusão, alteração ou exclusão
method persist(nOpc) class crud
local lTipo

if empty(::cAlias)
	return .F.
endif

//Se houver recno no objeto, seta o registro
lTipo := ::nRecno <= 0
if !lTipo
	(::cAlias)->(dbGoTo(::nRecno))
	if (::cAlias)->(eof())
		return .F.
	endif
endif

//Se o registro estiver apagado...
if ::lDeleted
	//Se for inclusão, apenas ingnora o registro
	if lTipo
		return .T.	
	//Se for alteração, exclue o registro
	else
		recLock(::cAlias, lTipo) 
		(::cAlias)->(dbDelete())
		(::cAlias)->(msUnlock())
		return .T.		
	endif
endif

//Salva os dados do alias
SX3->(dbSetOrder(2))

recLock(::cAlias, lTipo) 

if nOpc == 1
	for i := 1 to len(::aData)
		if SX3->(dbSeek(::aData[i][1])) .and. SX3->X3_CONTEXT <> "V"
			(::cAlias)->&(::aData[i][1]) := ::aData[i][2]
		endif
	next
	::nRecno := recNo()
elseif nOpc == 2
	(::cAlias)->(dbDelete())
endif

(::cAlias)->(msUnlock())

return


// -- ************************************
// -- Método para setar valor do campo
// -- ************************************
method set(cCampo, xVal, nI) class Crud
local n := 0
local j, cAlias, nX

default nI := 0

//Verifica qual o alias
n := at("_", cCampo)
	
if n == 3
	cAlias := "S" + cCampo
	n++
else
	cAlias := cCampo
endif
	
cAlias := left(cAlias, n - 1)

//Seta campo no cpo
if ::cAlias == cAlias
	n := aScan(::aData,{|x| allTrim(x[1]) == allTrim(cCampo)})
	
	if n > 0 
		//Pega valor do campo
		M->&(::aData[n][1]) := xVal
		//Verifica se deve validar, se sim, chama validação
		if !::lValid .or. ::valid(cCampo)
			//Se for caracter, preenche com espaço à direita
			if valType(xVal) == "C"
				xVal_ := padr(xVal, len(&(cAlias + "->" + cCampo)), " ")
				//Utilizo o xVal_ pois estava retornando nulo para os campos memo
				if !empty(xVal_) .and. len(xVal_) > len(xVal)
					xVal := xVal_
				endif
			endif
			::aData[n][2] := xVal
		endif
	endif

//Seta campo nos Childs
else
	oObj := ::getChild(cAlias)

	if nI == -1
		nX := len(oObj:aData)
		for nI := 1 to nX
			oObj:aData[nI]:set(cCampo, xVal)
			n := nI
		next	
	else	
		if nI == 0
			nI := oObj:nLine
		endif
		if nI == -2
			oObj:aData[oObj:nLine]:cMyID := xVal
		elseif len(oObj:aData) >= nI
			oObj:aData[nI]:set(cCampo, xVal)
			n := len(oObj:aData)
		else
			msgInfo("CRUD: Linha informada inválida.")
			n := 0
		endif
	endif
endif

return n > 0


// -- ************************************************************
// -- Método para setar valor do campo em todas as linhas do Child
// -- ************************************************************
method replace(cCampo, xVal) class Crud
return ::set(cCampo, xVal, -1)


// -- ********************************************
// -- Método retorna se Crud está ou não deletado
// -- ********************************************
method isDeleted() class Crud
return ::lDeleted


// -- ***********************************
// -- Método para retornar valor do campo
// -- ************************************
method get(cCampo, nI) class Crud
local n, j, oObj, xVal, cAlias
default nI := 0

//Verifica qual o alias
n := at("_", cCampo)
	
if n == 3
	cAlias := "S" + cCampo
	n++
else
	cAlias := cCampo
endif
	
cAlias := left(cAlias, n - 1)

//Busca no Cpo
if ::cAlias == cAlias
	n := aScan(::aData,{|x| allTrim(x[1]) == allTrim(cCampo)})
	
	if n > 0 
		xVal := ::aData[n][2]
	endif

//Busca nos Childs
else
	oObj := ::getChild(cAlias)
	if !empty(oObj) .and. nI == 0
		nI := oObj:nLine
	endif	
	if nI == -2
		xVal := oObj:aData[oObj:nLine]:cMyID
	elseif nI == 0
		xVal := Nil
	elseif len(oObj:aData) >= nI
		xVal := oObj:aData[nI]:get(cCampo)
	else
		msgInfo("CRUD: Linha informada inválida.")
	endif
endif

return xVal


// -- ***********************************
// -- Método para retornar o objeto crud 
// -- ***********************************
method getCrud(cAlias, nI) class crud
local oObj, oChild, i, nX

default cAlias := ""
default nI	:= 0

if empty(cAlias)
	oObj := self
else
	oChild := ::getChild(cAlias)
	if !empty(oChild)
		if nI == 0
			nI := oChild:getLine()
		endif
		nX := len(oChild:aData)
		if nI <= nX
			oObj := oChild:aData[nI]
		endif
	endif	
endif

return oObj


// -- *************************
// -- Seta a propriedade MyId
// -- *************************
method setMyId(cAlias, cId) class Crud
return ::set(cAlias, cId, -2)


// -- ****************************
// -- Recupera a propriedade MyId
// -- ****************************
method getMyId(cCampo, cId) class Crud
return ::get(cCampo, -2)


// -- ************************************
// -- Método para validar o valor do campo
// -- ************************************
method valid(cCampo) class Crud
local lRet := .T.

SX3->(dbSetOrder(2))
if SX3->(dbSeek(cCampo)) 
	if !empty(SX3->X3_VALID) 
		lRet := &(allTrim(SX3->X3_VALID))
	endif
	
	if lRet .and. !empty(SX3->X3_VLDUSER)
		lRet := &(allTrim(SX3->X3_VLDUSER))
	endif
endif
       
//Executa gatilhos ( [ nTipo: 1 - Enchoice; 2 - getDados ] [ nLin - linha do getDados ] [ cMacro - n usado ] [ oObj - objeto do Get] [ cField ] )
if lRet
	runTrigger(1, , , , allTrim(cCampo))
endif

return lRet


// -- ************************************
// -- Método para adicionar Child
// -- ************************************
method addChild(cAlias, nIndex, cWhile, cFilter) class crud
local lRet		:= .T.
local oChild, nX

default cAlias	:= ""
default nIndex	:= 1
default cWhile	:= ""
default cFilter:= ""

oChild := child():newChild(cAlias, nIndex, cWhile, cFilter, self)

aAdd(::aChilds, oChild)

return oChild


// -- ************************************
// -- Método para retornar um Child
// -- ************************************
method getChild(cAlias) class crud
local i, nX

nX := len(::aChilds)
for i := 1 to nX
	if ::aChilds[i]:cAlias == cAlias
		return ::aChilds[i]
	endif
next

return nil


// -- *****************************************
// -- Método para retornar o aData de um Child
// -- *****************************************
method getChildData(cAlias) class crud
return ::getChild(cAlias):aData


// -- ************************************
// -- Método para adicionar linha ao Child
// -- ************************************
method addLine(cAlias) class crud
local aChave, aCampos
local oObj, nT, oChild

n := ::getLine(cAlias)

oChild := ::getChild(cAlias)
aAdd(oChild:aData, crud():new(cAlias))

nT := len(oChild:aData)

::setLine(cAlias, nT)

//Preenche os campos de chava
aChave	:= strToArray(strTran(self:cWhile, "+", ","), ",")
aCampos	:= strToArray(strTran(oChild:cWhile, "+", ","), ",")

nX := len(aChave)
for i := 1 to nX
	if i <= len(aCampos)
		oChild:aData[nT]:set(aCampos[i], self:get(aChave[i]))
	endif
next

return nT > n


// -- ****************************************************************
// -- Método para recuperar ou marcar como deletada uma linha do Child
// -- ****************************************************************
method opeLine(cAlias, n, lFlag) class crud
default n := 0

if n == 0
	n := ::getLine(cAlias)
endif

::getChild(cAlias):aData[n]:lDeleted := lFlag

return .T.

// -- Marca linha do Child como deletada
method delLine(cAlias, n) class crud
return ::opeLine(cAlias, n, .T.)

// -- Recupera linha deletada do Child
method undLine(cAlias, n) class crud
return ::opeLine(cAlias, n, .F.)


// -- **********************************************
// -- Verifica se a linha do Child está deletada
// -- **********************************************
method isLineDeleted(cAlias, n) class crud
default n := 0

if n == 0
	n := ::getLine(cAlias)
endif

return ::getChild(cAlias):aData[n]:lDeleted


// -- ******************************************************
// -- Seta função de execAuto para operações de persistêcnia
// -- ******************************************************
method getLenChild(cAlias) class Crud
local i, nX, nT

nT := 0
nX := len(::aChilds)

for i := 1 to nX
	if ::aChilds[i]:cAlias == cAlias
		nT := len(::aChilds[i]:aData)
	endif
next

return nT


// -- ******************************************************
// -- Seta função de execAuto para operações de persistêcnia
// -- ******************************************************
method setExecAuto(cExecAuto) class Crud
return ::cExecAuto := cExecAuto


// -- ******************************************************
// -- Executa execAuto
// -- ******************************************************
method execAuto(nOpc, lExibe, aAlias) class Crud
local cExec 	:= ::cExecAuto
local aCabec 	:= {}
local aItem1	:= {}
local aItem2	:= {}
local cArray	:= ""
local cFilTmp	:= cFilAnt

default lExibe	:= .T.
default aAlias := {}

if empty(cExec)
	msgInfo("CRUD: ExecAuto não definido na rotina")
	return .F.
endif

//Pega a quantidade de alias
if !empty(aAlias)
	nX := len(aAlias) - 1 //desconsidera o cabecaçalho (-1)
else
	nX	:= len(::aChilds) 
endif

//Permite no máximo execautos com 2 arrays de itens
if nX > 2
	nX := 2
endif

//Ordena sx3
SX3->(dbSetOrder(2))
	
//Pega os dados os itens	
for i := 1 to nX
	aArray := {}
	
	nY := len(::aChilds[i]:aData)		
	for j := 1 to nY
		if ::aChilds[i]:aData:lDeleted
			loop
		endif
		nZ := len(::aChilds[i]:aData[j]:aData)
		aItem := {}
		for l := 1 to nZ			
			//Pega o valor do campo e trata de acordo com o tipo de dado
			//Seta apenas campos com conteúdo preenchido ou usados para evitar erros de execAuto
			if SX3->(dbSeek(::aChilds[i]:aData[j]:aData[l][1])) .and. x3Uso(SX3->X3_USADO)
				xVal := ::aChilds[i]:aData[j]:aData[l][2]
				if (valType(xVal) $ "C,D" .and. !empty(xVal)) .or. (valType(xVal) $ "N" .and. xVal > 0) .or. valType(xVal) $ "L,M"
					aAdd(aItem, ::aChilds[i]:aData[j]:aData[l])
				endif
			endif
		next
		//Adiciona ao array de itens
		aAdd(aArray, aItem)
	next
	
	if i == 1
		aItem1 := aClone(aArray)
	elseif i == 2
		aItem2 := aClone(aArray)
	endif	
next

//Array com dados do cabeçalho.
//Ignora os campos em branco para evitar validações que não desconsideram os campos em branco.
nY := len(::aData)
aArray := {}
for i := 1 to nY

	//Seta a filial do sistema na filial do registro
	if "_FILIAL" $ ::aData[i][1]
		cFilAnt := ::aData[i][2]
	endif

	//Pega o valor do campo e trata de acordo com o tipo de dado
	//Seta apenas campos com conteúdo preenchido para evitar erros de execAuto
	if SX3->(dbSeek(::aChilds[i]:aData[j]:aData[l][1])) .and. x3Uso(SX3->X3_USADO)
		xVal := ::aData[i][2]
		if (valType(xVal) $ "C,D" .and. !empty(xVal)) .or. (valType(xVal) $ "N" .and. xVal > 0) .or. valType(xVal) $ "L,M"
			aAdd(aArray, ::aData[i])
		endif
	endif
next

aCabec := aClone(aArray)

//Executa o execauto
lMsErroAuto := .F.
if nX == 0
	bBlock 	:= &("{|x,y|" +  cExec + "(x,y)}")
	msExecAuto(bBlock,aCabec,nOpc)	
elseif nX == 1
	bBlock 	:= &("{|x,y,z|" +  cExec + "(x,y,z)}")
	msExecAuto(bBlock,aCabec,aItem1,nOpc)
elseif nX == 2

endif

//Retorna a filial do sistema setada anteriormente
cFilAnt := cFilTmp

if lMsErroAuto
	mostraErro()
endif

return !lMsErroAuto

// -- Chama o execAuto para salvar ou alterar
method execSave(lExibe, aAlias) class crud
local nOpc := 3

if ::nRecno > 0
	nOpc := 4
endif

return ::execAuto(nOpc, lExibe, aAlias)

// -- Chama o execAuto para apagar
method execDel(lExibe, aAlias) class crud
local nOpc := 5

if ::nRecno == 0
	return .F.
endif

return ::execAuto(nOpc, lExibe, aAlias)


// -- ******************************************************
// -- Seta a linha atual do child
// -- ******************************************************
method setLine(cAlias, nLin) class Crud
local i, nX

nX := len(::aChilds)

for i := 1 to nX
	if ::aChilds[i]:cAlias == cAlias
		::aChilds[i]:nLine := nLin
	endif
next

return nLin


// -- ******************************************************
// -- Retorna a linha atual do child
// -- ******************************************************
method getLine(cAlias) class Crud
local nLin := 0
local i, nX

nX := len(::aChilds)

for i := 1 to nX
	if ::aChilds[i]:cAlias == cAlias
		nLin := ::aChilds[i]:nLine
	endif
next

return nLin


// -- ************************************
// ---- Classe Child 
// -- ************************************
class child

data cAlias
data nIndex
data aData
data cSeek
data cWhile
data cFilter 
data cOwner
data nLine
data oOwner

method newChild(cAlias, nIndex, cWhile, cFilter, oOwner) constructor

method addChild(cAlias, nIndex, cSeek, cWhile, cFilter)
method getChild(cAlias)

method set(cCampo, xVal, nI)
method get(cCampo, nI)

method addLine()
method delLine()
method getLine()
method setLine()
method getLenChild(cAlias) 
method getLen()
method goTop()
method goBottom()
method getCrud()
method seek()

endClass


// -- *****************************************
// -- Método para instanciar novo objeto child
// -- *****************************************
method newChild(cAlias, nIndex, cWhile, cFilter, oOwner) class child
local aArea		:= getArea()
local aAreaChi	:= (cAlias)->(getArea())
local aDados	:= {}
local aSubChilds:= {}
local lCarrega := oOwner:nRecno > 0
local cSeek		:= oOwner:cSeek
local cOwner	:= oOwner:cAlias
local nLenSeek, i, nX

default nIndex	:= 1
default cWhile	:= ""
default cFilter:= ""

if empty(cSeek)  
	dbSelectArea(cOwner)
	cSeek		:= &(indexKey())
endif            

nLenSeek := len(cSeek)

dbSelectArea(cAlias)		
dbSetOrder(nIndex)
	
if empty(cWhile)
	cWhile := indexKey()
endif

if lCarrega
	if dbSeek(cSeek)
		while cSeek == left(&(cWhile), nLenSeek)
			aAdd(aDados, crud():new(cAlias, recNo()))
			dbSkip()
		endDo
	else
		aAdd(aDados, crud():new(cAlias))	
	endif
endif

//Preenche os campos do objeto
::cAlias		:= cAlias
::nIndex		:= nIndex
::cOwner		:= oOwner:cAlias
::cFilter	:= cFilter     
::cSeek		:= cSeek
::cWhile		:= cWhile
::nLine		:= if(len(aDados) > 0, 1, 0)
::aData		:= aClone(aDados)
::oOwner		:= oOwner

(cAlias)->(restArea(aAreaChi))
restArea(aArea)

return self


// -- *******************************************************************
// -- Método para adicionar novo Child a um Child, ou seja, um sub-Child
// -- *******************************************************************
method addChild(cAlias, nIndex, cWhile, cFilter) class child
local nX 	:= len(::aData)
local oChild
local i, j, nY, lExist, nLin 

default cAlias	:= ""
default nIndex	:= 1
default cWhile	:= ""
default cFilter:= ""

//Coloca o novo Child em todos os cruds do Child atual

for i := 1 to nX
	//Verifica se no Child já existe no crud, se sim, ignora-o, pois já foi relacionado
	nY := len(::aData[i]:aChilds)
	for j := 1 to nY
		if ::aData[i]:aChilds[j]:cAlias == cAlias
			lExist := .T.
		endif
	next
	//Se não houver childs ou ele ainda não estiver declarado
	if nY == 0 .or. !lExist
		::aData[i]:addChild(cAlias, nIndex, cWhile, cFilter)
	endif
next

oChild := ::getChild(cAlias)

return oChild 


// -- ***************************************
// -- Método setar valor a um campo do Child
// -- ***************************************
method set(cCampo, xVal, nI) class child
return ::oOwner:set(cCampo, xVal, nI)


// -- ****************************************
// -- Método retornar valor do campo do Child
// -- ****************************************
method get(cCampo, nI) class child
return ::oOwner:get(cCampo, nI)


// -- *********************************
// -- Método para retornar o sub-Child 
// -- *********************************
method getChild(cAlias, nI) class child
local nLin := ::getLine()
local oChild

default nI := nLin

if nI > 0 .and. len(::aData) >= nI
	oChild := ::aData[nI]:getChild(cAlias)
endif

return oChild


// -- *****************************************
// -- Método para adicionar uma linha do Child
// -- *****************************************
method addLine() class child
return ::oOwner:addLine(::cAlias)


// -- *****************************************
// -- Método para apagar uma linha do Child
// -- *****************************************
method delLine() class child
return ::oOwner:delLine(::cAlias) 


// -- *********************************************
// -- Método para retornar  a linha atual do Child 
// -- *********************************************
method getLine() class child
return ::nLine


// -- *****************************************
// -- Método para setar a linha atual do Child 
// -- *****************************************
method setLine(nI) class child
return ::nLine := nI


// -- *********************************************************
// -- Método para retornar a quantidade de linhas do sub-Child
// -- *********************************************************
method getLenChild(cAlias, nI) class child
local nT := 0

default nI := ::getLine()

if nI > 0
	nT := ::aData[nI]:getLenChild(cAlias)
endif

return nT


// -- **********************************************
// -- Método que posiciona na última linha do child
// -- **********************************************
method goTop() class child
::setLine(1)
return 1


// -- *********************************************************
// -- Método para retornar a quantidade de linhas do sub-Child
// -- *********************************************************
method goBottom() class child
local nT := ::getLen()

if nT > 0
	::setLine(nT)
endif

return nT


// -- ******************************************************
// -- Método para retornar a quantidade de linhas do Child
// -- ******************************************************
method getLen() class child
local nT := ::oOwner:getLenChild(::cAlias)
return nT


// -- ******************************************************
// -- Método para retornar um crud do Child
// -- ******************************************************
method getCrud(nI) class child
local oObj := ::oOwner:getCrud(::cAlias, nI)
return oObj


// -- ******************************************************
// -- Método para setar a chave em uma linha do Child
// -- ******************************************************
method seek(cChave) class child
local lRet := .F.
local i, nX

nX := len(::aData)

for i := 1 to nX
	if ::aData[i]:cSeek == cChave
		::nLine := i
		lRet := .T.
		exit
	endif
next

return lRet

User Function crud001
Return
