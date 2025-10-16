
function(codeType, content){
  // Se a interação que recebi for igual a mensagemProtheus
  if (codeType == 'mensagemProtheus') {
    // Eu dou um alert com a informação que recebi para trabalhar
    alert('Mensagem recebida do Protheus: ' + content);
  }
  // Efetua o envio do evento para observable do buildObservable
  this.eventTarget.send(codeType, content);
}