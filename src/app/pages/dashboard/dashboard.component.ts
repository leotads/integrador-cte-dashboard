import { Component } from '@angular/core';
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
import { Router } from '@angular/router';
import { ProtheusService } from '../../services/protheus.service';

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
  isLoading: boolean = true;
  numberOfDocuments: string = '0';
  integratedQuantity: string = '0';
  numberOfErrors: string = '0';
  endDate: string = <any>new Date();
  startDate: string = <any>format(new Date(), 'yyyy-MM-dd');

  chartDocumentsPerDayOptions: PoChartOptions = {};
  chartDocumentsPerDayCategories: Array<string> = [];
  chartDocumentsPerDaySeries: Array<PoChartSerie> = [];

  chartDocumentsPerMonthOptions: PoChartOptions = {};
  chartDocumentsPerMonthCategories: Array<string> = [];
  chartDocumentsPerMonthSeries: Array<PoChartSerie> = [];
  
  chartDocumentsPerYearOptions: PoChartOptions = {};
  chartDocumentsPerYearCategories: Array<string> = [];
  chartDocumentsPerYearSeries: Array<PoChartSerie> = [];
  
  chartDocumentsPerYearsOptions: PoChartOptions = {};
  chartDocumentsPerYearsCategories: Array<string> = [];
  chartDocumentsPerYearsSeries: Array<PoChartSerie> = [];
  
  /*
  
  optionsColumnDocumentsPerYear: PoChartOptions = {};
  categoriesColumnDocumentsPerYear: Array<string> = [];
  DocumentsPerYear: Array<PoChartSerie> = [];
  optionsColumnAllDocuments: PoChartOptions = {};
  categoriesColumnAllDocuments: Array<string> = [];
  allDocuments: Array<PoChartSerie> = [];
*/
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

  async onLoading() {
    this.isLoading = false;

    Promise.all([
      this.getQuantityDocuments(),
      this.getQuantityIntegrated(),
      this.getQuantityErrors(),
      this.chartDocumentsPerDay()
    ])
    .catch((err) => this.poNotification.error("erro ao buscar os registros"))
    .finally(() => this.isLoading = true)
  }

  async getQuantityDocuments() {
    this.protheusService.getProtheus('getQuantityDocuments')
      .subscribe({
        next: (result) => {
          this.numberOfDocuments = result;
        }
      })
  }
  
  async getQuantityIntegrated() {
    this.protheusService.getProtheus('getQuantityIntegrated')
      .subscribe({
        next: (result) => {
          this.integratedQuantity = result;
        }
      })
  }

  async getQuantityErrors() {
    this.protheusService.getProtheus('getQuantityErrors')
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

        this.chartDocumentsPerDayOptions = {
          axis: {
            maxRange: data?.axis?.maxRange,
            gridLines: this.maiorDivisor(data?.axis?.maxRange)
          }
        };
    
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
        
        this.chartDocumentsPerMonthOptions = {
          axis: {
            maxRange: data?.axis?.maxRange,
            gridLines: this.maiorDivisor(data?.axis?.maxRange)
          }
        };
        
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

        this.chartDocumentsPerYearOptions = {
          axis: {
            maxRange: data?.axis?.maxRange,
            gridLines: this.maiorDivisor(data?.axis?.maxRange)
          }
        };
    
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

        this.chartDocumentsPerYearsOptions = {
          axis: {
            maxRange: data?.axis?.maxRange,
            gridLines: this.maiorDivisor(data?.axis?.maxRange)
          }
        };
    
        this.chartDocumentsPerYearsCategories = data?.axisX;
    
        this.chartDocumentsPerYearsSeries = data?.data;

      },
      error: (error) => error
    })

  }

  maiorDivisor(valor: number) {
    for (let i = Math.floor(valor); i > 0; i--) {
      if (valor % i === 0) return i;
    }
    return 1;
  }

  openMonitor(status: string) {
    this.router.navigate(["/monitor"], {
      queryParams: {
        status: status
      }
    })
  }

  changeDate() {
    this.chartDocumentsPerDay()
    this.chartDocumentsPerMonth()
    this.chartDocumentsPerYear()
    this.chartDocumentsPerYears()
  }

} 
