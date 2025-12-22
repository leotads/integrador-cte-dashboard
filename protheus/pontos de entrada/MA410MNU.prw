/*/{Protheus.doc} MA410MNU
(long_description)
@type user function
@author user
@since 04/12/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function MA410MNU()
  Local aArea := GetArea()

  aAdd( aRotina, { 'Documento de saída', 'u_opnDocSa', 0, 4, 0, nil } )
//  aAdd( aRotina, { 'Documento de Saída', 'MATA460A()', 0, 4, 0, nil } )

  RestArea(aArea)

Return 

/*/{Protheus.doc} opnDocSa
(long_description)
@type user function
@author user
@since 04/12/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function opnDocSa()
//MATA460A

  SD2->( dbSetOrder( 8 ) )
  if SD2->( dbSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
    
    SF2->( dbSetOrder( 1 ) )
    if SF2->( dbSeek( SD2->D2_FILIAL + SD2->D2_DOC + SD2->D2_SERIE + SD2->D2_CLIENTE + SD2->D2_LOJA ) )
      Mc090Visual( "SF2",SF2->( recno() ), 2)
    else 
      MsgInfo("Documento de saída não localizado!")
    endif
  else 
    MsgInfo("Documento de saída não localizado!")
  endif
Return 
