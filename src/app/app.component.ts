import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ProAppConfigService, ProJsToAdvplService } from '@totvs/protheus-lib-core';

import {
  PoMenuItem,
  PoMenuModule,
  PoThemeModule,
  PoToolbarModule,
} from '@po-ui/ng-components';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { MonitorComponent } from './pages/monitor/monitor.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    PoToolbarModule,
    PoMenuModule,
    PoThemeModule,
    DashboardComponent,
    MonitorComponent
  ],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
})
export class AppComponent {

  page: string = "Dashboard";
  status: string = "";

  readonly menus: Array<PoMenuItem> = [
    { label: 'Dashboard', action: () => this.onAlterarPage("Dashboard", ""), icon: 'an an-chart-line', shortLabel: 'Dashboard' },
    { label: 'Monitor', action: () => this.onAlterarPage("Monitor", ""), icon: 'an an-monitor', shortLabel: 'Monitor' },
  ];

  constructor(
    private proJsToAdvplService: ProJsToAdvplService,
    private proAppConfigService: ProAppConfigService
  ) {
    if (!this.proAppConfigService.insideProtheus()) {
      this.proAppConfigService.loadAppConfig();
    }
  }
/*
  onAlterarStatus(newStatus: string) {
    this.status = newStatus;
  }
*/
  onAlterarPage(newPage: string, status: string) {
    this.status = status;
    this.page = newPage;

    console.log('status', status)
    console.log('page', newPage)
  }

}
