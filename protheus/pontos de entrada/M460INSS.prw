/*/{Protheus.doc} M460INSS
(long_description)
@type user function
@author user
@since 18/12/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function M460INSS(nTotInss)
  If (IsInCallStack('ProcesNFse') )
    if _vlrINSS > 0
      nTotInss := _vlrINSS
    endif
  endif
Return nTotInss
