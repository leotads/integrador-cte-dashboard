import { Component, Input } from '@angular/core';
import { PoDialogModule, PoDialogService, PoNotificationService, PoPageModule, PoTableAction, PoTableColumn, PoTableColumnSort, PoTableModule } from '@po-ui/ng-components';
import { ProAppConfigService, ProJsToAdvplService } from '@totvs/protheus-lib-core';
import { ProtheusService } from '../../services/protheus.service';

@Component({
  selector: 'app-monitor',
  imports: [
    PoTableModule,
    PoPageModule,
    PoDialogModule 
  ],
  templateUrl: './monitor.component.html',
  styleUrls: ['./monitor.component.css']
})
export class MonitorComponent {

  @Input() status!: string;

  columns: Array<PoTableColumn> = [
      {
        property: 'status',
        type: 'label',
        labels: [
          { value: 'A', color: 'color-10', label: 'Aberto' },
          { value: 'F', color: 'color-03', label: 'Integrado' },
          { value: 'E', color: 'color-07', label: 'Erro' }
        ]
      },
      { property: 'filial' },
      { property: 'data', format: 'dd/MM/yyyy' },
      { property: 'documento' },
      { property: 'serie' },
      { property: 'chave' },
      { 
        property: 'acao', 
        type: 'label',
        labels: [
          { value: "I", label: "Inclusão" },
          { value: "C", label: "Carta Correção" },
          { value: "E", label: "Exclusão" },
        ]
      },
    ];
  columnsDefault: Array<PoTableColumn> = [];
  detail: any;
  items: Array<any> = [];
  total: number = 0;
  totalExpanded = 0;
  initialColumns: Array<any> = [];
  showMoreDisabled: boolean = false;
  isLoading: boolean = false;
  pagination: object = {page: 0, pageSize: 5}
  //status: string = "";
  
  actions: Array<PoTableAction> = [
    {
      action: this.confirmDelete.bind(this),
      icon: 'po-icon an an-trash',
      label: 'Excluir'
      //disabled: this.validateDiscount.bind(this)
    },
    { 
      action: this.confirmReprocess.bind(this), 
      icon: 'an an-arrows-counter-clockwise', label: 'Reprocessar' 
    },
    { 
      action: this.openXML.bind(this), 
      icon: 'an an-download-simple', 
      label: 'Baixar' 
    }
  ];

    constructor(
      private proJsToAdvplService: ProJsToAdvplService,
      private protheusService: ProtheusService,
      private proAppConfigService: ProAppConfigService,
      public poNotification: PoNotificationService,
      public poDialog: PoDialogService
    ) {
      if (!this.proAppConfigService.insideProtheus()) {
        this.proAppConfigService.loadAppConfig();
      }
    }
  

  ngOnInit(): void {
/*    
    this.activatedRoute.queryParams.subscribe( params => {
      if (params['status'] == "integracao") {
        this.status = "I";
      } else if(params['status'] == "erros") {
        this.status = "E"
      }
    });
*/
    this.onLoading();

  }

  onLoading() {
    this.isLoading = false;

    this.protheusService.getProtheus(
      'getDocuments',
      JSON.stringify({ ...this.pagination, status: this.status })
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);

        this.showMoreDisabled = !data.hasPage;
        this.pagination = {...this.pagination, page: data.nextPage}

        this.items = data.data;
      },
      error: (error) => error,
      complete: () => this.isLoading = true
    });
  }

  excluir(item: any) {
    this.isLoading = false;

    this.protheusService.getProtheus(
      'excluiDocument',
      JSON.stringify(item)
    ).subscribe({
      next: (result) => {
        this.onLoading();

        this.poNotification.success("Registro excluído com sucesso!")
      },
      error: (error) => this.poNotification.error("Não foi possível excluir o registro!"),
      complete: () => this.isLoading = true
    });
  }

  confirmDelete(item: any) {
    if (item.status !== "E") {
      return this.poNotification.information("Só é permitido excluir registros com erros na integração!");
    }

    this.poDialog.confirm({
      literals: {cancel: "Cancelar", confirm: "Confirmar"},
      title: "Confirmação de exclusão",
      message: "Confirma a exclusão do registro?",
      confirm: () => this.excluir(item),
    });
  }


  confirmReprocess(item: any) {

    this.poDialog.confirm({
      literals: {cancel: "Cancelar", confirm: "Confirmar"},
      title: "Confirmação de reprocessamento",
      message: "Confirma o reprocessamento do registro?",
      confirm: () => this.reprocess(item),
    });

    

  }

  reprocess(item: any) {
    this.isLoading = false;

    this.protheusService.getProtheus(
      'reprocessDocument',
      JSON.stringify(item)
    ).subscribe({
      next: (result) => {

        this.onLoading();

        if (!result) {
          this.poNotification.success("Processamento realizado com sucesso!");
        } else {
          this.poNotification.error(result);
        }
      },
      error: (error) => this.poNotification.error("Não foi possível reprocessar o registro!"),
      complete: () => this.isLoading = true
    });
  }

  openXML(item: any) {
    this.isLoading = false;

    this.protheusService.getProtheus(
      'downloadDocument',
      JSON.stringify(item)
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);

        if (data.status) {
          this.poNotification.success(data.message);
        } else {
          this.poNotification.error(data.message);
        }
      },
      error: (error) => this.poNotification.error("Não foi possível baixar o XML!"),
      complete: () => this.isLoading = true
    });
  }

  showMore(sort: PoTableColumnSort) {
    this.onLoading();
  }


}
