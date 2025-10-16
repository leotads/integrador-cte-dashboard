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
          { value: 'available', color: 'color-11', label: 'Available' },
          { value: 'reserved', color: 'color-08', label: 'Reserved' },
          { value: 'closed', color: 'color-07', label: 'Closed' }
        ]
      },
      { property: 'filial' },
      { property: 'data' },
      { property: 'tipo' },
      { property: 'documento' },
      { property: 'serie' }
    ];
  columnsDefault: Array<PoTableColumn> = [];
  detail: any;
  items: Array<any> = [
      {
        status: 'available',
        filial: '01',
        data: '14/10/2025',
        tipo: 'CT-e',
        documento: '123456789',
        serie: 'CTE',
        detail: [
          {
            package: 'Basic',
            tour: 'City tour by public bus and visit to the main museums.',
            time: '20:10:10',
            distance: '1000'
          },
        ]
      },
 
      {
        status: 'closed',
        filial: '01',
        data: '13/10/2025',
        tipo: 'CT-e',
        documento: '987654321',
        serie: 'CTE',
        detail: [
          {
            package: 'Basic',
            tour: 'City tour by public bus and visit to the main museums.',
            time: '20:10:10',
            distance: '1000'
          },
        ]
      },
 
    ];
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
      action: this.baixarXML.bind(this), 
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

        this.items = data;
      },
      error: (error) => error
    })
  }

  excluir() {

  }

  reprocess() {

  }

  baixarXML() {

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
