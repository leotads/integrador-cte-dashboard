#Include 'Protheus.ch'

/*/{Protheus.doc} M460NUM
Ponto de Entrada executado após informada a série do Documento de Saída.
Tem finalidade de carregar o Documento transferido do sistema Legado e a série padrão utilizada em Integração.
@type function
@author André Vicente
@since 20/10/2025
@version 1.0
@param cNumDoc, character, Número do documento que deverá ser gerado
/*/
User Function M460NUM
    If (IsInCallStack('PROCESSACTE') .OR. IsInCallStack('PROCESSANFSE') ) .AND. Type("cYNumNF") <> 'U'
        cNumero	:= cYNumNF
		//cSerie  := SC5->C5_YSERIE
    EndIf
Return

