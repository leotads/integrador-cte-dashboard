/*/{Protheus.doc} M460ICM
(long_description)
@type user function
@author Leonardo Freitas
@since 14/11/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function M460ICM()
  
  If (IsInCallStack('PROCESSACTE') .OR. IsInCallStack('ProcesNFse') )
    if _nBaseIcms > 0
      _BASEICM := _nBaseIcms
    endif

    if _nAliqIcms > 0
      _ALIQICM := _nAliqIcms
    endif

    if _nValIcms > 0
      _VALICM  := _nValIcms
    endif
  endif

Return 
