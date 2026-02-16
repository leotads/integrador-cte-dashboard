#INCLUDE 'Rwmake.ch'
#INCLUDE 'Protheus.ch'
#INCLUDE 'Tbiconn.ch'
#INCLUDE 'Topconn.ch'
#Include 'totvs.ch'

/*/{Protheus.doc} alCliLoj
(long_description)
@type user function
@author user
@since 03/01/2026
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function alCliLoj(cCgc, cIE)
  local cRetorno := "0001"
  
  default cCgc := ""

  if empty(cCgc)
    return cRetorno
  endif

  SA1->( dbsetorder(1) )
  if !SA1->( dbSeek( xFilial('SA1') + cCgc ) )
    return substr(cCgc,9,4)
  endif

  if LEN(cCgc) == 14
    BeginSQL alias 'QRYSA1'
      SELECT max(a1_loja) maxloja
        FROM %table:SA1% a1
       WHERE a1_filial = %xFilial:SA1% AND
             a1_cod = %exp:left(cCgc,8)% AND
             a1_loja like 'IE%' AND 
             D_E_L_E_T_ = ' '
    endSql

    if QRYSA1->(!EOF())
      if !empty(QRYSA1->maxloja)
        cRetorno := soma1( alltrim( QRYSA1->maxloja ) )
      else
        cRetorno := "IE01"
      endif
    else 
      cRetorno := "IE01"
    endif 
    QRYSA1->(dbCloseArea())
  endif

Return cRetorno
