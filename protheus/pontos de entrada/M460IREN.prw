/*/{Protheus.doc} M460IREN
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
User Function M460IREN()
  If (IsInCallStack('ProcesNFse') )

    if _vlrIRRF > 0
      PARAMIXB := _vlrIRRF //ok
    endif
  
  endif
Return PARAMIXB
