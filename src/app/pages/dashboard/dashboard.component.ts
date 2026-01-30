import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { format, formatDate } from 'date-fns';

import { 
  PoPageModule,
  PoDividerModule,
  PoWidgetModule,
  PoDatepickerModule,
  PoTabsModule,
  PoChartModule,
  PoLoadingModule,
  PoChartOptions,
  PoChartSerie,
  PoNotificationService,
  PoTab
} from '@po-ui/ng-components';
import { ProAppConfigService, ProJsToAdvplService } from '@totvs/protheus-lib-core';
import { ProtheusService } from '../../services/protheus.service';
import { timeout } from 'rxjs';

@Component({
  selector: 'app-dashboard',
  imports: [
    PoPageModule,
    PoDividerModule,
    PoWidgetModule,
    FormsModule,
    PoDatepickerModule,
    PoTabsModule,
    PoChartModule,
    PoLoadingModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent {

  @Input() acao!: (page: string, filters: object) => void;

  isLoading: boolean = true;
  numberOfDocuments: string = '0';
  numberOpenOfDocuments: string = '0';
  integratedQuantity: string = '0';
  numberOfErrors: string = '0';
  endDate: string = <any>new Date();
  startDate: string = <any>format(new Date(), 'yyyy-MM-dd');

  optionsChart: PoChartOptions = {
    axis: {
      minRange: undefined,
      maxRange: undefined,
      gridLines: undefined,
      labelType: undefined,
      paddingBottom: undefined,
      paddingLeft: undefined,
      paddingRight: undefined,
      rotateLegend: undefined,
      showXAxis: undefined,
      showYAxis: undefined,
      showAxisDetails: undefined
    },
    header: {
      hideExpand: undefined,
      hideExportCsv: undefined,
      hideExportImage: undefined,
      hideTableDetails: undefined
    },
    dataZoom: undefined,
    fillPoints: undefined,
    firstColumnName: undefined,
    innerRadius: undefined,
    borderRadius: undefined,
    textCenterGraph: undefined,
    descriptionChart: undefined,
    subtitleGauge: undefined,
    legend: undefined,
    legendPosition: undefined,
    legendVerticalPosition: undefined,
    bottomDataZoom: undefined,
    rendererOption: undefined,
    pointer: undefined,
    stacked: undefined,
    roseType: undefined,
    showFromToLegend: undefined
  };
  chartDocumentsPerDayCategories: Array<string> = [];
  chartDocumentsPerDaySeries: Array<PoChartSerie> = [];

  chartDocumentsPerMonthCategories: Array<string> = [];
  chartDocumentsPerMonthSeries: Array<PoChartSerie> = [];
  
  chartDocumentsPerYearCategories: Array<string> = [];
  chartDocumentsPerYearSeries: Array<PoChartSerie> = [];
  
  chartDocumentsPerYearsCategories: Array<string> = [];
  chartDocumentsPerYearsSeries: Array<PoChartSerie> = [];
  
  constructor(
    private proJsToAdvplService: ProJsToAdvplService,
    private protheusService: ProtheusService,
    public poNotification: PoNotificationService,
    private proAppConfigService: ProAppConfigService
  ) {
    if (!this.proAppConfigService.insideProtheus()) {
      this.proAppConfigService.loadAppConfig();
    }
  }

  ngOnInit(): void {
    this.onLoading();
  }

  

  async onLoading() {
    this.isLoading = false;

    Promise.all([
      this.getQuantityDocuments(),
      this.getQuantityOpenDocuments(),
      this.getQuantityIntegrated(),
      this.getQuantityErrors(),
      this.chartDocumentsPerDay()
    ])
    .catch((err) => this.poNotification.error("erro ao buscar os registros"))
    .finally(() => this.isLoading = true)
  }

  async getQuantityDocuments() {
    this.protheusService
      .getProtheus(
        'getQuantityDocuments',
        JSON.stringify({ date: this.startDate, status: '' })
      )
      .subscribe({
        next: (result) => {
          this.numberOfDocuments = result;
        }
      })
  }
  
  async getQuantityIntegrated() {
    this.protheusService
      .getProtheus(
        'getQuantityIntegrated',
        JSON.stringify({ date: this.startDate, status: 'P' })
      )
      .subscribe({
        next: (result) => {
          this.integratedQuantity = result;
        }
      })
  }

  async getQuantityOpenDocuments() {
    this.protheusService
      .getProtheus(
        'getQuantityOpenDocuments',
        JSON.stringify({ date: this.startDate, status: 'A' })
      )
      .subscribe({
        next: (result) => {
          this.numberOpenOfDocuments = result;
        }
      })
  }

  async getQuantityErrors() {
    this.protheusService
      .getProtheus(
        'getQuantityErrors',
        JSON.stringify({ date: this.startDate, status: 'E' })
      )
      .subscribe({
        next: (result) => {
          this.numberOfErrors = result;
        }
      })
  }

  async chartDocumentsPerDay() {

    this.protheusService.getProtheus(
      'chartDocumentsPerDay',
      JSON.stringify({date: this.startDate})
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);
    
        this.chartDocumentsPerDayCategories = data?.axisX;
    
        this.chartDocumentsPerDaySeries = data?.data;

      },
      error: (error) => error
    });

    
  }

  async chartDocumentsPerMonth() {


    const [ ano, mes ] = this.startDate.split('-');
    const mesAno = `${mes}/${ano}` 

    this.protheusService.getProtheus(
      'chartDocumentsPerMonth',
      JSON.stringify({date: mesAno})
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);
                
        this.chartDocumentsPerMonthCategories = data?.axisX;
        
        this.chartDocumentsPerMonthSeries = data?.data;

      },
      error: (error) => error
    })

    
  }

  async chartDocumentsPerYear() {

    const [ ano ] = this.startDate.split('-'); 

    this.protheusService.getProtheus(
      'chartDocumentsPerYear',
      JSON.stringify({date: ano })
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);

        this.chartDocumentsPerYearCategories = data?.axisX;
    
        this.chartDocumentsPerYearSeries = data?.data;

      },
      error: (error) => error
    })

  }

  async chartDocumentsPerYears() {


    this.protheusService.getProtheus(
      'chartDocumentsPerYears',
    ).subscribe({
      next: (result) => {
        const data: any = JSON.parse(result);

        this.chartDocumentsPerYearsCategories = data?.axisX;
    
        this.chartDocumentsPerYearsSeries = data?.data;

      },
      error: (error) => error
    })

  }

  async openMonitor(status: string) {

    this.acao("Monitor", { status: [status] });

  }

  changeDate() {
    this.getQuantityDocuments()
    this.getQuantityIntegrated()
    this.getQuantityOpenDocuments()
    this.getQuantityErrors()
    this.chartDocumentsPerDay()
    this.chartDocumentsPerMonth()
    this.chartDocumentsPerYear()
    this.chartDocumentsPerYears()
  }

  

} 
