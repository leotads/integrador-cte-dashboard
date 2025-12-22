import { Component, inject, Input, ViewChild } from '@angular/core';
import { PoDialogModule, PoDialogService, PoLoadingModule, PoNotificationService, PoPageModule, PoTableAction, PoTableColumn, PoTableColumnSort, PoTableModule, PoModalModule, PoModalAction, PoModalComponent, PoButtonModule, PoFieldModule, PoDynamicModule, PoDynamicFormField, ForceBooleanComponentEnum, PoDividerModule, PoContextTabsModule, PoTabsModule, PoTab } from '@po-ui/ng-components';
import { ProAppConfigService, ProJsToAdvplService } from '@totvs/protheus-lib-core';
import { ProtheusService } from '../../services/protheus.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-monitor',
  imports: [
    CommonModule,
    PoTableModule,
    PoPageModule,
    PoDialogModule,
    PoLoadingModule,
    PoModalModule,
    FormsModule,
    PoPageModule,
    PoButtonModule,
    PoFieldModule,
    PoDynamicModule,
    PoDividerModule,
    PoContextTabsModule,
    PoTabsModule
],
  templateUrl: './monitor.component.html',
  styleUrls: ['./monitor.component.css']
})
export class MonitorComponent {

  @Input() status!: string;

  @ViewChild(PoModalComponent, { static: true }) poModal!: PoModalComponent;

  public bluetooth = true;

  value: any = {};

  columns: Array<PoTableColumn> = [
      {
        property: 'status',
        type: 'label',
        labels: [
          { value: 'A', color: 'color-10', label: 'Aberto', textColor: "white" },
          { value: 'P', color: 'color-03', label: 'Integrado', textColor: "white" },
          { value: 'E', color: 'color-07', label: 'Erro', textColor: "white" }
        ]
      },
      { property: 'filial' },
      { property: 'data' },
      { property: 'hora' },
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
  isLoadingDialog: boolean = true;
  pagination: object = {page: 1, pageSize: 10}
  log: any = {};
  filtered: boolean = false;
  tabsFilters: Array<any> = [];
  fieldsFilter: Array<PoDynamicFormField> = [
    {
      property: 'chave',
      label: "Chave",
      optional: true,
      required: false,
      minLength: 10,
      maxLength: 44,
      errorMessage: "É necessário incluir de 10 a 44 caracteres para filtar a chave",
      gridColumns: 12,
      order: 1,
      placeholder: "Informa a chave da CTE/NFse"
    },
    {
      property: 'tomador',
      label: 'Tomador',
      optional: true,
      required: false,
      gridColumns: 12,
      placeholder: "Tomador do serviço"
    },
    {
      property: 'Emissaode',
      label: 'Emissão De',
      type: 'date',
      optional: true,
      gridColumns: 6
    },
    {
      property: 'Emissaoate',
      label: 'Emissão Até',
      optional: true,
      type: 'date',
      gridColumns: 6
    },
    {
      property: 'seriede',
      label: 'Série De',
      optional: true,
      gridColumns: 6
    },
    {
      property: 'serieate',
      label: 'Série Até',
      optional: true,
      gridColumns: 6
    },
    {
      property: 'numerode',
      label: 'Número De',
      optional: true,
      gridColumns: 6
    },
    {
      property: 'numeroate',
      label: 'Número Até',
      optional: true,
      gridColumns: 6
    },
    {
      property: 'tipo',
      label: 'Tipo',
      optional: true,
      gridColumns: 12,
      fieldValue: 'code',
      fieldLabel: 'description',
      options: [
        { code: "I", description: "Inclusão"},
        { code: "S", description: "Substituição"},
        { code: "E", description: "Cancelamento"},
        { code: "C", description: "Complemento"},
      ],
      optionsMulti: true
    },
    {
      property: 'status',
      label: 'Status',
      optional: true,
      gridColumns: 12,
      fieldValue: 'id',
      fieldLabel: 'description',
      options: [
        { id: "T", description: "Todos"},
        { id: "A", description: "Aberto"},
        { id: "P", description: "Processado"},
        { id: "E", description: "Erro"}
      ],
      optionsMulti: true
    },
  ];
  
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
      action: this.openLog.bind(this), 
      icon: 'an an-file-magnifying-glass', label: 'Log' 
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

    this.onLoading();

  }

  salvar() {
    this.poNotification.success('Formulário enviado com sucesso!');
    console.log(this.value);
  }

  onLoading() {
    this.isLoading = true;

    this.protheusService.getProtheus(
      'getDocuments',
      JSON.stringify({ ...this.pagination, status: this.status })
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);

        this.showMoreDisabled = !data.hasNext;

        this.pagination = {...this.pagination, page: data.nextPage}

        this.items = [ ...this.items, ...data.data ];
      },
      error: (error) => error,
      complete: () => this.isLoading = false
    });
  }

  openLog(item: any) {
    this.isLoadingDialog = false;

    this.protheusService.getProtheus(
      'getLog',
      JSON.stringify(item)
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);
        
        if (Object.keys(data).length === 0) {
          this.poNotification.information("Não foi localizado log para esse registro!");
        } else {
          this.log = data;
  
          this.poModal.open();
        }

      },
      error: (error) => this.poNotification.error("Não foi possível buscar o log de processamento!"),
      complete: () => this.isLoadingDialog = true
    });
  }

  excluir(item: any) {
    this.isLoadingDialog = false;

    this.protheusService.getProtheus(
      'excluiDocument',
      JSON.stringify(item)
    ).subscribe({
      next: (result) => {

        this.pagination = {page: 1, pageSize: 10};
        this.items = [];

        this.onLoading();

        this.poNotification.success("Registro excluído com sucesso!")
      },
      error: (error) => this.poNotification.error("Não foi possível excluir o registro!"),
      complete: () => this.isLoadingDialog = true
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
    this.isLoadingDialog = false;

    this.protheusService.getProtheus(
      'reprocessDocument',
      JSON.stringify(item)
    ).subscribe({
      next: (result) => {
        this.pagination = {page: 1, pageSize: 10};
        this.items = [];

        this.onLoading();

        if (!result) {
          this.poNotification.success("Processamento realizado com sucesso!");
        } else {
          this.poNotification.error(result);
        }
      },
      error: (error) => this.poNotification.error("Não foi possível reprocessar o registro!"),
      complete: () => this.isLoadingDialog = true
    });
  }

  openXML(item: any) {
    this.isLoadingDialog = false;

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
      complete: () => this.isLoadingDialog = true
    });
  }

  showMore(sort: PoTableColumnSort) {
    this.onLoading();
  }

  confirmModal: PoModalAction = {
    action: () => {
      this.closeModal();
    },
    label: 'Confirmar'
  };

  closeModal() {
    this.poModal.close();
  }

  onClick(tab: PoTab) {}
  onClose(tab: PoTab) {}


}
