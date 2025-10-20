import { Component } from '@angular/core';
import { PoNotificationService, PoPageModule, PoTableAction, PoTableColumn, PoTableColumnSort, PoTableModule } from '@po-ui/ng-components';
import { ProAppConfigService, ProJsToAdvplService } from '@totvs/protheus-lib-core';
import { ProtheusService } from '../../services/protheus.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-monitor',
  imports: [
    PoTableModule,
    PoPageModule
  ],
  templateUrl: './monitor.component.html',
  styleUrl: './monitor.component.css'
})
export class MonitorComponent {

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
      { property: 'data' },
      { property: 'documento' },
      { property: 'serie' },
      { property: 'acao' },
      { property: 'chave' },
    ];
  columnsDefault: Array<PoTableColumn> = [];
  detail: any;
  items: Array<any> = [];
  total: number = 0;
  totalExpanded = 0;
  initialColumns: Array<any> = [];
  showMoreDisabled: boolean = false;
  isLoading: boolean = false;

  actions: Array<PoTableAction> = [
    {
      action: this.excluir.bind(this),
      icon: 'po-icon an an-trash',
      label: 'Excluir'
      //disabled: this.validateDiscount.bind(this)
    },
    { 
      action: this.reprocess.bind(this), 
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
      public poNotification: PoNotificationService,
      private proAppConfigService: ProAppConfigService,
      private router: Router
    ) {
      if (!this.proAppConfigService.insideProtheus()) {
        this.proAppConfigService.loadAppConfig();
      }
    }
  

  ngOnInit(): void {
    this.onLoading();
  }

  onLoading() {
    this.isLoading = false;

    this.protheusService.getProtheus(
      'getDocuments',
      //JSON.stringify({date: this.startDate})
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);

        this.items = data.data;
      },
      error: (error) => error
    })
  }

  excluir() {

  }

  reprocess() {

  }

  openXML() {
//    const blob = new Blob([xmlData], { type: 'application/xml' });
//    const url = window.URL.createObjectURL(blob);
//    window.open(url, '_blank');
  }

  showMore(sort: PoTableColumnSort) {
    this.isLoading = true;
    this.showMoreDisabled = true;
    /*setTimeout(() => {
      this.items = this.getItems(sort);
      this.isLoading = false;
    }, 4000);*/
  }

  decreaseTotal(row: any) {
    if (row.value) {
      this.total -= row.value;
    }
  }

  deleteItems(items: Array<any>) {
    this.items = items;
  }

  onCollapseDetail() {
    this.totalExpanded -= 1;
    this.totalExpanded = this.totalExpanded < 0 ? 0 : this.totalExpanded;
  }

  onExpandDetail() {
    this.totalExpanded += 1;
  }

  sumTotal(row: any) {
    if (row.value) {
      this.total += row.value;
    }
  }

  restoreColumn() {
    this.columns = this.columnsDefault;
  }

  changeColumnVisible(event: any) {
    localStorage.setItem('initial-columns', event);
  }
}
