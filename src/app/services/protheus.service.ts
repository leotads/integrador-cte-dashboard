import { Injectable } from '@angular/core';
import { ProJsToAdvplService } from '@totvs/protheus-lib-core';

@Injectable({
  providedIn: 'root'
})
export class ProtheusService {

  constructor(
    private proJsToAdvplService: ProJsToAdvplService
  ) {}
      
  getProtheus(receiveId: string, content: string = '') {
    return this.proJsToAdvplService.buildObservable<string>(
      ({protheusResponse, subscriber}: any) => {
        subscriber.next(protheusResponse);
        subscriber.complete();
      },
      {
        autoDestruct: true,
        receiveId: receiveId,
        sendInfo: {
          type: receiveId,
          content: content
        }
      }
    );
  }
    
}
